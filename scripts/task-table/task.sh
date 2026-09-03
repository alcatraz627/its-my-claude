#!/usr/bin/env bash
# task.sh — write to a session's task store from Bash, for harness builds that expose
# no TaskCreate / TaskUpdate tool (observed 2026-08-18 on Fable builds by gcc-work-78,
# vb-fable and gcc-fable), and for anyone who wants /tasks to be the one surface.
#
# The store is ~/.claude/tasks/session-<sid8>/<n>.json, the same files the built-in
# Task tool writes, so /tasks (task-table.sh) reads both without knowing which wrote
# them. Fields kept identical: id, subject, description, status, activeForm, blocks,
# blockedBy, metadata. Ids are max+1 across the directory. Writes are atomic
# (temp + rename) and serialised through a per-store lock, because a live Task tool
# and this script may both write the same store.
#
# Store resolution is the same as task-table.sh: --session <sid8> wins, then the pin
# written by task-table.sh --pin, then a store named for the live session, then
# resolve-store.sh. `--new` creates a store for the live session when none resolves.
#
# Usage:
#   task.sh add "<subject>" [--desc "<text>"] [--class C] [--domain D] [--batch B] [--goal G] [--lane L] [--tier T]
#           [--priority P1] [--owner A] [--note "…"] [--blocked-on "USER: …"]
#           [--verified true|false|prod] [--blocked-by N,M] [--status pending|in_progress]
#   task.sh update <id> [--status S] [--subject "<s>"] [--desc "<d>"] [--append-desc "<d>"]
#           [--class C] [--domain D] [--blocked-on X] [--verified V] [--blocked-by N,M] [--clear-blocked-on]
#   task.sh done <id> [<id>…]         mark completed
#   task.sh start <id>                mark in_progress
#   task.sh meta <id> key=value …     set arbitrary metadata keys
#   task.sh show <id>                 print the JSON
#   task.sh list                      short list (id · status · subject); /tasks is the full view
#   task.sh store                     print the resolved store path
# Common flags: --session <sid8> · --new · --json (machine output)
set -uo pipefail
TASKS="$HOME/.claude/tasks"; PINS="$TASKS/.live-session-map"
SESSION=""; NEW=0; JSON=0; ARGS=()
# Global flags are accepted BEFORE the subcommand as well as after it. Taking $1
# as the subcommand unconditionally meant `task.sh --session X update 87` died
# with "unknown command --session", which names the wrong thing: the flag is
# valid, only its position was not. Both orders now work, so nobody loses a call
# to a rule the help text never stated (owner, 2026-09-04).
while [ $# -gt 0 ]; do case "$1" in
  --session) SESSION="$2"; shift 2;; --new) NEW=1; shift;; --json) JSON=1; shift;;
  *) break;; esac; done

CMD="${1:-}"; [ -n "$CMD" ] && shift || { sed -n '2,29p' "$0"; exit 2; }
case "$CMD" in -h|--help|help) sed -n '2,29p' "$0"; exit 0;; esac
while [ $# -gt 0 ]; do case "$1" in
  --session) SESSION="$2"; shift 2;; --new) NEW=1; shift;; --json) JSON=1; shift;;
  -h|--help) sed -n '2,29p' "$0"; exit 0;; *) ARGS+=("$1"); shift;; esac; done
set -- "${ARGS[@]+"${ARGS[@]}"}"

LIVE="${CLAUDE_CODE_SESSION_ID:-}"; LIVE8="${LIVE:0:8}"
resolve_store() {
  if [ -n "$SESSION" ]; then echo "$TASKS/session-${SESSION:0:8}"; return; fi
  if [ -n "$LIVE8" ] && [ -f "$PINS/$LIVE8" ]; then local p; p=$(cat "$PINS/$LIVE8"); p="session-${p#session-}"; [ -d "$TASKS/$p" ] && { echo "$TASKS/$p"; return; }; fi
  if [ -n "$LIVE8" ] && [ -d "$TASKS/session-$LIVE8" ] && [ -n "$(ls "$TASKS/session-$LIVE8" 2>/dev/null)" ]; then echo "$TASKS/session-$LIVE8"; return; fi
  local r="$HOME/.claude/scripts/task-table/resolve-store.sh"
  if [ -x "$r" ]; then local d; d=$("$r" 2>/dev/null) && [ -n "$d" ] && [ -d "$d" ] && { echo "$d"; return; }; fi
  if [ "$NEW" = 1 ] && [ -n "$LIVE8" ]; then mkdir -p "$TASKS/session-$LIVE8"; echo "$TASKS/session-$LIVE8"; return; fi
  return 1
}
STORE=$(resolve_store) || { echo "task.sh: no task store resolves for this session (pass --session <sid8>, or --new to create one for $LIVE8)" >&2; exit 4; }
[ -d "$STORE" ] || { echo "task.sh: store missing: $STORE" >&2; exit 4; }
LOCK="$STORE/.task-sh.lock"
with_lock() { local i=0; while ! mkdir "$LOCK" 2>/dev/null; do i=$((i+1)); [ $i -gt 50 ] && { echo "task.sh: lock held >5s: $LOCK" >&2; return 1; }; sleep 0.1; done; "$@"; local rc=$?; rmdir "$LOCK" 2>/dev/null; return $rc; }
next_id() { ls "$STORE" | rg -o '^[0-9]+' | sort -n | tail -1 | awk '{print $1+1}'; }
write_json() { local f="$1"; local tmp="$f.tmp.$$"; cat > "$tmp" && mv -f "$tmp" "$f"; }
csv_to_arr() { [ -n "${1:-}" ] && printf '%s' "$1" | jq -Rc 'split(",")|map(gsub("^ +| +$";""))|map(select(length>0))' || echo '[]'; }
# Owner ruling 2026-08-20: "Map and refuse and on every bad flag print a helper
# warning with all the acceptable messages (irrespective of it being a warn or
# error type)." So no rejection here ever says only what is wrong; every one
# names the whole acceptable set. Demonstrated the same minute it was ruled:
# "task.sh: unknown flag --session f5c44d78" listed no alternatives.
STATUSES="pending in_progress completed"
TIERS="fable opus sonnet haiku lm"
# Derived from the case arms below rather than maintained by hand, so the help
# cannot drift from what the parser actually accepts.
known_flags() { rg -o -- '^    --[a-z-]+\)' "$0" 2>/dev/null | tr -d ' )' | sort -u | tr '\n' ' '; }
flag_reject() {  # flag_reject <flag> <given> <acceptable set>
  { printf 'task.sh: %s does not accept "%s".\n' "$1" "$2"
    printf '  acceptable: %s\n' "$3"; } >&2
}
flag_warn() {    # flag_warn <flag> <given> <used instead> <acceptable set>
  { printf 'task.sh: %s "%s" is not canonical; writing "%s".\n' "$1" "$2" "$3"
    printf '  acceptable: %s\n' "$4"; } >&2
}

# turn the flag list into a jq filter that patches the object; shared by add/update
patch_filter() { # sets FILTER and ARGJ (jq --arg pairs)
  FILTER="."; ARGJ=()
  while [ $# -gt 0 ]; do case "$1" in
    --status)
      # "done" is the colloquial spelling and it minted a third vocabulary: 7 rows
      # on this machine carry it, and the renderer counted every one as neither
      # open nor done until 2026-08-20 (traced by vb-fable). Map it, say so.
      _st="$2"
      case "$_st" in
        done|Done|DONE|complete|finished) flag_warn --status "$_st" completed "$STATUSES"; _st=completed ;;
        pending|in_progress|completed) ;;
        *) flag_reject --status "$_st" "$STATUSES"; return 2 ;;
      esac
      FILTER="$FILTER | .status=\$status"; ARGJ+=(--arg status "$_st"); shift 2;;
    --subject) FILTER="$FILTER | .subject=\$subject"; ARGJ+=(--arg subject "$2"); shift 2;;
    --desc) FILTER="$FILTER | .description=\$desc"; ARGJ+=(--arg desc "$2"); shift 2;;
    --append-desc) FILTER="$FILTER | .description=((.description // \"\") + \"\n\n\" + \$adesc)"; ARGJ+=(--arg adesc "$2"); shift 2;;
    --class) FILTER="$FILTER | .metadata.class=\$class"; ARGJ+=(--arg class "$2"); shift 2;;
    --domain) FILTER="$FILTER | .metadata.domain=\$domain"; ARGJ+=(--arg domain "$2"); shift 2;;
    --batch) FILTER="$FILTER | .metadata.batch=\$batch"; ARGJ+=(--arg batch "$2"); shift 2;;
    --lane) FILTER="$FILTER | .metadata.lane=\$lane"; ARGJ+=(--arg lane "$2"); shift 2;;
    --tier)
      case " $TIERS " in *" $2 "*) ;; *) flag_reject --tier "$2" "$TIERS"; return 2 ;; esac
      FILTER="$FILTER | .metadata.tier=\$tier"; ARGJ+=(--arg tier "$2"); shift 2;;
    --goal) FILTER="$FILTER | .metadata.goal=\$goal"; ARGJ+=(--arg goal "$2"); shift 2;;
    --priority) FILTER="$FILTER | .metadata.priority=\$prio"; ARGJ+=(--arg prio "$2"); shift 2;;
    --owner) FILTER="$FILTER | .metadata.owner=\$owner"; ARGJ+=(--arg owner "$2"); shift 2;;
    --note) FILTER="$FILTER | .metadata.note=\$note"; ARGJ+=(--arg note "$2"); shift 2;;
    --blocked-on) FILTER="$FILTER | .metadata.blocked_on=\$bo"; ARGJ+=(--arg bo "$2"); shift 2;;
    # DELEGATED. Owner instruction relayed by automation 2026-08-20: "ipc them all
    # to confirm they are doing it, and mark it as 'delegated' -> ipc to gcc-work
    # to add this to /tasks as a status with metadata about who took it up".
    # A delegated row is neither the owner's to decide nor this agent's to pick up,
    # and counting it as either makes the queue dishonest: five of automation's
    # forty-two owner-gates were only there because the work was FILED in their
    # store, which is what made their task render unreadable.
    --delegated-to) FILTER="$FILTER | .metadata.delegated_to=\$dto | .metadata.delegated_at=(.metadata.delegated_at // \$dat)"
                    ARGJ+=(--arg dto "$2" --arg dat "$(date -u +%Y-%m-%dT%H:%M:%SZ)"); shift 2;;
    --delegated-at) FILTER="$FILTER | .metadata.delegated_at=\$dat2"; ARGJ+=(--arg dat2 "$2"); shift 2;;
    --confirmed)
      # delegated-and-unconfirmed is a DIFFERENT state from delegated-and-acknowledged,
      # and automation had no way to say which after ipc-ing three peers for confirmation.
      case "$2" in true|false) ;; *) flag_reject --confirmed "$2" "true false"; return 2 ;; esac
      FILTER="$FILTER | .metadata.delegated_confirmed=\$dcf"; ARGJ+=(--arg dcf "$2"); shift 2;;
    --undelegate) FILTER="$FILTER | del(.metadata.delegated_to) | del(.metadata.delegated_at) | del(.metadata.delegated_confirmed)"; shift;;
    --clear-blocked-on) FILTER="$FILTER | del(.metadata.blocked_on)"; shift;;
    --verified) case "$2" in true) FILTER="$FILTER | .metadata.verified=true";; false) FILTER="$FILTER | .metadata.verified=false";; *) FILTER="$FILTER | .metadata.verified=\$ver"; ARGJ+=(--arg ver "$2");; esac; shift 2;;
    --blocked-by) FILTER="$FILTER | .blockedBy=\$bb"; ARGJ+=(--argjson bb "$(csv_to_arr "$2")"); shift 2;;
    --blocks) FILTER="$FILTER | .blocks=\$bl"; ARGJ+=(--argjson bl "$(csv_to_arr "$2")"); shift 2;;
    *) { printf 'task.sh: unknown flag %s\n' "$1"
         printf '  acceptable: %s\n' "$(known_flags)"; } >&2; return 2;;
  esac; done
}
do_add() {
  local subject="$1"; shift; local id; id=$(next_id); [ -n "$id" ] || id=1
  patch_filter "$@" || return 2
  jq -n --arg id "$id" --arg s "$subject" '{id:$id,subject:$s,description:"",status:"pending",activeForm:null,blocks:[],blockedBy:[],metadata:{}}' \
    | jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" | write_json "$STORE/$id.json"
  [ "$JSON" = 1 ] && cat "$STORE/$id.json" || echo "added #$id: $subject  ($(basename "$STORE"))"
}
do_update() {
  local id="$1"; shift; local f="$STORE/$id.json"; [ -f "$f" ] || { echo "task.sh: no task #$id in $(basename "$STORE")" >&2; return 1; }
  patch_filter "$@" || return 2
  jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" "$f" | write_json "$f"
  [ "$JSON" = 1 ] && cat "$f" || echo "updated #$id: $(jq -r '"\(.status) · \(.subject)"' "$f")"
}
do_meta() {
  local id="$1"; shift; local f="$STORE/$id.json"; [ -f "$f" ] || { echo "task.sh: no task #$id" >&2; return 1; }
  FILTER="."; ARGJ=(); local kv k v
  for kv in "$@"; do k="${kv%%=*}"; v="${kv#*=}"
    case "$v" in true|false|null) FILTER="$FILTER | .metadata[\"$k\"]=$v";; *) FILTER="$FILTER | .metadata[\"$k\"]=\$v_$k"; ARGJ+=(--arg "v_$k" "$v");; esac; done
  jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" "$f" | write_json "$f" && echo "meta #$id: $(jq -c .metadata "$f")"
}
case "$CMD" in
  store) echo "$STORE" ;;
  add) [ -n "${1:-}" ] || { echo "task.sh add: need a subject" >&2; exit 2; }; with_lock do_add "$@" ;;
  update) [ -n "${1:-}" ] || { echo "task.sh update: need an id" >&2; exit 2; }; with_lock do_update "$@" ;;
  done) for id in "$@"; do with_lock do_update "$id" --status completed; done ;;
  start) with_lock do_update "$1" --status in_progress ;;
  meta) [ -n "${2:-}" ] || { echo "task.sh meta: need <id> key=value…" >&2; exit 2; }; with_lock do_meta "$@" ;;
  show) cat "$STORE/$1.json" ;;
  # --json is advertised at the top of this file as "machine output" and was
  # honoured by add and update but silently ignored here, so a caller asking for
  # JSON got the human table and had to parse columns. Emit one array, id-sorted,
  # with every field the store holds.
  list)
    if [ "$JSON" = 1 ]; then
      jq -s 'sort_by(.id | tonumber? // .id)' "$STORE"/*.json
    else
      for f in $(ls "$STORE"/*.json | sort -t/ -k"$(($(echo "$STORE" | tr -cd / | wc -c)+1))" -n); do jq -r '"\(.id)\t\(.status)\t\(.subject)"' "$f"; done | sort -n | awk -F'\t' '{printf "%4s  %-12s %s\n",$1,$2,$3}'
    fi ;;
  *) echo "task.sh: unknown command $CMD" >&2; exit 2 ;;
esac

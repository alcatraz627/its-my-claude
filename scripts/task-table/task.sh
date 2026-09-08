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
#           [--state owner-gate|blocked|active|review|deferred|done|unassigned]
#   task.sh update <id> [--status S] [--subject "<s>"] [--desc "<d>"] [--append-desc "<d>"]
#           [--class C] [--domain D] [--blocked-on X] [--verified V] [--blocked-by N,M] [--clear-blocked-on]
#           [--delegated-to <agent>] [--delegated-confirmed true|false] [--undelegate]
#             a row handed to a sub-agent or peer draws as 🤝 delegated, neither ready nor
#             yours to pick up; set it when you dispatch, confirm when the seat acknowledges
#   task.sh close <id> --by "<what proved it>"   close naming the instrument (true = ran it, prod = seen live,
#                                     false = nothing did, with one clause why); the encouraged close verb
#   task.sh done <id> [<id>…] [--verified <text>]  mark completed; without --verified it says no instrument was named
#   task.sh to-board <id>             move one row to this project's kanban board: the card is
#                                     created from the subject, the row closes here carrying the
#                                     card id as its pointer. Relocation, not generation (owner
#                                     extension of the 2026-08-10 ruling, 2026-09-08)
#   task.sh start <id>                mark in_progress
#   task.sh meta <id> key=value …     set arbitrary metadata keys
#   task.sh goal <id|"goal text"> [--direction "<d>"] [--when "<check>"]
#                                     the two things a goal says about itself (P3, 2026-09-08): the
#                                     🧭 direction it serves and the ✅ check that closes it. Kept in
#                                     <store>/.goals (JSON) keyed by the goal's text, so a goal has one
#                                     answer however many rows carry it. An id names its row's goal;
#                                     an empty value clears; no flag prints what is set
#   task.sh show <id>                 print the JSON
#   task.sh list                      short list (id · status · subject); /tasks is the full view
#   task.sh store                     print the resolved store path
# Common flags: --session <sid8> · --new · --json (machine output)
set -uo pipefail
# PINS moved out of ~/.claude/tasks on 2026-09-04: the live session's own entry
# kept being swept from there while everything outside that directory survived.
# Reasoning and evidence in task-table.sh beside its PIN_DIR. Legacy read kept.
TASKS="$HOME/.claude/tasks"; PINS="$HOME/.claude/tasks-pins"; PINS_LEGACY="$TASKS/.live-session-map"
SESSION=""; NEW=0; JSON=0; ARGS=()
# Global flags are accepted BEFORE the subcommand as well as after it. Taking $1
# as the subcommand unconditionally meant `task.sh --session X update 87` died
# with "unknown command --session", which names the wrong thing: the flag is
# valid, only its position was not. Both orders now work, so nobody loses a call
# to a rule the help text never stated (owner, 2026-09-04).
while [ $# -gt 0 ]; do case "$1" in
  --session) SESSION="$2"; shift 2;; --new) NEW=1; shift;; --json) JSON=1; shift;;
  *) break;; esac; done

CMD="${1:-}"; [ -n "$CMD" ] && shift || { sed -n '2,/^# Common flags/p' "$0"; exit 2; }
case "$CMD" in -h|--help|help) sed -n '2,/^# Common flags/p' "$0"; exit 0;; esac
while [ $# -gt 0 ]; do case "$1" in
  --session) SESSION="$2"; shift 2;; --new) NEW=1; shift;; --json) JSON=1; shift;;
  -h|--help) sed -n '2,/^# Common flags/p' "$0"; exit 0;; *) ARGS+=("$1"); shift;; esac; done
set -- "${ARGS[@]+"${ARGS[@]}"}"

LIVE="${CLAUDE_CODE_SESSION_ID:-}"; LIVE8="${LIVE:0:8}"
resolve_store() {
  if [ -n "$SESSION" ]; then echo "$TASKS/session-${SESSION:0:8}"; return; fi
  if [ -n "$LIVE8" ] && [ -f "$PINS/$LIVE8" ]; then local p; p=$(cat "$PINS/$LIVE8"); p="session-${p#session-}"; [ -d "$TASKS/$p" ] && { echo "$TASKS/$p"; return; }; fi
  if [ -n "$LIVE8" ] && [ -f "$PINS_LEGACY/$LIVE8" ]; then local p; p=$(cat "$PINS_LEGACY/$LIVE8"); p="session-${p#session-}"; [ -d "$TASKS/$p" ] && { echo "$TASKS/$p"; return; }; fi
  if [ -n "$LIVE8" ] && [ -d "$TASKS/session-$LIVE8" ] && [ -n "$(ls "$TASKS/session-$LIVE8" 2>/dev/null)" ]; then echo "$TASKS/session-$LIVE8"; return; fi
  local r="$HOME/.claude/scripts/task-table/resolve-store.sh"
  if [ -x "$r" ]; then local d; d=$("$r" 2>/dev/null) && [ -n "$d" ] && [ -d "$d" ] && { echo "$d"; return; }; fi
  if [ "$NEW" = 1 ] && [ -n "$LIVE8" ]; then mkdir -p "$TASKS/session-$LIVE8"; echo "$TASKS/session-$LIVE8"; return; fi
  return 1
}
STORE=$(resolve_store) || { echo "task.sh: no task store resolves for this session (pass --session <sid8>, or --new to create one for $LIVE8)" >&2; exit 4; }
[ -d "$STORE" ] || { echo "task.sh: store missing: $STORE" >&2; exit 4; }
# A write stamps the store with its project once, so the renderer can find the
# project's view file from any shell directory. Reads never stamp it: a `list`
# run from a stranger's repo must not claim the store.
case "$CMD" in add|update|done|start|meta|goal)
  if [ ! -s "$STORE/.project" ]; then
    p=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null); [ -n "$p" ] || p="$PWD"
    printf '%s' "$p" > "$STORE/.project"
  fi;;
esac
LOCK="$STORE/.task-sh.lock"
# The rmdir on the normal path is not enough. If the wrapped function dies
# rather than returning (an unbound variable under `set -u`, a signal, a jq that
# is not there), the lock directory survives and every later call to that store
# waits 5s and then refuses. The store is wedged and nothing says why. Observed
# 2026-09-04 while adding the containment check: one bad indirect expansion took
# the store out for every subsequent call in the same probe.
#
# The EXIT trap covers the death paths; the explicit rmdir still covers the
# normal one, because the trap fires when the shell exits and a caller may run
# several locked operations in one invocation.
with_lock() {
  local i=0
  while ! mkdir "$LOCK" 2>/dev/null; do
    i=$((i+1))
    [ $i -gt 50 ] && { echo "task.sh: lock held >5s: $LOCK" >&2; return 1; }
    sleep 0.1
  done
  trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM
  "$@"
  local rc=$?
  rmdir "$LOCK" 2>/dev/null
  trap - EXIT INT TERM
  return $rc
}
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
# THE SEVEN STATES, ruled 2026-09-04. This is metadata.state, a SEPARATE field
# from the top-level status above. status belongs to the harness Task tool,
# which writes these same files and knows only its own three values; widening it
# would hand the harness a value it cannot read. So the model's states live
# beside it and the two are reconciled by the renderer, never merged.
#
# The count was contradictory and is settled here. REDESIGN.md is headed "Five
# states" and lists owner-gate, blocked, active, review, deferred. The migration
# plan's D2 adds `done`, because a completed row needs a state, and then says
# "five" at plan.md:35 and plan.md:68 while saying "one of six" at plan.md:118.
# The adversarial review caught that. D7a then added `unassigned` for the
# residual: the row is real and nobody has picked it up. Five plus done plus
# unassigned is SEVEN, and seven is what both write paths enforce.
#
# `unassigned` is the one that matters most. Without it the migration's residual
# had nowhere to go but `active`, which is 156 of 181 open rows in the real
# store and breaks the one-active-row-per-lane invariant on all four lanes at
# once. The state exists so that mapping never has to be made.
TASK_STATES="owner-gate blocked active review deferred done unassigned"
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
    --batch)
      # A milestone name has to be recallable. Owner 2026-09-05: a three-letter
      # acronym is the floor, "enough to be remembered and associative"; live
      # stores carry milestones named A, B, gates. Warn, never refuse (D5's
      # register precedent): the row still writes.
      _letters=$(printf '%s' "$2" | tr -cd 'A-Za-z')
      if [ "${#_letters}" -lt 3 ]; then
        printf 'task.sh: milestone "%s" is too thin to recall (owner floor: a three-letter acronym).\n  A milestone names a STATE: read it after "Right now," and it should parse. Row still written.\n' "$2" >&2
      fi
      FILTER="$FILTER | .metadata.batch=\$batch | .metadata.batch_at=\$batch_at"; ARGJ+=(--arg batch "$2" --arg batch_at "$(date -u +%FT%TZ)"); shift 2;;
    --lane) FILTER="$FILTER | .metadata.lane=\$lane"; ARGJ+=(--arg lane "$2"); shift 2;;
    # Where a row came from: the owner asked, a measurement found it, or an agent
    # inferred it. Speculation becomes visible structurally (forge-console's marker,
    # adopted 2026-09-08).
    --origin)
      case " $ORIGINS " in *" $2 "*) ;; *) flag_reject --origin "$2" "$ORIGINS"; return 2 ;; esac
      FILTER="$FILTER | .metadata.origin=\$origin"; ARGJ+=(--arg origin "$2"); shift 2;;
    --tier)
      case " $TIERS " in *" $2 "*) ;; *) flag_reject --tier "$2" "$TIERS"; return 2 ;; esac
      FILTER="$FILTER | .metadata.tier=\$tier"; ARGJ+=(--arg tier "$2"); shift 2;;
    --state)
      case " $TASK_STATES " in *" $2 "*) ;; *) flag_reject --state "$2" "$TASK_STATES"; return 2 ;; esac
      FILTER="$FILTER | .metadata.state=\$state"; ARGJ+=(--arg state "$2")
      # `done` is terminal on BOTH channels. Setting only metadata.state left
      # status=pending, so a ✅ row sat inside an open box whose meter read
      # "0 of 1" (adv-tasks §S, 2026-09-05). The two channels must agree.
      [ "$2" = done ] && FILTER="$FILTER | .status=\"completed\""
      shift 2;;
    --goal) FILTER="$FILTER | .metadata.goal=\$goal"; ARGJ+=(--arg goal "$2"); shift 2;;
    --priority) FILTER="$FILTER | .metadata.priority=\$prio"; ARGJ+=(--arg prio "$2"); shift 2;;
    --owner) FILTER="$FILTER | .metadata.owner=\$owner"; ARGJ+=(--arg owner "$2"); shift 2;;
    --note) FILTER="$FILTER | .metadata.note=\$note"; ARGJ+=(--arg note "$2"); shift 2;;
    --origin)
      case " $ORIGINS " in *" $2 "*) ;; *) flag_reject --origin "$2" "$ORIGINS"; return 2 ;; esac
      FILTER="$FILTER | .metadata.origin=\$origin"; ARGJ+=(--arg origin "$2"); shift 2;;
    # A USER: gate also records when it was believed, so a render can age it
    # against rulings that came later (alignment check 4).
    --blocked-on) FILTER="$FILTER | .metadata.blocked_on=\$bo | if (\$bo|startswith(\"USER:\")) then .metadata.blocked_on_at=\$bo_at else del(.metadata.blocked_on_at) end"; ARGJ+=(--arg bo "$2" --arg bo_at "$(date -u +%FT%TZ)"); shift 2;;
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
    --clear-blocked-on) FILTER="$FILTER | del(.metadata.blocked_on, .metadata.blocked_on_at)"; shift;;
    # A batch is a verdict too (later, parked, deferred), so it carries its date;
    # forge-console found nine this-week rows still deferred by a stale batch.
    --batch) FILTER="$FILTER | .metadata.batch=\$batch | .metadata.batch_at=\$batch_at"; ARGJ+=(--arg batch "$2" --arg batch_at "$(date -u +%FT%TZ)"); shift 2;;
    --verified) case "$2" in true) FILTER="$FILTER | .metadata.verified=true";; false) FILTER="$FILTER | .metadata.verified=false";; *) FILTER="$FILTER | .metadata.verified=\$ver"; ARGJ+=(--arg ver "$2");; esac; shift 2;;
    --blocked-by) FILTER="$FILTER | .blockedBy=\$bb"; ARGJ+=(--argjson bb "$(csv_to_arr "$2")"); shift 2;;
    --blocks) FILTER="$FILTER | .blocks=\$bl"; ARGJ+=(--argjson bl "$(csv_to_arr "$2")"); shift 2;;
    *) { printf 'task.sh: unknown flag %s\n' "$1"
         printf '  acceptable: %s\n' "$(known_flags)"; } >&2; return 2;;
  esac; done
}
# CONTAINMENT AT THE WRITE PATH, reconciling two rulings that pull apart.
#
# D6a: three levels ALWAYS, goal then milestone then task, milestone mandatory.
# D3b: a row with no goal is ALLOWED, rendered in a loud UNFILED band, with the
# agent nudged to file it. Owner note: "We should allow it, but nudge the agent
# to assign it to a goal if possible".
#
# Read together they are not in conflict, they describe two different rows:
#
#   goal AND no milestone  -> REFUSED. Three-levels-always makes this malformed
#                             on its face: the row claims an outcome and skips
#                             the stage. D6a says the 6 existing rows in this
#                             shape are few enough to backfill by hand, which is
#                             only true if new ones stop arriving.
#   neither                -> ALLOWED, with a loud nudge naming both flags. This
#                             is D3b's case and refusing it would contradict the
#                             ruling outright. The UNFILED band is where it
#                             becomes visible; the write path only has to make
#                             sure nobody files it by accident.
#
# A hard refusal on every unfiled add was the tempting reading of "mandatory"
# and would have been wrong twice over: it contradicts D3b, and it breaks every
# peer session and script that adds a row today, mid-flight, with no migration.
containment_check() {  # containment_check <goal> <milestone> <what>
  local goal="$1" ms="$2" what="$3"
  if [ -n "$goal" ] && [ -z "$ms" ]; then
    { printf 'task.sh %s: a row with a goal must name a milestone (D6a: three levels always).\n' "$what"
      printf '  goal given : %s\n' "$goal"
      printf '  add        : --batch "<the state this row moves the goal into>"\n'
      printf '  a milestone names a STATE, not activity. Read it aloud after "Right now,":\n'
      printf '  if it parses as true or false about the world it is a milestone.\n'; } >&2
    return 2
  fi
  if [ -z "$goal" ] && [ -z "$ms" ]; then
    { printf 'task.sh %s: this row is UNFILED, and it will render in the UNFILED band.\n' "$what"
      printf '  allowed (D3b), but file it if you can:\n'
      printf '  --goal "<the behaviour change>" --batch "<the state this row reaches>"\n'; } >&2
  fi
  return 0
}

do_add() {
  local subject="$1"; shift; local id; id=$(next_id); [ -n "$id" ] || id=1
  # Read goal and batch out of the args without consuming them; patch_filter
  # still gets the full list. A first version used indirect expansion over
  # $(seq 1 $#), which reads past the end on a trailing flag and dies under
  # `set -u`, and because the death happened inside with_lock the lock was never
  # released and the next call to this store hung for 5s and refused. A plain
  # positional walk cannot run off the end.
  local _g="" _b="" _prev=""
  for _a in "$@"; do
    case "$_prev" in
      --goal)  _g="$_a" ;;
      --batch) _b="$_a" ;;
    esac
    _prev="$_a"
  done
  containment_check "$_g" "$_b" add || return 2
  # Q5a, ruled 2026-09-05, built for add on 2026-09-08: a subject past 70 chars is
  # cut at a word and the rest moves to the note, said aloud. Median subject in
  # the forge-console store was 97 chars, which is what made the screen unreadable.
  if [ "${#subject}" -gt 70 ]; then
    local _head _tail; _head="${subject:0:70}"; _head="${_head% *}"; _tail="${subject#"$_head"}"; _tail="${_tail# }"
    case " $* " in
      *" --note "*) printf 'task.sh add: subject is %s chars (ceiling 70, Q5a); kept whole because --note is set. Shorten it.\n' "${#subject}" >&2 ;;
      *) subject="$_head"; set -- "$@" --note "$_tail"
         printf 'task.sh add: subject cut at a word under 70 chars (Q5a); the rest is in the note: "%s"\n' "$_tail" >&2 ;;
    esac
  fi
  patch_filter "$@" || return 2
  jq -n --arg id "$id" --arg s "$subject" '{id:$id,subject:$s,description:"",status:"pending",activeForm:null,blocks:[],blockedBy:[],metadata:{}}' \
    | jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" | write_json "$STORE/$id.json"
  # A note draws on the table and a description is what a close is judged
  # against; rows with a note and no description looked complete and could
  # not be judged (forge-brains review F1, ledger 43, 2026-09-08).
  if [ "$(jq -r '.description // ""' "$STORE/$id.json")" = "" ]; then
    case " $* " in *" --note "*) echo "task.sh add: --note without --desc; the note draws on the table, the description is what a close is judged against. Add one: task.sh update $id --desc \"<the ask>\"" >&2 ;; esac
  fi
  [ "$JSON" = 1 ] && cat "$STORE/$id.json" || echo "added #$id: $subject  ($(basename "$STORE"))"
}
do_update() {
  local id="$1"; shift; local f="$STORE/$id.json"; [ -f "$f" ] || { echo "task.sh: no task #$id in $(basename "$STORE")" >&2; return 1; }
  # A reversed edge is refused: six children were marked as waiting on their
  # parent while the parent already waited on them, and four startable rows
  # vanished from the render (forge-console, ledger 45, 2026-09-08).
  local _a=("$@") _i=0
  while [ $_i -lt ${#_a[@]} ]; do
    if [ "${_a[$_i]}" = "--blocked-by" ]; then
      local _n; for _n in $(printf '%s' "${_a[$((_i+1))]:-}" | tr ',' ' '); do
        if [ -f "$STORE/$_n.json" ] && jq -e --arg me "$id" '.blockedBy | index($me)' "$STORE/$_n.json" >/dev/null 2>&1; then
          echo "task.sh update: --blocked-by $_n is backwards; #$_n already waits on #$id. Clear one side first (update $_n --blocked-by <others>)." >&2; return 2
        fi
      done
    fi; _i=$((_i+1))
  done
  patch_filter "$@" || return 2
  jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" "$f" | write_json "$f"
  # The echo names the state too when one is set; "updated #185: pending" after
  # --state review read as the update failing (forge-brains, 2026-09-08).
  [ "$JSON" = 1 ] && cat "$f" || echo "updated #$id: $(jq -r '"\(.status)\(if .metadata.state then " (" + .metadata.state + ")" else "" end) · \(.subject)"' "$f")"
}
# `meta` is the deliberate escape hatch for keys the flags do not cover, so it
# stays open to new keys. What it must NOT be is a way around the vocabularies
# the flag path enforces: `--tier nonsense` is refused while `meta tier=nonsense`
# wrote it without a word, which makes the validator decorative. Three tiers of
# response, matched to how certain the defect is.
#
# A shadow key is REFUSED. metadata.status is not the status: the renderer reads
# the top-level field, so writing the metadata one mints a second answer to the
# same question and the next reader picks whichever they find first.
META_SHADOW="status subject description id activeForm blocks blockedBy"
# A closed vocabulary is REFUSED, reading the same lists the flags use so the two
# cannot drift. Add `state` here the day D2's enum lands and both paths inherit it.
meta_vocab() { case "$1" in
    tier) printf '%s' "$TIERS" ;;
    # The placeholder left here on 2026-09-04 said to add `state` the day D2's
    # enum landed, so that both write paths inherit it. D7a landed it. Without
    # this line `task.sh meta <id> state=nonsense` walks straight around the
    # --state validator, which is what made the flag-path check decorative for
    # tier and is the whole defect #17 was filed for.
    state) printf '%s' "$TASK_STATES" ;;
    # `verified` is NOT closed: the flag path takes true, false, prod, or the
    # instrument's own name, and meta refused the name for a week while the
    # charter told every lane to write it (vb-fable, 2026-09-08).
    delegated_confirmed) printf '%s' "true false" ;;
    *) return 1 ;;
  esac; }
# An unfamiliar key is WARNED and still written, because refusing it would close
# the escape hatch. This is the tier that catches a typo: `laen=hands` wrote a key
# nothing reads and said nothing.
META_KNOWN="class domain batch batch_at goal lane tier priority owner note origin blocked_on blocked_on_at board_card delegated_to delegated_at delegated_confirmed verified state milestone"
ORIGINS="asked measured inferred"

do_meta() {
  local id="$1"; shift; local f="$STORE/$id.json"; [ -f "$f" ] || { echo "task.sh: no task #$id" >&2; return 1; }
  FILTER="."; ARGJ=(); local kv k v vocab
  for kv in "$@"; do k="${kv%%=*}"; v="${kv#*=}"
    case " $META_SHADOW " in *" $k "*)
      { printf 'task.sh meta: "%s" shadows the top-level field of the same name.\n' "$k"
        printf '  metadata.%s is not read by anything; writing it mints a second answer.\n' "$k"
        printf '  use: task.sh update %s --%s <value>\n' "$id" "$k"; } >&2
      return 2 ;;
    esac
    if vocab=$(meta_vocab "$k"); then
      case " $vocab " in *" $v "*) ;; *) flag_reject "meta $k" "$v" "$vocab"; return 2 ;; esac
    fi
    case " $META_KNOWN " in *" $k "*) ;; *)
      { printf 'task.sh meta: "%s" is not a key anything reads; writing it anyway.\n' "$k"
        printf '  known: %s\n' "$META_KNOWN"; } >&2 ;;
    esac
    case "$v" in true|false|null) FILTER="$FILTER | .metadata[\"$k\"]=$v";; *) FILTER="$FILTER | .metadata[\"$k\"]=\$v_$k"; ARGJ+=(--arg "v_$k" "$v");; esac; done
  jq "${ARGJ[@]+"${ARGJ[@]}"}" "$FILTER" "$f" | write_json "$f" && echo "meta #$id: $(jq -c .metadata "$f")"
}
# Goal-level fields. A goal is a TAG rows carry, not a row, so anything said about
# the goal itself has nowhere to live on a row without inviting the rows to
# disagree (the batch_at problem, one level up). The sidecar holds one entry per
# goal text. The renderer draws the direction above the box and the check under
# its meter; --json carries both. The goal named must be one some row carries,
# because a field on a goal nobody filed is a note to no one.
# No .json suffix, on purpose: pathlib's "*.json" matches dotfiles (the shell's
# and glob.glob's do not), and the renderer read a sidecar named .goals.json as a
# row on the first render (KeyError: status). Same convention as .project.
GOALS_FILE="$STORE/.goals"
do_goal() {
  local ref="${1:-}"; shift; local goal="" dir="" when="" set_dir=0 set_when=0
  [ -n "$ref" ] || { echo "task.sh goal: need <id> or \"<goal text>\"" >&2; return 2; }
  case "$ref" in
    *[!0-9]*) goal="$ref" ;;
    *) local f="$STORE/$ref.json"; [ -f "$f" ] || { echo "task.sh goal: no task #$ref" >&2; return 1; }
       goal=$(jq -r '.metadata.goal // empty' "$f")
       [ -n "$goal" ] || { echo "task.sh goal: #$ref carries no goal; file it first: task.sh update $ref --goal \"<g>\" --batch \"<m>\"" >&2; return 2; } ;;
  esac
  while [ $# -gt 0 ]; do case "$1" in
    --direction|--when)
      [ $# -ge 2 ] || { printf 'task.sh goal: %s needs a value (an empty string clears it)\n' "$1" >&2; return 2; }
      if [ "$1" = --direction ]; then dir="$2"; set_dir=1; else when="$2"; set_when=1; fi; shift 2 ;;
    *) { printf 'task.sh goal: unknown flag %s\n' "$1"; printf '  flags: --direction "<d>"  --when "<check>"  (empty value clears; no flag shows)\n'; } >&2; return 2 ;;
  esac; done
  if ! cat "$STORE"/[0-9]*.json 2>/dev/null | jq -e --arg g "$goal" 'select(.metadata.goal==$g)' >/dev/null 2>&1; then
    { printf 'task.sh goal: no row in this store carries the goal "%s"\n' "$goal"
      printf '  goals here:\n'; cat "$STORE"/[0-9]*.json 2>/dev/null | jq -r '.metadata.goal // empty' | sort -u | sed 's/^/    /'; } >&2
    return 1
  fi
  [ -s "$GOALS_FILE" ] || echo '{}' > "$GOALS_FILE"
  if [ "$set_dir" = 0 ] && [ "$set_when" = 0 ]; then
    jq --arg g "$goal" '{goal: $g} + (.[$g] // {})' "$GOALS_FILE"; return 0
  fi
  jq --arg g "$goal" --arg d "$dir" --arg w "$when" --argjson sd "$set_dir" --argjson sw "$set_when" \
     --arg ts "$(date -u +%FT%TZ)" '
    .[$g] = ((.[$g] // {})
      | (if $sd == 1 then (if $d == "" then del(.direction) else .direction = $d end) else . end)
      | (if $sw == 1 then (if $w == "" then del(.when) else .when = $w end) else . end)
      | .set_at = $ts)' "$GOALS_FILE" | write_json "$GOALS_FILE" \
    && echo "goal: $(jq -c --arg g "$goal" '{goal: $g} + .[$g]' "$GOALS_FILE")"
}
# A row that closes without saying what proved it is the liberty the owner named
# in the definition of done. The close still lands; the omission is said aloud
# (alignment check 9: done rows name their instrument).
verified_warn() {
  local f="$STORE/$1.json"; [ -f "$f" ] || return 0
  if [ "$(jq -r '.status' "$f")" = completed ] && [ -z "$(jq -r '.metadata.verified // empty' "$f")" ]; then
    echo "task.sh: #$1 closed with NO instrument named. What proved it?" >&2
    echo "  --verified true (ran it) · prod (seen live) · \"<the check, run or artifact>\"" >&2
  fi
}
case "$CMD" in
  store) echo "$STORE" ;;
  add) [ -n "${1:-}" ] || { echo "task.sh add: need a subject" >&2; exit 2; }; with_lock do_add "$@" ;;
  update) [ -n "${1:-}" ] || { echo "task.sh update: need an id" >&2; exit 2; }; with_lock do_update "$@" || exit $?; verified_warn "$1" ;;
  # status and metadata.state are two channels for one fact. `done` used to write
  # only status, so a row closed while blocked kept state=blocked forever and the
  # renderer had to prefer status to avoid drawing it 🟠 (found 2026-09-05, #32).
  # Keep them in step at the write.
  # `done 7 8 --verified "<what proved it>"`: the flag used to be read as two more
  # ids, so the rows closed unverified and the warning then asked for the very
  # flag it had just misparsed (vb-fable, 2026-09-08).
  done) rc=0; ver=""; ids=()
    while [ $# -gt 0 ]; do case "$1" in --verified) ver="${2:-}"; shift 2;; --by) ver="${2:-}"; shift 2;; *) ids+=("$1"); shift;; esac; done
    for id in "${ids[@]+"${ids[@]}"}"; do
      if [ -n "$ver" ]; then with_lock do_update "$id" --status completed --state done --verified "$ver" || rc=$?
      else with_lock do_update "$id" --status completed --state done || rc=$?; verified_warn "$id"; fi
    done; exit $rc ;;
  # The one close verb that cannot forget its instrument: close <id> --by "<what proved it>".
  close)
    id="${1:-}"; [ -n "$id" ] || { echo "task.sh close: need an id" >&2; exit 2; }
    [ "${2:-}" = "--by" ] && [ -n "${3:-}" ] || { echo "task.sh close: say what proved it: close $id --by \"<the check, run or artifact>\"  (true = ran it, prod = seen live, false = nothing did, with one clause why)" >&2; exit 2; }
    with_lock do_update "$id" --status completed --state done --verified "$3" ;;
  to-board)
    id="${1:-}"; f="$STORE/$id.json"
    [ -n "$id" ] && [ -f "$f" ] || { echo "task.sh to-board: need an id that exists in $STORE" >&2; exit 2; }
    subj=$(jq -r '.subject' "$f")
    card=$(bash "$HOME/.claude/scripts/kanban/kanban.sh" add "$subj" --json 2>/dev/null | jq -r '.id // empty' 2>/dev/null)
    [ -n "$card" ] || { echo "task.sh to-board: the board did not take the row. Is this project registered? kanban.sh init" >&2; exit 4; }
    with_lock do_update "$id" --status completed --state done --verified "moved to board card $card"
    with_lock do_meta "$id" "board_card=$card"
    echo "moved #$id to the board as card $card; the row closes here with the pointer" ;;
  start) with_lock do_update "$1" --status in_progress --state active ;;
  meta) [ -n "${2:-}" ] || { echo "task.sh meta: need <id> key=value…" >&2; exit 2; }; with_lock do_meta "$@" ;;
  goal) with_lock do_goal "$@" ;;
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

#!/usr/bin/env bash
# group.sh — a named set of sessions working one goal, with the things a lane kept
# losing on its own: the goal every member reads, the store each lane's rows live
# in, the authority line that says what may be decided alone, and one address.
#
# Owner rulings 2026-08-26 (board 2hfsi577 and 8f28k41o): goals move from
# per-session to per-group; the warden and the revive take their roster from the
# group; a watcher seat speaks to members only as ADVICE or STOP, never as an
# instruction, and a member may refuse advice with a reason the owner can see.
#
#   group.sh create <name> --goal "…" --authority "…" [--cwd DIR]
#   group.sh join <name> <sid> [--alias A] [--store SID8] [--watcher]
#   group.sh leave <name> <sid>
#   group.sh show <name>            the file, pretty
#   group.sh list                   every group, members and their state
#   group.sh members <name>         member sids, one per line (roster feed)
#   group.sh store <name> <sid>     the store declared for that member (exit 1 if none)
#   group.sh send <name> --from <alias> [--kind inform|query|request] [--reply-by T] <body>
#                                   fan out to every member alias except the sender
#   group.sh advise <name> --from <watcher-alias> <body>   inform, body prefixed [ADVICE]
#   group.sh stop   <name> --from <watcher-alias> <why>    inform, body prefixed [STOP], logged
#   group.sh refuse <msg-id> --from <alias> <why>          reply "[REFUSED] <why>", logged
#
# Files: ~/.claude/groups/<name>.json  (GROUPS_DIR overrides). Writes are atomic.
set -uo pipefail
G="${GROUPS_DIR:-$HOME/.claude/groups}"; IPC="${GROUP_IPC_CMD:-claude-ipc}"; LOG="$G/protocol.jsonl"
mkdir -p "$G"
usage() { sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
f() { printf '%s/%s.json' "$G" "$1"; }
need() { [ -f "$(f "$1")" ] || { echo "group.sh: no group '$1'" >&2; exit 1; }; }
save() { local tmp; tmp=$(mktemp "$G/.tmp.XXXXXX"); cat > "$tmp" && mv -f "$tmp" "$(f "$1")"; }
plog() { jq -nc --arg ts "$(date -u +%FT%TZ)" --arg g "$1" --arg act "$2" --arg from "$3" --arg body "$4" '{ts:$ts,group:$g,act:$act,from:$from,body:$body}' >> "$LOG"; }
cmd="${1:-}"; shift || true
case "$cmd" in
  create)
    name="${1:?name}"; shift; goal=""; auth=""; cwd="$PWD"
    while [ $# -gt 0 ]; do case "$1" in --goal) goal="$2"; shift 2;; --authority) auth="$2"; shift 2;; --cwd) cwd="$2"; shift 2;; *) usage;; esac; done
    [ -n "$goal" ] || { echo "group.sh create: --goal is required; a group without a goal is a mailing list" >&2; exit 2; }
    [ -n "$auth" ] || { echo "group.sh create: --authority is required (what may members decide alone?)" >&2; exit 2; }
    [ -f "$(f "$name")" ] && { echo "group.sh: '$name' exists; edit with join/leave" >&2; exit 1; }
    jq -n --arg n "$name" --arg g "$goal" --arg a "$auth" --arg c "$cwd" --arg ts "$(date -u +%FT%TZ)" \
      '{name:$n,goal:$g,authority:$a,cwd:$c,created:$ts,members:{}}' | save "$name"
    echo "group $name created; join members with: group.sh join $name <sid> --alias <a> --store <sid8>" ;;
  join)
    name="${1:?name}"; sid="${2:?sid}"; shift 2; need "$name"; alias=""; store=""; role="member"
    while [ $# -gt 0 ]; do case "$1" in --alias) alias="$2"; shift 2;; --store) store="$2"; shift 2;; --watcher) role="watcher"; shift;; *) usage;; esac; done
    [ -n "$store" ] || [ "$role" = watcher ] || { echo "group.sh join: --store <sid8> is required for a member; without it the revive refuses the lane" >&2; exit 2; }
    jq --arg s "$sid" --arg a "$alias" --arg st "$store" --arg r "$role" --arg ts "$(date -u +%FT%TZ)" \
      '.members[$s] = {alias:$a, store:$st, role:$r, joined:$ts}' "$(f "$name")" | save "$name"
    # The member's own goal file carries the group so per-session readers still work.
    gf="$HOME/.claude/goals/$sid.json"
    if [ -f "$gf" ]; then jq --arg n "$name" --arg st "$store" '.group=$n | (if $st!="" then .store=$st else . end)' "$gf" > "$gf.tmp" && mv -f "$gf.tmp" "$gf"; fi
    echo "$sid joined $name as $role${store:+ (store $store)}" ;;
  leave) name="${1:?}"; sid="${2:?}"; need "$name"; jq --arg s "$sid" 'del(.members[$s])' "$(f "$name")" | save "$name"; echo "left" ;;
  show) need "${1:?}"; jq . "$(f "$1")" ;;
  list) for x in "$G"/*.json; do [ -e "$x" ] || continue; jq -r '"\(.name)  goal: \(.goal[0:70])\n" + ([.members|to_entries[]|"   \(.key[0:8]) \(.value.role) \(.value.alias) store=\(.value.store)"]|join("\n"))' "$x"; done ;;
  members) need "${1:?}"; jq -r '.members | to_entries[] | select(.value.role=="member") | .key' "$(f "$1")" ;;
  store) need "${1:?}"; s=$(jq -r --arg k "${2:?sid}" '.members[$k].store // empty' "$(f "$1")"); [ -n "$s" ] || exit 1; printf '%s\n' "$s" ;;
  send|advise|stop)
    name="${1:?name}"; shift; need "$name"; from=""; kind="inform"; rb=""; body=""
    while [ $# -gt 0 ]; do case "$1" in --from) from="$2"; shift 2;; --kind) kind="$2"; shift 2;; --reply-by) rb="$2"; shift 2;; *) body="$body${body:+ }$1"; shift;; esac; done
    [ -n "$from" ] && [ -n "$body" ] || usage
    case "$cmd" in
      advise) kind=inform; body="[ADVICE from $from] $body (you may refuse with: group.sh refuse <msg-id> --from <you> <why>)" ;;
      stop)   kind=inform; body="[STOP from $from] $body (stop the current row; reply with what you were doing; the owner sees this)" ;;
    esac
    [ "$cmd" != send ] && { r=$(jq -r --arg a "$from" '.members[] | select(.alias==$a) | .role' "$(f "$name")"); [ "$r" = watcher ] || { echo "group.sh $cmd: '$from' is not a watcher of $name; members speak with send" >&2; exit 1; }; }
    n=0; for a in $(jq -r --arg me "$from" '.members[] | select(.alias!="" and .alias!=$me) | .alias' "$(f "$name")"); do
      $IPC send --to "$a" --from "$from" --kind "$kind" ${rb:+--reply-by "$rb"} "$body" >/dev/null 2>&1 && n=$((n+1)); done
    plog "$name" "$cmd" "$from" "$body"; echo "$cmd: $n member(s) reached" ;;
  refuse)
    mid="${1:?msg-id}"; shift; from=""; why=""
    while [ $# -gt 0 ]; do case "$1" in --from) from="$2"; shift 2;; *) why="$why${why:+ }$1"; shift;; esac; done
    [ -n "$from" ] && [ -n "$why" ] || usage
    $IPC reply "$mid" --from "$from" "[REFUSED] $why" >/dev/null 2>&1; plog "-" refuse "$from" "$mid: $why"; echo "refused $mid, logged for the owner" ;;
  *) usage ;;
esac

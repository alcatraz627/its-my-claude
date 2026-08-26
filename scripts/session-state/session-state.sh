#!/usr/bin/env bash
# session-state.sh — make "finished" a fact on disk instead of a sentence in chat.
#
# A supervisor watching a session cannot tell a clean finish from a death: both
# are silence. This script lets a session declare working | blocked | finished
# at the moment it would otherwise just say "lane empty" or "handing off", so a
# reader (the warden's revive layer, a resume, the owner) can act on the state.
#
# The one rule with teeth: `set finished` is REFUSED while the session's task
# store still holds an agent-ready row. The refusal names the row. Absence of a
# state file never means finished; readers derive from transcript activity.
#
#   session-state.sh set working|blocked|finished [--reason "…"] [--next "…"]
#                    [--sid SID] [--store SID8] [--by WHO]
#   session-state.sh show [SID]        print the JSON (exit 3 when no file)
#   session-state.sh clear [SID]       remove the file (the next real work turn)
#   session-state.sh path [SID]        print where the file lives
#
# Env: SESSION_STATE_DIR (default ~/.claude/session-state), CLAUDE_CODE_SESSION_ID.
set -uo pipefail
DIR="${SESSION_STATE_DIR:-$HOME/.claude/session-state}"
TT="$HOME/.claude/scripts/task-table/task-table.sh"
cmd="${1:-}"; shift || true
sid="${CLAUDE_CODE_SESSION_ID:-}"; state=""; reason=""; next=""; store=""; by="agent"
case "$cmd" in
  set) state="${1:-}"; shift || true ;;
  show|clear|path) [ -n "${1:-}" ] && [ "${1#--}" = "$1" ] && { sid="$1"; shift; } ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --reason) reason="${2:-}"; shift 2 ;;
    --next)   next="${2:-}";   shift 2 ;;
    --sid)    sid="${2:-}";    shift 2 ;;
    --store)  store="${2:-}";  shift 2 ;;
    --by)     by="${2:-}";     shift 2 ;;
    *) echo "session-state: unknown flag $1" >&2; exit 2 ;;
  esac
done
[ -n "$sid" ] || { echo "session-state: no session id (pass --sid or set CLAUDE_CODE_SESSION_ID)" >&2; exit 2; }
f="$DIR/$sid.json"
case "$cmd" in
  path)  printf '%s\n' "$f"; exit 0 ;;
  show)  [ -f "$f" ] || { echo "no state file for $sid (derive from activity; never assume finished)" >&2; exit 3; }; cat "$f"; exit 0 ;;
  clear) [ -f "$f" ] && trash "$f" 2>/dev/null || true; exit 0 ;;
esac
case "$state" in working|blocked|finished) ;; *) echo "session-state: state must be working|blocked|finished" >&2; exit 2 ;; esac
if [ "$state" != working ] && [ -z "$reason" ]; then echo "session-state: $state requires --reason" >&2; exit 2; fi
# The refusal. Resolve the store (explicit --store, else task-table's own pin/live
# resolution) and look for a row the agent could run right now.
store_note="${store:-unresolved}"; ready_row=""
if [ "$state" = finished ]; then
  store_note="unresolved"
  if [ -n "$store" ]; then js=$(bash "$TT" --session "$store" --json 2>/dev/null); else js=$(bash "$TT" --json 2>/dev/null); fi
  if printf '%s' "$js" | jq -e '.store' >/dev/null 2>&1; then
    store_note=$(printf '%s' "$js" | jq -r '.store')
    ready_row=$(printf '%s' "$js" | jq -r -f "$HOME/.claude/scripts/task-table/agent-ready.jq" | jq -r 'first | select(.!=null) | "#\(.id) \(.subject)"')
  fi
  if [ -n "$store" ] && [ "$store_note" = unresolved ]; then
    echo "session-state: REFUSED finished — store '$store' does not resolve; a wrong store name is not a clean finish" >&2
    exit 1
  fi
  if [ -n "$ready_row" ]; then
    echo "session-state: REFUSED finished — store $store_note still has an agent-ready row: $ready_row" >&2
    echo "  do that row, or declare 'blocked' with the reason it cannot run" >&2
    exit 1
  fi
fi
mkdir -p "$DIR"
tmp=$(mktemp "$DIR/.tmp.XXXXXX")
jq -n --arg sid "$sid" --arg state "$state" --arg reason "$reason" --arg next "$next" \
      --arg store "$store_note" --arg by "$by" --arg ts "$(date -u +%FT%TZ)" \
      '{sid:$sid,state:$state,reason:$reason,next_action:$next,store:$store,by:$by,ts:$ts}' > "$tmp" && mv -f "$tmp" "$f"
printf 'session-state: %s = %s%s\n' "${sid:0:8}" "$state" "${reason:+ ($reason)}"

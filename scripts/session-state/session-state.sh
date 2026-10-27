#!/usr/bin/env bash
# session-state.sh: make "finished" a fact on disk instead of a sentence in chat.
#
# A supervisor watching a session cannot tell a clean finish from a death: both
# are silence. This script lets a session declare working | blocked | finished
# at the moment it would otherwise just say "lane empty" or "handing off", so a
# reader (the warden's revive layer, a resume, the owner) can act on the state.
#
# The one rule with teeth: `set finished` is REFUSED while the session's goal
# record (the drive's goal, else the linked one, else --goal) still holds an
# agent-ready row, read through queue-run.sh ready. The refusal names the row.
# Absence of a state file never means finished; readers derive from activity.
#
#   session-state.sh set working|blocked|finished [--reason "…"] [--next "…"]
#                    [--sid SID] [--goal G] [--by WHO]
#   session-state.sh show [SID]        print the JSON (exit 3 when no file)
#   session-state.sh clear [SID]       remove the file (the next real work turn)
#   session-state.sh path [SID]        print where the file lives
#
# --store is accepted and ignored: the retired task store no longer decides.
# Env: SESSION_STATE_DIR (default ~/.claude/session-state), CLAUDE_CODE_SESSION_ID.
set -uo pipefail
DIR="${SESSION_STATE_DIR:-$HOME/.claude/session-state}"
QR="$HOME/.claude/scripts/goals/queue-run.sh"
cmd="${1:-}"; shift || true
sid="${CLAUDE_CODE_SESSION_ID:-}"; state=""; reason=""; next=""; goal=""; by="agent"
case "$cmd" in
  set) state="${1:-}"; shift || true ;;
  show|clear|path) [ -n "${1:-}" ] && [ "${1#--}" = "$1" ] && { sid="$1"; shift; } ;;
  *) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --reason) reason="${2:-}"; shift 2 ;;
    --next)   next="${2:-}";   shift 2 ;;
    --sid)    sid="${2:-}";    shift 2 ;;
    --goal)   goal="${2:-}";   shift 2 ;;
    --store)  echo "session-state: --store is retired and ignored; the goal record decides" >&2; shift 2 ;;
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
# The refusal. Ask the goal record for a row the agent could run right now.
# No goal at all (none linked, no drive, no --goal) means no queue to refuse on.
goal_note="${goal:-none}"
if [ "$state" = finished ]; then
  if [ -n "$goal" ]; then rows=$(bash "$QR" ready --sid "$sid" --goal "$goal" 2>/dev/null); rc=$?
  else rows=$(bash "$QR" ready --sid "$sid" 2>/dev/null); rc=$?; fi
  if [ $rc -eq 2 ] && [ -n "$goal" ]; then
    echo "session-state: REFUSED finished: goal '$goal' does not resolve; a wrong goal name is not a clean finish" >&2
    exit 1
  fi
  [ $rc -eq 2 ] || goal_note=$(bash "$QR" status --sid "$sid" ${goal:+--goal "$goal"} 2>/dev/null | sed -n '1s/^goal \([0-9a-f]*\).*/\1/p')
  if [ $rc -eq 0 ] && [ -n "$rows" ]; then
    echo "session-state: REFUSED finished: goal ${goal_note:-?} still has an agent-ready row: $(printf '%s\n' "$rows" | head -n 1)" >&2
    echo "  do that row (queue-run.sh next), park it, or declare 'blocked' with the reason it cannot run" >&2
    exit 1
  fi
fi
mkdir -p "$DIR"
tmp=$(mktemp "$DIR/.tmp.XXXXXX")
jq -n --arg sid "$sid" --arg state "$state" --arg reason "$reason" --arg next "$next" \
      --arg goal "${goal_note:-none}" --arg by "$by" --arg ts "$(date -u +%FT%TZ)" \
      '{sid:$sid,state:$state,reason:$reason,next_action:$next,goal:$goal,by:$by,ts:$ts}' > "$tmp" && mv -f "$tmp" "$f"
printf 'session-state: %s = %s%s\n' "${sid:0:8}" "$state" "${reason:+ ($reason)}"

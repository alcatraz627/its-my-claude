#!/usr/bin/env bash
# queue-stop: blocks a stop while the drive's goal has an agent-ready row, once
# per record state; silent with no drive, nothing ready, or the mute; re-blocks
# under stop_hook_active only after progress; three unchanged stops park the row
# in hand. Then each guard is broken on a scratch copy and must go red.
# Sandbox HOME; never touches ~/.claude/goals or a live marker.
set -uo pipefail
REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/qstop-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals" "$SB/.claude/scripts/hooks" "$SB/.claude/scripts/session-mgmt" "$SB/repo"
cp -f "$REAL/.claude/scripts/goals/gs" "$REAL/.claude/scripts/goals/goalstore.py" "$REAL/.claude/scripts/goals/queue_run.py" "$REAL/.claude/scripts/goals/queue-run.sh" "$SB/.claude/scripts/goals/"
cp -f "$REAL/.claude/scripts/hooks/hook-common.sh" "$REAL/.claude/scripts/hooks/queue-stop.sh" "$SB/.claude/scripts/hooks/"
cp -f "$REAL/.claude/scripts/session-mgmt/compact-gate.sh" "$SB/.claude/scripts/session-mgmt/"
export HOME="$SB"
SID="qqqqqqqq-0000-4000-8000-000000000000"
export CLAUDE_CODE_SESSION_ID="$SID" COMPACT_GATE_DIR="$SB/compact" COMPACT_GATE_LOG="$SB/compact.jsonl"
GS="$HOME/.claude/scripts/goals/gs"; QR="$HOME/.claude/scripts/goals/queue-run.sh"
GOALS="$HOME/.claude/goals"; MARK="/tmp/claude-queuestop-${SID:0:8}"
trap 'export HOME="$REAL"; trash "$SB" 2>/dev/null; trash "$MARK" 2>/dev/null; true' EXIT
git -C "$SB/repo" init -q 2>/dev/null
cd "$SB/repo" || exit 1
pass=0; fail=0
ok(){ echo "  ok    $1"; pass=$((pass+1)); }
bad(){ echo "  FAIL  $1"; fail=$((fail+1)); }

# fresh [on]: a linked goal with #1 alpha and #2 beta; with "on", the drive is on.
fresh(){
  [ -d "$GOALS" ] && trash "$GOALS"
  [ -f "$MARK" ] && trash "$MARK"
  [ -f "$HOME/.claude/.no-queue-stop-gate" ] && trash "$HOME/.claude/.no-queue-stop-gate"
  "$GS" new "The stop hook keeps the run going" --accept "functional: the suite passes" >/dev/null 2>&1
  GID=$(ls "$GOALS/by-id" | sed 's/.json//' | head -1)
  "$GS" link "$GID" >/dev/null 2>&1
  "$GS" milestone "$GID" "The rows are worked" >/dev/null 2>&1
  "$GS" task "$GID" m1 "alpha" >/dev/null 2>&1
  "$GS" task "$GID" m1 "beta" >/dev/null 2>&1
  [ "${1:-}" = on ] && bash "$QR" on >/dev/null 2>&1
  return 0
}
# stop <hook> [continuing] [reply]: feed one Stop event; prints the hook's stdout.
stop(){ printf '{"session_id":"%s","transcript_path":"","stop_hook_active":%s,"last_assistant_message":%s}' \
  "$SID" "${2:-false}" "$(printf '%s' "${3:-Row done.}" | jq -Rs .)" | bash "$1"; }
blocks(){ printf '%s' "$1" | rg -q '"decision":"block"'; }
state_of(){ python3 -c "import json,sys;r=json.load(open(sys.argv[1]));print(next(t['state'] for t in r['tasks'] if t['id']==sys.argv[2]))" "$GOALS/by-id/$GID.json" "$1"; }

h_no_drive(){ fresh; [ -z "$(stop "$1")" ]; }
h_blocks(){ fresh on; local o; o=$(stop "$1"); blocks "$o" && printf '%s' "$o" | rg -q 'Next: #1 alpha'; }
h_once_per_state(){ fresh on; stop "$1" >/dev/null; [ -z "$(stop "$1")" ]; }
h_nothing_ready(){ fresh on
  "$GS" close "$GID" 1 --by "true: fixture" >/dev/null 2>&1
  "$GS" gate "$GID" 2 "rule on beta" --do "say yes" >/dev/null 2>&1
  [ -z "$(stop "$1")" ]; }
h_continuing(){ fresh on
  stop "$1" >/dev/null
  [ -z "$(stop "$1" true)" ] || return 1                       # no progress since the block: let through
  "$GS" close "$GID" 1 --by "true: fixture" >/dev/null 2>&1
  local o; o=$(stop "$1" true); blocks "$o" && printf '%s' "$o" | rg -q 'Next: #2 beta'; }
h_backstop(){ fresh on
  bash "$QR" next >/dev/null
  stop "$1" >/dev/null; stop "$1" >/dev/null
  local o; o=$(stop "$1")
  blocks "$o" || return 1
  printf '%s' "$o" | rg -q 'Parked #1 alpha' || return 1
  printf '%s' "$o" | rg -q 'Next: #2 beta' || return 1
  [ "$(state_of 1)" = deferred ] || return 1
  rg -q '"by": "queue-stop"' "$GOALS/runs/$GID.jsonl"; }
h_backstop_not_while_continuing(){ fresh on
  bash "$QR" next >/dev/null
  stop "$1" >/dev/null; stop "$1" true >/dev/null; stop "$1" true >/dev/null
  [ "$(state_of 1)" = active ]; }
h_question(){ fresh on
  local o; o=$(stop "$1" false $'Built it.\n\nShould I also do beta?')
  blocks "$o" && printf '%s' "$o" | rg -q 'ends on a question' || return 1
  fresh on; o=$(stop "$1" false 'Built it. Moving on.')
  blocks "$o" && ! printf '%s' "$o" | rg -q 'ends on a question'; }
h_mute(){ fresh on; touch "$HOME/.claude/.no-queue-stop-gate"; [ -z "$(stop "$1")" ]; }

H="$HOME/.claude/scripts/hooks/queue-stop.sh"
CHECKS="h_no_drive h_blocks h_once_per_state h_nothing_ready h_continuing h_backstop h_backstop_not_while_continuing h_question h_mute"
echo "── the hook ──"
for c in $CHECKS; do $c "$H" >/dev/null 2>&1 && ok "$c" || bad "$c"; done

mutate(){ # mutate <check> <old> <new> <label>
  local check="$1" M="$SB/.claude/scripts/hooks/queue-stop.mut.sh"
  python3 - "$H" "$M" "$2" "$3" <<'PY' || { bad "mutation $4: pattern not found"; return; }
import sys
src, dst, old, new = sys.argv[1:5]
s = open(src).read()
if old not in s: sys.exit(1)
open(dst, "w").write(s.replace(old, new, 1))
PY
  if $check "$M" >/dev/null 2>&1; then bad "mutation $4 stayed green ($check)"; else ok "mutation $4 goes red ($check)"; fi
}
echo "── each guard, broken alone ──"
# The plausible regression: the hook drives any session with a linked goal, drive or not.
mutate h_no_drive '[ -f "$drive" ] || exit 0' '[ -f "$drive" ] || { mkdir -p "$(dirname "$drive")"; jq -c "{goal: .goal_id}" "$GOALS/$sid.json" > "$drive"; }' "drive-on check"
mutate h_once_per_state 'if [ "$sig" = "$prev_sig" ]; then seen=$((seen + 1)); else seen=1; fi' 'seen=1' "one block per state"
mutate h_nothing_ready 'rows=$(bash "$QR" ready --sid "$sid" 2>/dev/null) || exit 0' 'rows="#9 phantom"' "steps aside when nothing is ready"
mutate h_backstop '[ "$seen" -ge 3 ] && ' 'false && ' "three-stop backstop"
mutate h_backstop_not_while_continuing ' && [ "$continuing" != "true" ]' '' "backstop waits for a real stop"
mutate h_question '*\?*) reason=' '*\?NEVER*) reason=' "question routed to a gate"
mutate h_mute '[ -f "$HOME/.claude/.no-queue-stop-gate" ] && exit 0' ':' "mute file"

echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]

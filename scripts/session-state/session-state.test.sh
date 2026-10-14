#!/usr/bin/env bash
# session-state.test.sh: the refusal must go red on an agent-ready goal row and
# green once it is done, parked or gated; a wrong --goal is refused; no goal at
# all is a clean finish; show/clear round-trip; finished needs a reason. Then the
# refusal is broken on a scratch copy and must go red. Sandbox HOME throughout.
set -uo pipefail
REAL="$HOME"
SB=$(mktemp -d "${TMPDIR:-/tmp}/sstate-home-XXXXXX")
mkdir -p "$SB/.claude/scripts/goals" "$SB/.claude/scripts/session-state" "$SB/repo"
cp -f "$REAL/.claude/scripts/goals/gs" "$REAL/.claude/scripts/goals/goalstore.py" "$REAL/.claude/scripts/goals/queue_run.py" "$REAL/.claude/scripts/goals/queue-run.sh" "$SB/.claude/scripts/goals/"
cp -f "$REAL/.claude/scripts/session-state/session-state.sh" "$SB/.claude/scripts/session-state/"
export HOME="$SB"
SID=sstest00-0000-4000-8000-000000000001
export CLAUDE_CODE_SESSION_ID=$SID SESSION_STATE_DIR="$SB/state"
GS="$HOME/.claude/scripts/goals/gs"; GOALS="$HOME/.claude/goals"
trap 'export HOME="$REAL"; trash "$SB" 2>/dev/null || true' EXIT
git -C "$SB/repo" init -q 2>/dev/null
cd "$SB/repo" || exit 1
pass=0; fail=0; ok(){ pass=$((pass+1)); echo "  ok    $1"; }; ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

"$GS" new "The session finishes only when its rows are done" --accept "functional: the suite passes" >/dev/null 2>&1
GID=$(ls "$GOALS/by-id" | sed 's/.json//' | head -1)
"$GS" link "$GID" >/dev/null 2>&1
"$GS" milestone "$GID" "The rows are worked" >/dev/null 2>&1
"$GS" task "$GID" m1 "ready row for the refusal" >/dev/null 2>&1

# refuses <script>: does `set finished` refuse while #1 is agent-ready?
refuses(){ bash "$1" set finished --sid $SID --reason "done" >"$SB/out" 2>&1; [ $? -eq 1 ] && rg -q "#1 ready row for the refusal" "$SB/out"; }

S="$HOME/.claude/scripts/session-state/session-state.sh"
refuses "$S" && ok "finished REFUSED while a goal row is agent-ready, naming the row" || ko "refusal: $(cat "$SB/out")"
[ -f "$SESSION_STATE_DIR/$SID.json" ] && ko "refusal still wrote a file" || ok "refusal wrote nothing"
bash "$S" set finished --sid $SID --goal nosuch --reason "typo" >/dev/null 2>&1; rc=$?
[ $rc -eq 1 ] && ok "unresolvable --goal refused (exit 1), not a free finish" || ko "typo goal (rc=$rc)"
bash "$S" set finished --sid $SID 2>/dev/null; rc=$?
[ $rc -eq 2 ] && ok "finished without --reason rejected (exit 2)" || ko "reason required (rc=$rc)"
bash "$S" set blocked --sid $SID --reason "USER: needs a ruling" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && [ "$(jq -r .state "$SESSION_STATE_DIR/$SID.json")" = blocked ] && ok "blocked writes even with a ready row" || ko "blocked (rc=$rc)"
bash "$S" set finished --sid $SID --store abcd1234 --reason "old flag" >"$SB/out" 2>&1; rc=$?
[ $rc -eq 1 ] && rg -q "retired" "$SB/out" && ok "--store is ignored with a note; the goal record still refuses" || ko "--store (rc=$rc)"
"$GS" gate "$GID" 1 "rule on it" --do "say yes" >/dev/null 2>&1
bash "$S" set finished --sid $SID --reason "only the owner's row is left" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ok "an owner-gated row does not hold finished" || ko "gated row still refused (rc=$rc)"
"$GS" ungate "$GID" 1 >/dev/null 2>&1
"$GS" close "$GID" 1 --by "true: fixture" >/dev/null 2>&1
bash "$S" set finished --sid $SID --reason "row done" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && [ "$(jq -r .state "$SESSION_STATE_DIR/$SID.json")" = finished ] && ok "finished ACCEPTED once the row is done" || ko "accept (rc=$rc)"
[ "$(jq -r .goal "$SESSION_STATE_DIR/$SID.json")" = "$GID" ] && ok "the state file names the goal it checked" || ko "goal field: $(jq -r .goal "$SESSION_STATE_DIR/$SID.json")"
[ "$(bash "$S" show $SID | jq -r .reason)" = "row done" ] && ok "show round-trips the reason" || ko "show"
bash "$S" clear $SID; bash "$S" show $SID >/dev/null 2>&1; rc=$?
[ $rc -eq 3 ] && ok "clear removes; show exits 3 (never 'finished' by absence)" || ko "clear/show (rc=$rc)"
bash "$S" set finished --sid other-sid-with-no-goal --reason "nothing was queued" >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && ok "a session with no goal finishes (no queue to refuse on)" || ko "no-goal finish (rc=$rc)"

# Mutation: the refusal broken alone must turn the first check red.
"$GS" task "$GID" m1 "ready row for the refusal" >/dev/null 2>&1   # #2, so the fixture holds a ready row again
M="$HOME/.claude/scripts/session-state/session-state.mut.sh"
python3 - "$S" "$M" <<'PY'
import sys
s = open(sys.argv[1]).read()
old = 'if [ $rc -eq 0 ] && [ -n "$rows" ]; then'
assert old in s
open(sys.argv[2], "w").write(s.replace(old, 'if false; then', 1))
PY
refuses2(){ bash "$1" set finished --sid $SID --reason "done" >/dev/null 2>&1; [ $? -eq 1 ]; }
refuses2 "$S" && ok "the real script refuses on the new ready row" || ko "real script let a ready row finish"
refuses2 "$M" && ko "mutation (refusal removed) stayed green" || ok "mutation (refusal removed) goes red"
echo "---- pass=$pass fail=$fail"; [ $fail -eq 0 ]

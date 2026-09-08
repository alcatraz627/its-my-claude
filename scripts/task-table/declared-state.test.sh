#!/usr/bin/env bash
# declared-state.test.sh — the seven ruled states survive the trip from the write
# path to the ball. task.sh accepts --state; before 2026-09-05 the renderer
# ignored metadata.state entirely, so `review` and `deferred` both drew the green
# ready ball and a row parked on purpose read as a row waiting to be picked up.
#
# Every case is mutation-proved: the assertion is run against the real renderer,
# then against a copy with the lookup removed, and a case that stays green under
# the mutation is reported as a FAILED GUARD rather than a pass.
set -uo pipefail
SRC=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
ok(){ pass=$((pass+1)); echo "  ok    $1"; }
ko(){ fail=$((fail+1)); echo "  FAIL  $1"; }

SB=$(mktemp -d); REAL="$HOME"; export HOME="$SB"
mkdir -p "$HOME/.claude/tasks" "$HOME/.claude/scripts/task-table"
cp "$SRC/task-table.sh" "$SRC/task.sh" "$SRC/resolve-store.sh" "$HOME/.claude/scripts/task-table/" 2>/dev/null
TT="$HOME/.claude/scripts/task-table/task-table.sh"
T="$HOME/.claude/scripts/task-table/task.sh"
trap 'export HOME="$REAL"; rm -rf "$SB"' EXIT

seed() {
  rm -rf "$HOME/.claude/tasks/session-decl0001"
  mkdir -p "$HOME/.claude/tasks/session-decl0001"
  $T --session decl0001 add "gate row"     --goal G --batch b --state owner-gate --lane l --tier sonnet >/dev/null 2>&1
  $T --session decl0001 add "blocked row"  --goal G --batch b --state blocked    --lane l --tier sonnet >/dev/null 2>&1
  $T --session decl0001 add "active row"   --goal G --batch b --state active     --lane l --tier sonnet >/dev/null 2>&1
  $T --session decl0001 add "review row"   --goal G --batch b --state review     --lane l --tier sonnet >/dev/null 2>&1
  $T --session decl0001 add "deferred row" --goal G --batch b --state deferred   --lane l --tier sonnet >/dev/null 2>&1
}
seed
OUT=$($TT --session decl0001 2>/dev/null)

echo "== each ruled state reaches its own ball =="
# subject -> the ball that state must draw
check() {  # check <subject> <ball> <label>
  echo "$OUT" | rg -q "$2 .* $1" && ok "$3" || ko "$3"
}
check "review row"   "🟣" "review draws its own ball, not ready"
check "deferred row" "💤" "deferred draws its own ball, not ready"
check "gate row"     "🔴" "owner-gate draws the gate ball"
check "blocked row"  "🟠" "blocked draws the waiting ball"
check "active row"   "🔵" "active draws the running ball"

echo "== a closed row ignores a stale declared state =="
# task.sh done writes status and leaves metadata.state alone, so the two diverge
# on every close. Terminal status must win or a finished row reads as blocked.
$T --session decl0001 update 2 --status completed >/dev/null 2>&1
OUT2=$($TT --session decl0001 2>/dev/null)
echo "$OUT2" | rg -q "🟠 .* blocked row" \
  && ko "a completed row still renders with its stale blocked ball" \
  || ok "terminal status beats a stale metadata.state"

echo "== a declared owner-gate is a gate to the machinery, not only to the paint (adv-tasks F4) =="
rm -rf "$HOME/.claude/tasks/session-decl0002"; mkdir -p "$HOME/.claude/tasks/session-decl0002"
$T --session decl0002 add "declared gate with no blocked_on" --goal G --batch b --state owner-gate --lane l --tier sonnet >/dev/null 2>&1
$T --session decl0002 add "plain row" --goal G --batch b --lane l --tier sonnet >/dev/null 2>&1
G2=$($TT --session decl0002 2>/dev/null)
echo "$G2" | rg -q "🔴 1 need you" && ok "the header counts the declared gate" || ko "declared gate invisible to the owed count"
$TT --session decl0002 --json > "$SB/decl2.json" 2>/dev/null
jq -e '.tasks[] | select(.id==1 or .id=="1") | .gated==true' "$SB/decl2.json" >/dev/null \
  && ok "gated is true in the JSON for a declared owner-gate" || ko "gated stays false beside state=owner-gate"

echo "== --state done completes the row on both channels =="
$T --session decl0002 add "finished row" --goal G --batch b --state done --lane l --tier sonnet >/dev/null 2>&1
jq -e '.status=="completed" and .metadata.state=="done"' "$HOME/.claude/tasks/session-decl0002/3.json" >/dev/null \
  && ok "status and state agree on done" || ko "state=done left status pending"

echo "== a bare task reference in a subject is glossed inline (adv-tasks F9) =="
rm -rf "$HOME/.claude/tasks/session-decl0003"; mkdir -p "$HOME/.claude/tasks/session-decl0003"
$T --session decl0003 add "Fix the thing" --goal G --batch b --lane l --tier sonnet >/dev/null 2>&1
$T --session decl0003 add "Follow up on #1 once it lands" --goal G --batch b --lane l --tier sonnet >/dev/null 2>&1
G3=$($TT --session decl0003 2>/dev/null)
echo "$G3" | rg -q "» .*#1 Fix the thing" && ok "the referenced row's subject appears as a gloss" || ko "bare #1 left unglossed"

echo "== mutation: remove the lookup and the guards must go red =="
MUT="$HOME/.claude/scripts/task-table/task-table.sh"
cp "$MUT" "$SB/pristine.sh"
# The mutation: make the declared-state lookup always miss, which is exactly the
# pre-fix behaviour. If a case above still passes now, it was never testing this.
python3 - "$MUT" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
before = s
s = s.replace('    declared = DECLARED_STATE.get(meta_of(x, "state") or "")',
              '    declared = None  # MUTANT')
assert s != before, "mutation anchor not found"
open(p, "w").write(s)
PY
MUTOUT=$($TT --session decl0001 2>/dev/null)
red=0
echo "$MUTOUT" | rg -q "🟣 .* review row"   || red=$((red+1))
echo "$MUTOUT" | rg -q "💤 .* deferred row" || red=$((red+1))
[ "$red" -eq 2 ] \
  && ok "both guards go red under the mutation (they test the fix, not the fixture)" \
  || ko "FAILED GUARD: $((2-red)) case(s) stayed green with the lookup removed"
cp "$SB/pristine.sh" "$MUT"

MUTOUT2=$($TT --session decl0001 2>/dev/null)
echo "$MUTOUT2" | rg -q "🟣 .* review row" && ok "restored: review is purple again" || ko "restore failed"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

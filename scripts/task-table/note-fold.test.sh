#!/usr/bin/env bash
# note-fold.test.sh — a note rides the trait row when it fits there.
#
# Owner ruling 2026-09-05: "stick the notes line (third line) in the second line
# itself if it can fit because this is making the height explode". A three-line
# row is what pushes a queue past the 44-line cap, and the trait row leaves most
# of its width empty, so a note that fits belongs there.
#
# Two things must hold together, which is why they are tested together: the note
# folds when it fits, AND it does not fold when folding would clip it to a stub.
# A test for only the first would pass on an implementation that folds
# everything and shreds long notes.
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

LONG="this note is deliberately far too long to ride the trait row, so it must drop to its own full width line and be clipped there instead"
mkdir -p "$HOME/.claude/tasks/session-fold0001"
$T --session fold0001 add "short note row" --goal G --batch b --lane hands --tier opus --class fix --domain x --note "after #12" >/dev/null 2>&1
$T --session fold0001 add "long note row"  --goal G --batch b --lane hands --tier opus --class fix --domain x --note "$LONG" >/dev/null 2>&1
OUT=$($TT --session fold0001 2>/dev/null)

echo "== a note that fits rides the trait row =="
echo "$OUT" | rg -q '◆ hands.*▫ x.*» after #12' \
  && ok "short note shares the trait line" || ko "short note did not fold"

echo "== a note that does not fit keeps its own line =="
echo "$OUT" | rg -q '◆ hands.*▫ x\s*$' \
  && ok "long note leaves the trait line clean" || ko "long note was folded and clipped"
echo "$OUT" | rg -q '» this note is deliberately' \
  && ok "long note renders on its own full-width line" || ko "long note line missing"

echo "== the render still reports a height within the cap =="
H=$(echo "$OUT" | rg -o --replace '$1' 'height ([0-9]+)/44')
[ -n "$H" ] && [ "$H" -le 44 ] && ok "height reported and within the cap ($H)" || ko "height: $H"

echo "== a traitless row with a short note is costed as it prints (f1378236, 2026-09-05) =="
# No lane, tier, kind or domain, so there is no trait row for the note to ride;
# the note takes its own line and the budget must count it. The footer's height
# figure equals the real line count or the height law is a lie.
mkdir -p "$HOME/.claude/tasks/session-fold0002"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do
  $T --session fold0002 add "traitless row $i" --note "after #1" >/dev/null 2>&1
done
OUT2=$($TT --session fold0002 2>/dev/null)
real=$(printf '%s\n' "$OUT2" | wc -l | tr -d ' ')
claimed=$(printf '%s\n' "$OUT2" | rg -o --replace '$1' 'height ([0-9]+)/44')
ok "footer height equals the real line count ($real)" "$claimed" "$real"
[ "$real" -le 44 ] && ok "and stays within the law" || ko "over the law: $real"

echo "== mutation: disable the fold and the first guard must go red =="
MUT="$HOME/.claude/scripts/task-table/task-table.sh"
cp "$MUT" "$SB/pristine.sh"
python3 "$SRC/../../scripts/task-table/_mutate-fold.py" "$MUT"
MUTOUT=$($TT --session fold0001 2>/dev/null)
echo "$MUTOUT" | rg -q '◆ hands.*▫ x.*» after #12' \
  && ko "FAILED GUARD: the short-note case passed with folding disabled" \
  || ok "the fold guard goes red under the mutation"
cp "$SB/pristine.sh" "$MUT"
RESTORED=$($TT --session fold0001 2>/dev/null)
echo "$RESTORED" | rg -q '◆ hands.*▫ x.*» after #12' \
  && ok "restored: the short note folds again" || ko "restore failed"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

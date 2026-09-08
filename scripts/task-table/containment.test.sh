#!/usr/bin/env bash
# containment.test.sh — --unfiled counts the open rows that sit under no goal or
# no milestone, and the human table stays silent about it.
#
# The silence is deliberate and is asserted here so nobody removes it by
# accident. Whether a goal-less row is malformed, and whether a milestone is
# mandatory, are owner rulings still open on decision page tasks-redesign-0904
# (D3 and D6). A footer warning would answer both by rendering, which is how a
# ruling gets made by momentum instead of by the owner. When those land, wiring
# this to the footer is one line, and case 6 below is the line that will fail
# and make somebody think about it.
#
# Run: bash ~/.claude/scripts/task-table/containment.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/contain-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
STORE="$ROOT/.claude/tasks/session-cont001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }
hasnt(){ if rg -q -- "$2" "$3" 2>/dev/null; then fail=$((fail+1)); echo "  FAIL: $1 — unexpected match for [$2]"; else pass=$((pass+1)); fi; }

mk(){ # mk <id> <status> <goal|-> <batch|->
  python3 - "$STORE/$1.json" "$1" "$2" "$3" "$4" <<'PY'
import json, sys
path, tid, status, goal, batch = sys.argv[1:6]
meta = {"class": "fix", "domain": "synth", "lane": "hands", "tier": "opus"}
if goal  != "-": meta["goal"] = goal
if batch != "-": meta["batch"] = batch
json.dump({"id": tid, "subject": f"Synthetic row {tid}", "description": "", "status": status,
           "activeForm": None, "blocks": [], "blockedBy": [], "metadata": meta}, open(path, "w"), indent=1)
PY
}
field(){ rg -o "^  $1 *: ([0-9]+)" -r '$2' "$ROOT/out" | tail -1; }
run(){ rm -f "$ROOT/out"; HOME="$ROOT" "$TT" --session cont001 --unfiled > "$ROOT/out" 2>&1; }
reset(){ rm -f "$STORE"/*.json; }

echo "── a fully filed queue reports nothing unfiled ──"
reset
for i in 1 2 3; do mk "$i" pending "Ship it" "B1"; done
run
ok "all three are filed"      "$(rg -o 'filed under a goal AND a milestone *: ([0-9]+)' -r '$1' "$ROOT/out")" "3"
ok "none missing a goal"      "$(rg -o 'no goal *: ([0-9]+)' -r '$1' "$ROOT/out")" "0"
ok "none missing a milestone" "$(rg -o 'no milestone *: ([0-9]+)' -r '$1' "$ROOT/out")" "0"

echo "── each shape is counted in the right bucket ──"
reset
mk 1 pending "Ship it" "B1"      # filed
mk 2 pending -         "B1"      # no goal
mk 3 pending "Ship it" -         # no milestone
mk 4 pending -         -         # neither
mk 5 completed -       -         # done rows never count
run
ok "one row is properly filed"   "$(rg -o 'filed under a goal AND a milestone *: ([0-9]+)' -r '$1' "$ROOT/out")" "1"
ok "two rows have no goal"       "$(rg -o 'no goal *: ([0-9]+)' -r '$1' "$ROOT/out")" "2"
ok "two rows have no milestone"  "$(rg -o 'no milestone *: ([0-9]+)' -r '$1' "$ROOT/out")" "2"
ok "one row has neither"         "$(rg -o 'neither *: ([0-9]+)' -r '$1' "$ROOT/out")" "1"
ok "the open total excludes done" "$(rg -o 'open rows: ([0-9]+)' -r '$1' "$ROOT/out")" "4"

echo "── the ids are named, so the reader can act on them ──"
has "the no-goal group names #2"      'no goal \(2\).*#2' "$ROOT/out"
has "the no-milestone group names #3" 'no milestone \(2\).*#3' "$ROOT/out"
has "the neither group names #4"      'neither \(1\): #4' "$ROOT/out"
hasnt "the filed row is never listed" '#1' "$ROOT/out"

echo "── the UNFILED band, ruled D3b ──"
# This block replaces an assertion that the human table stays SILENT about
# unfiled rows. That was correct while D3 was open and the renderer had no
# ruling to follow; answering the question by rendering would have settled it by
# momentum. D3b answered it on 2026-09-04: allow the row, render it in a loud
# band, nudge the agent to file it. So the silence is now the defect and the
# band is the contract. The assertion was changed deliberately, which is what
# the old comment here asked the next reader to do.
reset
mk 1 pending "Ship it" "B1"
mk 2 pending -         -
mk 3 pending -         -
rm -f "$ROOT/human"; HOME="$ROOT" "$TT" --session cont001 --group goal > "$ROOT/human" 2>&1
# The ruled layout draws every group as a boxed goal, so the band is now a box
# titled "unfiled" and carrying the inbox glyph and the ⚪ ball. What D3b ruled is
# unchanged and is what these still assert: the rows are kept, the band names
# itself rather than an absent field, it carries the command that empties it, and
# it sorts after every real outcome.
has "the band renders under its own name"  '^╭▏⚪ · 📥  unfiled' "$ROOT/human"
has "it counts what is in it"              'no meter can be drawn' "$ROOT/human"
# A solid bar reads as complete on every other line of the page (visual audit V8, #59).
has "its meter is an empty bar"            '▱▱▱▱▱▱▱▱▱▱  no meter' "$ROOT/human"
hasnt "and never a full one"               '██████████' "$ROOT/human"
has "and carries the command that empties it" 'task.sh update <id> --goal' "$ROOT/human"
hasnt "the old meaningless title is gone"  'GOAL \(no goal\)' "$ROOT/human"
hasnt "and so is the absent-field title"   '\(no goal\)' "$ROOT/human"

# Last, so the real outcomes are read first. The old bucket sorted alphabetically
# among them and was the largest thing on screen.
_g=$(rg -n '^╭' "$ROOT/human" | rg -v 'unfiled' | tail -1 | cut -d: -f1)
_u=$(rg -n '^╭▏⚪ · 📥  unfiled' "$ROOT/human" | head -1 | cut -d: -f1)
ok "the band sorts after every real goal" "$([ -n "$_g" ] && [ -n "$_u" ] && [ "$_u" -gt "$_g" ] && echo yes || echo no)" "yes"

# A queue with nothing unfiled must not grow an empty band.
reset
mk 1 pending "Ship it" "B1"
rm -f "$ROOT/clean"; HOME="$ROOT" "$TT" --session cont001 --group goal > "$ROOT/clean" 2>&1
hasnt "no band when nothing is unfiled" '^╭▏⚪ · 📥  unfiled' "$ROOT/clean"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

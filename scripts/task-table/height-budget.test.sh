#!/usr/bin/env bash
# height-budget.test.sh — a large GATES band must not starve the work rows.
#
# On 2026-09-04 session f04ae843 carried 16 owner-gate rows at two lines each.
# GATES renders first and had no ceiling, so the band alone exceeded the 44-line
# law and all 166 remaining rows went to the hidden list. The owner opened his
# task table and saw only work he could not act on, with none of the work.
#
# Gates keep priority. They no longer keep totality: WORK_FLOOR lines are held
# back for the bands after GATES, and gates that do not fit are named inside
# their own band rather than dropped into the global truncation line.
#
# The store is synthetic and lives in a temp dir, so this never touches a real
# queue. Run: bash ~/.claude/scripts/task-table/height-budget.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/heightbudget-XXXXXX")"
# The resolver reads $HOME/.claude/tasks, so the sandbox needs that shape, not
# a bare tasks/ directory. Getting this wrong makes every assertion read zero,
# which looks exactly like a starved table and is why the control below exists.
STORE="$ROOT/.claude/tasks/session-synth001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
atleast(){ if [ "$2" -ge "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got $2, want at least $3"; fi; }

# n gate rows (blocked_on starting USER:, each carrying a second line) plus
# m ordinary work rows under a named goal.
mk(){ # mk <id> <kind>
  local id="$1" kind="$2" blocked="" goal="Ship the thing"
  [ "$kind" = gate ] && blocked="USER: decide item $id before this can move at all"
  python3 - "$STORE/$id.json" "$id" "$blocked" "$goal" <<'PY'
import json, sys
path, tid, blocked, goal = sys.argv[1:5]
meta = {"class": "fix", "domain": "synth", "batch": "B1", "goal": goal,
        "lane": "hands", "tier": "opus"}
if blocked: meta["blocked_on"] = blocked
json.dump({"id": tid, "subject": f"Synthetic row {tid} with a subject long enough to wrap the column",
           "description": "", "status": "pending", "activeForm": None,
           "blocks": [], "blockedBy": [], "metadata": meta}, open(path, "w"), indent=1)
PY
}

for i in $(seq 1 20);  do mk "$i" gate; done
for i in $(seq 21 60); do mk "$i" work; done

OUT="$ROOT/render.txt"
HOME="$ROOT" "$TT" --session synth001 > "$OUT" 2>&1

# The ruled layout draws each goal as a box and keeps its gate rows inside it, so
# a row is a rail followed by its ball and the goal band is a box corner. The
# starvation this suite is about did not go away with the GATES band: it moved
# into the box, where twenty gates took the whole screen on the first run of the
# rebuilt renderer and all forty work rows were held.
lines=$(wc -l < "$OUT" | tr -d ' ')
# Gates render first in two places since Q1a (2026-09-05): up to three in the
# CLEAR NOW band above the boxes, then in their goal box. Both count as "first".
gaterows=$(( $(rg -c '^│\s+🔴' "$OUT" 2>/dev/null || echo 0) + $(rg -c '^   [0-9]  #' "$OUT" 2>/dev/null || echo 0) ))
workband=$(rg -c '^╭▏' "$OUT" 2>/dev/null || echo 0)
workrows=$(rg -c '^│\s+[🟢🟠🔵⚪]' "$OUT" 2>/dev/null || echo 0)
heldnote=$(rg -c 'more held here so the work below stays visible' "$OUT" 2>/dev/null || echo 0)

echo "── a 20-gate queue must still show the work ──"
atleast "the GOAL band renders at all"            "$workband" 1
atleast "at least 5 work rows render"             "$workrows" 5
# Three, not five. The ruled layout gives every row two lines plus a rail line
# between rows, and a gate here carries a note as well, so a gate costs four
# lines against the old one or two. Five gates and five work rows cannot both fit
# 44 lines under that density; the arithmetic changed, the property did not. What
# pins this guard is the mutation below, where removing the floor takes the work
# rows to zero.
atleast "gates still render first and in force"   "$gaterows" 3
ok      "the held-gates note appears in the band" "$heldnote" 1

echo
echo "── the height law still holds ──"
if [ "$lines" -le 46 ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: height $lines exceeds the 44-line law (2 lines slack allowed)"; fi

echo
echo "── control: the suite can see a starved table ──"
# Same store, but with the budget removed, which is the pre-fix behaviour.
MUT="$ROOT/task-table-nobudget.sh"
python3 - "$TT" "$MUT" <<'PY'
import sys
s = open(sys.argv[1]).read()
s = s.replace("budget = LINE_CAP - len(out) - _box_owed - WORK_FLOOR - 1",
              "budget = 10 ** 6", 1)
assert "budget = 10 ** 6" in s, "the mutation did not apply; the budget line moved"
open(sys.argv[2], "w").write(s)
PY
chmod +x "$MUT"
HOME="$ROOT" bash "$MUT" --session synth001 > "$ROOT/render-nobudget.txt" 2>&1
nb_work=$(rg -c '^│\s+[🟢🟠🔵⚪]' "$ROOT/render-nobudget.txt" 2>/dev/null || echo 0)
if [ "$nb_work" -lt "$workrows" ]; then
  pass=$((pass+1)); echo "  ok    without the budget the work rows drop to $nb_work (from $workrows)"
else
  fail=$((fail+1)); echo "  FAIL: removing the budget changed nothing ($nb_work work rows) — the test is blind"
fi

echo
echo "---- pass=$pass fail=$fail"
echo "render: $OUT"
[ "$fail" -eq 0 ]

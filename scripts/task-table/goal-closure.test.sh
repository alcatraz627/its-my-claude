#!/usr/bin/env bash
# goal-closure.test.sh — the header reports goal progress, and never calls a goal
# met while a milestone under it still holds an open row.
#
# Owner ruling 2026-09-04, verbatim: "I CARE ABOUT GOALS BEING DONE AGAINST THEIR
# MEANINGFUL BEHAVIORIAL INDENDED CHANGE; be it 3 tasks or 30 tasks". A header
# that answers with a finished-task count answers a question nobody asked, and a
# header that rounds a nearly-done goal up to met is the failure the milestone
# ruling exists to prevent: "one large milestone quietly holding three stages,
# reported met on the strength of one" (REDESIGN.md).
#
# The rounding case is the one that matters, so it is tested at the hardest
# boundary: a goal with 9 of 10 rows done, all the remaining work inside one
# milestone. Nine tenths done must still read as not met.
#
# Run: bash ~/.claude/scripts/task-table/goal-closure.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/goalclose-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
STORE="$ROOT/.claude/tasks/session-goal001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
hasnt(){ if rg -q -- "$2" "$3" 2>/dev/null; then fail=$((fail+1)); echo "  FAIL: $1 — unexpected match for [$2]"; else pass=$((pass+1)); fi; }

mk(){ # mk <id> <status> <goal> <milestone>
  python3 - "$STORE/$1.json" "$1" "$2" "$3" "$4" <<'PY'
import json, sys
path, tid, status, goal, ms = sys.argv[1:6]
meta = {"class": "fix", "domain": "synth", "lane": "hands", "tier": "opus", "goal": goal, "batch": ms}
json.dump({"id": tid, "subject": f"Synthetic row {tid}", "description": "", "status": status,
           "activeForm": None, "blocks": [], "blockedBy": [], "metadata": meta}, open(path, "w"), indent=1)
PY
}
head1(){ rm -f "$ROOT/out"; HOME="$ROOT" "$TT" --session goal001 > "$ROOT/out" 2>&1; sed -n 1p "$ROOT/out"; }
# The ruled header reads "🟢 N goals, M met  ·  🏁 X of Y". Same two facts in the
# owner's own phrasing; this normalises them back so the expectations below stay
# readable as the arithmetic they are testing.
prog(){
  head1 | python3 -c '
import sys, re
h = sys.stdin.read()
g = re.search(r"(\d+) goal tags?, (\d+) met", h)
m = re.search(r"\U0001F3C1 (\d+) of (\d+)", h)
if not (g and m): sys.exit(0)
n = int(g.group(1))
print(g.group(2) + "/" + str(n) + " goal" + ("s" if n != 1 else "")
      + " met, " + m.group(1) + "/" + m.group(2) + " milestones closed")
'
}
reset(){ rm -f "$STORE"/*.json; }

echo "── a goal with everything done reads met ──"
reset
mk 1 completed "Ship it" "M1"
mk 2 completed "Ship it" "M2"
ok "both milestones closed, goal met" "$(prog)" "1/1 goal met, 2/2 milestones closed"

echo "── one open row in one milestone, and the goal is not met ──"
reset
mk 1 completed "Ship it" "M1"
mk 2 pending   "Ship it" "M2"
ok "the open milestone holds the goal open" "$(prog)" "0/1 goal met, 1/2 milestones closed"

echo "── nine tenths done is still not met (the rounding-up case) ──"
# The open row sits INSIDE a milestone that is otherwise done, so `any` and
# `all` disagree about M1. The earlier fixture put it alone in M2, where they
# agreed, and the containment mutation stayed green on the file's own headline
# case (adv-tasks F11, 2026-09-05). M2 is closed so the milestone count is real.
reset
for i in $(seq 1 8); do mk "$i" completed "Ship it" "M1"; done
mk 9 completed "Ship it" "M2"
mk 10 pending "Ship it" "M1"
ok "90 percent done does not round up" "$(prog)" "0/1 goal met, 1/2 milestones closed"
hasnt "and the header never says the goal is met" '1/1 goal met' "$ROOT/out"

echo "── a milestone is closed only when EVERY row under it is done ──"
reset
mk 1 completed   "Ship it" "M1"
mk 2 in_progress "Ship it" "M1"
mk 3 completed   "Ship it" "M2"
ok "a running row keeps its milestone open" "$(prog)" "0/1 goal met, 1/2 milestones closed"

echo "── two goals are counted apart, one met and one not ──"
reset
mk 1 completed "Done goal" "M1"
mk 2 completed "Done goal" "M2"
mk 3 pending   "Open goal" "M3"
ok "only the finished goal counts as met" "$(prog)" "1/2 goals met, 2/3 milestones closed"

echo "── a store with no goals says nothing about goals ──"
reset
python3 - "$STORE/1.json" <<'PY'
import json, sys
json.dump({"id": "1", "subject": "No goal here", "description": "", "status": "pending",
           "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"class": "fix", "lane": "hands", "tier": "opus"}}, open(sys.argv[1], "w"), indent=1)
PY
head1 > /dev/null
hasnt "no goal progress is claimed" 'goals? met' "$ROOT/out"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

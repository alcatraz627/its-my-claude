#!/usr/bin/env bash
# lane-invariant.test.sh — a lane holds at most one running row, and saying so
# must not cost a row of the 44-line budget.
#
# REDESIGN.md:91 makes this the anti-bloat mechanism of the whole model. The
# migration plan's residual default would have promoted 159 rows to running and
# broken it on all four lanes at once, and nothing in the renderer would have
# said a word. Measured the day this was written, it was already broken in 10
# real stores on this machine, brains=3 in the largest.
#
# The second half matters as much as the first. A warning printed at the footer
# is a line the row budget did not reserve, so the first version of this check
# pushed a real store from 44 to 45 and silently broke the height ruling while
# enforcing a different one. The budget subtracts the warning lines.
#
# Run: bash ~/.claude/scripts/task-table/lane-invariant.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/laneinv-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
STORE="$ROOT/.claude/tasks/session-lane001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }
hasnt(){ if rg -q -- "$2" "$3" 2>/dev/null; then fail=$((fail+1)); echo "  FAIL: $1 — unexpected match for [$2]"; else pass=$((pass+1)); fi; }

mk(){ # mk <id> <status> <lane>
  python3 - "$STORE/$1.json" "$1" "$2" "$3" <<'PY'
import json, sys
path, tid, status, lane = sys.argv[1:5]
meta = {"class": "fix", "domain": "synth", "goal": "Ship the thing", "batch": "B1", "tier": "opus"}
if lane != "-": meta["lane"] = lane
json.dump({"id": tid, "subject": f"Synthetic row {tid}", "description": "", "status": status,
           "activeForm": None, "blocks": [], "blockedBy": [], "metadata": meta}, open(path, "w"), indent=1)
PY
}

render(){ rm -f "$ROOT/out"; HOME="$ROOT" "$TT" --session lane001 > "$ROOT/out" 2>&1; }
reset(){ rm -f "$STORE"/*.json; }

echo "── one running row per lane is fine ──"
reset
mk 1 in_progress hands
mk 2 in_progress brains
for i in $(seq 3 12); do mk "$i" pending hands; done
render
hasnt "a legal queue says nothing" 'one lane, several running' "$ROOT/out"

echo "── two running rows in one lane is named, with the ids ──"
reset
mk 1 in_progress hands
mk 2 in_progress hands
mk 3 in_progress brains
for i in $(seq 4 12); do mk "$i" pending hands; done
render
has "the violation is named"      'one lane, several running' "$ROOT/out"
has "it names the lane and count" 'hands has 2' "$ROOT/out"
has "it names both row ids"       '#1, #2' "$ROOT/out"
hasnt "the legal lane is not named" 'brains has' "$ROOT/out"

echo "── running rows with no lane get their own line, not a false lane ──"
reset
mk 1 in_progress -
mk 2 in_progress -
for i in $(seq 3 12); do mk "$i" pending hands; done
render
has "the no-lane case is named separately" 'running rows carry no lane' "$ROOT/out"
hasnt "it is not reported as a lane" 'one lane, several running' "$ROOT/out"

echo "── a single running row with no lane is not a violation ──"
reset
mk 1 in_progress -
for i in $(seq 2 12); do mk "$i" pending hands; done
render
hasnt "one unlaned running row is quiet" 'carry no lane' "$ROOT/out"

echo "── the warning must not cost a line of the height ruling ──"
# This one runs on the REAL corpus, deliberately. A synthetic fixture cannot
# reach the boundary: the overshoot needs the compact-mode path, whose
# "(compact rows: …)" line is inserted after the budget is computed, and no
# fixture built for this suite triggered it at 40, 90 or 160 rows. Removing the
# budget reservation left every synthetic case green while a real store went to
# 45, which is the failure this whole suite exists to catch, one level up.
real=0; over=""
for d in "$HOME"/.claude/tasks/session-*/; do
  [ -d "$d" ] || continue
  n=$(find "$d" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')
  [ "$n" -ge 60 ] || continue
  sid=$(basename "$d"); sid=${sid#session-}
  h=$("$TT" --session "$sid" 2>/dev/null | rg -o 'height ([0-9]+)/44' -r '$1' | tail -1)
  [ -n "$h" ] || continue
  real=$((real+1))
  [ "$h" -le 44 ] || over="$over $sid($h)"
done
if [ "$real" -eq 0 ]; then
  echo "  SKIP: no real store with 60+ rows, the height boundary cannot be reached"
else
  echo "  ($real real stores rendered)"
  ok "every real store stays inside the 44-line ruling" "${over:-none}" "none"
fi

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

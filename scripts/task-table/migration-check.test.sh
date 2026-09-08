#!/usr/bin/env bash
# migration-check.test.sh — the migration guard must fail on a real store, and
# it must still pass on a change the migration declared.
#
# The plan this exists for asserted row count, id set, and completed count after
# its migration. All three passed while 156 rows changed status and the owner's
# rendered open count fell from 178 to 22. Three suites were named as the
# verification and none of them reads a store: two build a synthetic one under
# mktemp, and the third greps the renderer as text and evals a regex against
# string literals. So no data migration could ever turn them red.
#
# This suite copies a REAL store into a sandbox and mutation-proves the guard:
# an unchanged copy passes, a mass status rewrite fails, a single-row rewrite
# fails, and a declared new field passes. The real store is only ever read.
#
# Run: bash ~/.claude/scripts/task-table/migration-check.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CHECK="$HERE/migration-check.py"
REAL_TASKS="${TASKS_DIR:-$HOME/.claude/tasks}"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }
has(){ if rg -q -- "$2" "$3" 2>/dev/null; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — no match for [$2]"; fi; }

# Pick the busiest real store. A migration guard proven on three synthetic rows
# is the very failure this suite exists to catch, so an absent store SKIPS
# loudly rather than passing on a toy.
SRC=""; best=0
if [ -d "$REAL_TASKS" ]; then
  for d in "$REAL_TASKS"/session-*; do
    [ -d "$d" ] || continue
    n=$(find "$d" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ')
    if [ "$n" -gt "$best" ]; then best="$n"; SRC="$d"; fi
  done
fi
if [ -z "$SRC" ] || [ "$best" -lt 50 ]; then
  echo "SKIP: no real store with 50+ rows under $REAL_TASKS (largest: ${best:-0})"
  echo "      this suite is meaningless on synthetic data, so it declines to run"
  exit 0
fi
SID="$(basename "$SRC")"; SID="${SID#session-}"
echo "── source store: $SID ($best rows, read-only) ──"

ROOT="$(mktemp -d "${TMPDIR:-/tmp}/migcheck-XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT
B="$ROOT/before"; A="$ROOT/after"
mkdir -p "$B/.claude/tasks" "$A/.claude/tasks"
cp -Rf "$SRC" "$B/.claude/tasks/session-$SID"
cp -Rf "$SRC" "$A/.claude/tasks/session-$SID"
BS="$B/.claude/tasks/session-$SID"; AS="$A/.claude/tasks/session-$SID"

run(){ # run <extra flags…> ; writes $ROOT/out, returns the exit code
  python3 "$CHECK" "$BS" "$AS" \
    --before-home "$B" --after-home "$A" --session "$SID" "$@" > "$ROOT/out" 2>&1
}

# 1. Control. An untouched copy must pass, or every later red is meaningless.
run; rc=$?
ok "an unchanged copy passes" "$rc" "0"
has "the control says so out loud" "PASS: every difference" "$ROOT/out"

# 2. The demonstrated failure: the residual mapping sends every unmatched
#    pending row to active. This is what the replaced check could not see.
python3 - "$AS" <<'PY'
import json, os, sys
d = sys.argv[1]; n = 0
for name in sorted(os.listdir(d)):
    if not name.endswith(".json"): continue
    p = os.path.join(d, name)
    with open(p) as fh:
        try: o = json.load(fh)
        except json.JSONDecodeError: continue
    if not isinstance(o, dict) or "id" not in o: continue
    if o.get("status") != "pending": continue
    if (o.get("metadata") or {}).get("blocked_on"): continue
    o["status"] = "in_progress"
    with open(p, "w") as fh: json.dump(o, fh, indent=1)
    n += 1
print(f"  (mutated {n} rows)")
PY
run; rc=$?
ok "a mass status rewrite fails" "$rc" "1"
has "it names the field that moved"   'field status changed on' "$ROOT/out"
has "it names the digest collapse"    'rendered open count moved' "$ROOT/out"

# 3. Sensitivity. A guard that only fires on 165 rows would miss the one-row
#    corruption, which is the shape nobody notices for weeks.
rm -rf "$AS"; cp -Rf "$SRC" "$AS"
python3 - "$AS" <<'PY'
import json, os, sys
d = sys.argv[1]
for name in sorted(os.listdir(d)):
    if not name.endswith(".json"): continue
    p = os.path.join(d, name)
    with open(p) as fh:
        try: o = json.load(fh)
        except json.JSONDecodeError: continue
    if isinstance(o, dict) and o.get("status") == "pending":
        o["status"] = "completed"
        with open(p, "w") as fh: json.dump(o, fh, indent=1)
        print(f"  (mutated exactly 1 row: #{o['id']})")
        break
PY
run; rc=$?
ok "a single-row rewrite fails too" "$rc" "1"
has "and names that one row" 'field status changed on 1 row' "$ROOT/out"

# 4. The opposite proof. A guard that fails on everything is as useless as one
#    that passes on everything, so a declared addition must still pass.
rm -rf "$AS"; cp -Rf "$SRC" "$AS"
python3 - "$AS" <<'PY'
import json, os, sys
d = sys.argv[1]; n = 0
for name in sorted(os.listdir(d)):
    if not name.endswith(".json"): continue
    p = os.path.join(d, name)
    with open(p) as fh:
        try: o = json.load(fh)
        except json.JSONDecodeError: continue
    if not isinstance(o, dict) or "id" not in o: continue
    o.setdefault("metadata", {})["state"] = "unassigned"
    with open(p, "w") as fh: json.dump(o, fh, indent=1)
    n += 1
print(f"  (added metadata.state to {n} rows)")
PY
run --allow metadata.state; rc=$?
ok "a declared new field passes" "$rc" "0"
run; rc=$?
ok "the same field undeclared fails" "$rc" "1"
has "and says it was not declared" 'not in --allow' "$ROOT/out"

echo "---- pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

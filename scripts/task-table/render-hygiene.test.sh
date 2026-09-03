#!/usr/bin/env bash
# render-hygiene.test.sh — the three ways the table wasted the reader's attention.
#
# All three shipped together on 2026-09-04 after the owner called the output
# "FUCKING DIFFICULT AND CRYPTIC TO READ VISUALLY". None is a crash; each is a
# line of screen that carries nothing, which is why none had a test.
#
#   1. A priority printed twice ("P2 P2 Vocabulary terms"), because 16 rows carry
#      it in the subject text AND in metadata.priority.
#   2. A tag printed twice ("ui · ui · forge"), because a row carries class=ui
#      beside a pre-joined domain="ui · forge".
#   3. A continuation line cut mid-token ("Was mis", "What remains is an acc"),
#      because the compact path hard-sliced instead of trimming at a word.
#
# Synthetic store in a temp HOME; the real queue is never touched.
# Run: bash ~/.claude/scripts/task-table/render-hygiene.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TT="$HERE/task-table.sh"
ROOT="$(mktemp -d "${TMPDIR:-/tmp}/renderhyg-XXXXXX")"
STORE="$ROOT/.claude/tasks/session-hygie001"
mkdir -p "$STORE"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1"; echo "        got  [$2]"; echo "        want [$3]"; fi; }

mkrow(){ # mkrow <id> <priority> <subject> <class> <domain> <blocked_on>
  python3 - "$STORE/$1.json" "$1" "$2" "$3" "$4" "$5" "$6" <<'PY'
import json, sys
p, tid, prio, subj, cls, dom, blocked = sys.argv[1:8]
meta = {"lane": "hands", "tier": "opus", "goal": "G", "batch": "B"}
if prio: meta["priority"] = prio
if cls: meta["class"] = cls
if dom: meta["domain"] = dom
if blocked: meta["blocked_on"] = blocked
json.dump({"id": tid, "subject": subj, "description": "", "status": "pending",
           "activeForm": None, "blocks": [], "blockedBy": [], "metadata": meta},
          open(p, "w"), indent=1)
PY
}

LONG="USER: a reason long enough that the compact continuation line must be trimmed before it reaches the end of this sentence about nothing"

mkrow 1 P2 "P2 Vocabulary terms render a chip wall"      ui  "ui · forge" ""
mkrow 2 P3 "P2 The Next button is not disabled"          ui  forge        ""
mkrow 3 P1 "Dev guard ceiling is too low"                ops forge        ""
mkrow 4 ""  "No priority anywhere on this row"           fix synth        ""
mkrow 5 P1 "P1 Row whose blocked text must be trimmed"   fix synth        "$LONG"

# ellip() runs on the COMPACT path only, which the renderer selects when the full
# view will not fit 44 lines. Five rows fit, so without this filler the suite
# asserts a trim that never had a reason to happen and reads the wrapped line
# instead. Caught by the check below failing on its first run.
# Vary class and domain across the filler. The renderer suppresses a metadata key
# whose value is the same on more than 80% of the rows that carry it, because a
# column that never changes carries no information. Uniform filler therefore
# silences the very tags case 3 is about, which is a property of the test data
# and not a defect. Caught by case 3 failing on the run that added the filler.
CLASSES=(fix ui ops build docs verify); DOMAINS=(synth forge foundry kit walmart hooks)
for i in $(seq 6 50); do
  mkrow "$i" "" "Filler row $i to push the table onto its compact path" \
        "${CLASSES[$((i % 6))]}" "${DOMAINS[$(((i + 3) % 6))]}" ""
done

OUT="$ROOT/render.txt"
HOME="$ROOT" bash "$TT" --session hygie001 > "$OUT" 2>&1

echo "── 1. a priority is printed once ──"
ok "matching prefix stripped"     "$(rg -c 'P2 P2' "$OUT" 2>/dev/null || echo 0)" 0
ok "row 1 keeps one P2"           "$(rg -c '#1 +P2 Vocabulary' "$OUT" 2>/dev/null || echo 0)" 1
ok "row 3 unaffected"             "$(rg -c '#3 +P1 Dev guard' "$OUT" 2>/dev/null || echo 0)" 1
ok "row 4 needs no priority"      "$(rg -c '#4 +No priority' "$OUT" 2>/dev/null || echo 0)" 1

echo
echo "── 2. a CONFLICT is labelled, not silently dropped ──"
# Row 2 says P3 in metadata and P2 in its subject. That disagreement is about how
# urgent the work is, so it must survive, legibly.
ok "conflict is shown"            "$(rg -c '#2 +P3 \(subject says P2\)' "$OUT" 2>/dev/null || echo 0)" 1

echo
echo "── 3. a tag is printed once ──"
ok "pre-joined domain split"      "$(rg -c 'ui · ui' "$OUT" 2>/dev/null || echo 0)" 0
ok "row 1 keeps ui and forge"     "$(rg -c '#1 .*ui · forge' "$OUT" 2>/dev/null || echo 0)" 1

echo
echo "── 4. a trimmed line ends at a word, not mid-token ──"
trimmed=$(rg -o '↳ blocked:.*' "$OUT" 2>/dev/null | head -1)
if printf '%s' "$trimmed" | rg -q '…$' 2>/dev/null; then
  pass=$((pass+1))
  last=$(printf '%s' "$trimmed" | sed 's/…$//' | awk '{print $NF}')
  ok "the trim lands on a whole word" "$(printf '%s' "$LONG" | rg -c -- "$last" 2>/dev/null || echo 0)" 1
else
  fail=$((fail+1)); echo "  FAIL: the long blocked line was not trimmed at all"
  echo "        got [$trimmed]"
fi

echo
echo "── control: the suite can see the defects it names ──"
MUT="$ROOT/mut.sh"
python3 - "$TT" "$MUT" <<'PY'
import sys
s = open(sys.argv[1]).read()
s = s.replace("task = prio(x) + (f\"[{sn}] \" if sn else \"\") + subject_of(x)",
              "task = prio(x) + (f\"[{sn}] \" if sn else \"\") + x[\"subject\"]", 1)
open(sys.argv[2], "w").write(s)
PY
HOME="$ROOT" bash "$MUT" --session hygie001 > "$ROOT/mut.txt" 2>&1
if [ "$(rg -c 'P2 P2' "$ROOT/mut.txt" 2>/dev/null || echo 0)" -ge 1 ]; then
  pass=$((pass+1)); echo "  ok    reverting subject_of brings the doubled prefix back"
else
  fail=$((fail+1)); echo "  FAIL: reverting subject_of changed nothing — the test is blind"
fi

echo
echo "---- pass=$pass fail=$fail"
echo "render: $OUT"
[ "$fail" -eq 0 ]

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
echo "── 5. auto-grouping picks a key most rows carry ──"
# The old test was any(): one row bearing a goal made goal the grouping key for
# the whole store, and every row without one landed in a single band titled
# "GOAL (no goal)". On the owner's queue that band held 98 of 180 open rows and
# was the largest thing on screen while naming nothing.
#
# This store is built so goal is sparse (5 of 50) and domain is dense (all 50).
SPARSE="$ROOT/.claude/tasks/session-sparse01"
mkdir -p "$SPARSE"
for i in $(seq 1 50); do
  python3 - "$SPARSE/$i.json" "$i" "$(( i <= 5 ? 1 : 0 ))" "${DOMAINS[$((i % 6))]}" <<'PY'
import json, sys
p, tid, has_goal, dom = sys.argv[1:5]
meta = {"lane": "hands", "tier": "opus", "domain": dom, "class": "fix"}
if has_goal == "1": meta["goal"] = "A goal only a few rows carry"
json.dump({"id": tid, "subject": f"Row {tid}", "description": "", "status": "pending",
           "activeForm": None, "blocks": [], "blockedBy": [], "metadata": meta},
          open(p, "w"), indent=1)
PY
done
AUTO="$ROOT/auto.txt"
HOME="$ROOT" bash "$TT" --session sparse01 --group auto > "$AUTO" 2>&1
ok "sparse goal is not chosen"      "$(rg -c 'grouped: goal' "$AUTO" 2>/dev/null || echo 0)" 0
ok "dense domain is chosen"         "$(rg -c 'grouped: domain' "$AUTO" 2>/dev/null || echo 0)" 1
ok "no giant unnamed goal band"     "$(rg -c 'GOAL \(no goal\)' "$AUTO" 2>/dev/null || echo 0)" 0

echo
echo "── 6. a PINNED sparse key is honoured, but says what it costs ──"
# A flag or a project view file may still pin a sparse key. That ruling is not
# ours to override; the reader just has to be told why one band swallowed the table.
PIN="$ROOT/pin.txt"
HOME="$ROOT" bash "$TT" --session sparse01 --group goal > "$PIN" 2>&1
ok "the pinned key is obeyed"       "$(rg -c 'grouped: goal' "$PIN" 2>/dev/null || echo 0)" 1
ok "and its coverage is flagged"    "$(rg -c "only .* of open rows carry 'goal'" "$PIN" 2>/dev/null || echo 0)" 1
ok "the warning names an alternative" "$(rg -c 'regroup: task-table.sh --group' "$PIN" 2>/dev/null || echo 0)" 1

echo
echo "── 7. an untouched owner gate says its age ──"
# A gate goes false by being SATISFIED, and nothing closes the row. Twice on
# 2026-09-04 the owner's band held an ask somebody had already cleared. Wording
# cannot catch that; only recency can.
GATED="$ROOT/.claude/tasks/session-gates001"
mkdir -p "$GATED"
for i in 1 2 3; do
  python3 - "$GATED/$i.json" "$i" <<'PY'
import json, sys
p, tid = sys.argv[1:3]
json.dump({"id": tid, "subject": f"Owner ask {tid}", "description": "", "status": "pending",
           "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"lane": "hands", "tier": "opus", "domain": "d", "class": "c",
                        "blocked_on": f"USER: decide item {tid}"}}, open(p, "w"), indent=1)
PY
done
# Rows 1 and 2 are two days stale; row 3 was touched just now.
OLD_TS=$(( $(date +%s) - 2 * 24 * 3600 ))
touch -t "$(date -r $OLD_TS +%Y%m%d%H%M.%S)" "$GATED/1.json" "$GATED/2.json"
GOUT="$ROOT/gates.txt"
HOME="$ROOT" bash "$TT" --session gates001 > "$GOUT" 2>&1
ok "the stale gates are flagged"     "$(rg -c 'untouched >24h, re-check before acting' "$GOUT" 2>/dev/null || echo 0)" 1
ok "and named by id"                 "$(rg -c 're-check before acting: #1 #2' "$GOUT" 2>/dev/null || echo 0)" 1
ok "the fresh gate is not named"     "$(rg -c 'acting: #1 #2 #3' "$GOUT" 2>/dev/null || echo 0)" 0

# Control: with every gate fresh the note must not appear at all.
touch "$GATED/1.json" "$GATED/2.json"
HOME="$ROOT" bash "$TT" --session gates001 > "$ROOT/gates-fresh.txt" 2>&1
ok "silent when no gate is stale"    "$(rg -c 'untouched >24h' "$ROOT/gates-fresh.txt" 2>/dev/null || echo 0)" 0

echo
echo "── 8. an empty store points at the store that holds the rows ──"
# An empty table is indistinguishable from an empty QUEUE. A peer read exactly
# that on 2026-09-04: its twenty rows lived in the store that created them, a
# bare run showed nothing, and it concluded the queue was done.
mkdir -p "$ROOT/.claude/tasks/session-empty001"
REAL="$ROOT/.claude/tasks/session-holder01"
mkdir -p "$REAL"
for i in 1 2 3; do
  python3 - "$REAL/$i.json" "$i" <<'PY'
import json, sys
p, tid = sys.argv[1:3]
json.dump({"id": tid, "subject": f"A real row {tid} in the creating store", "description": "",
           "status": "pending", "activeForm": None, "blocks": [], "blockedBy": [],
           "metadata": {"lane": "hands", "tier": "opus", "domain": "d"}}, open(p, "w"), indent=1)
PY
done
EOUT="$ROOT/empty.txt"
HOME="$ROOT" bash "$TT" --session empty001 > "$EOUT" 2>&1
ok "the empty store says so"          "$(rg -c 'EMPTY STORE' "$EOUT" 2>/dev/null || echo 0)" 1
ok "it names a populated store"       "$(rg -c 'task-table.sh --session holder01' "$EOUT" 2>/dev/null || echo 0)" 1
ok "with its open count"              "$(rg -c 'holder01   3 open of 3' "$EOUT" 2>/dev/null || echo 0)" 1
ok "and a recognisable subject"       "$(rg -c 'A real row' "$EOUT" 2>/dev/null || echo 0)" 1

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

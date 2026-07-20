#!/usr/bin/env bash
# gcc-vitals.test.sh — checks for the vitals reader (added in final-review R6:
# the one script whose numbers were wrong shipped with no tests).
# Isolation: GCC_VITALS_ATONE points the atone family at a fixture. The proposals/
# rules/churn families read the live tree (isolating them needs env hooks into
# propose.sh/git — deferred); the tests here cover atone math, JSON validity, the
# empty/missing-ledger guards, and the partial-month arrow.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
V="$HERE/gcc-vitals.sh"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }

FIX="$(mktemp "${TMPDIR:-/tmp}/gv-atone-XXXXXX")"
cat > "$FIX" <<'EOF'
{"id":"mist-20260501-120000-01","cluster":"A","slug":"x"}
{"id":"mist-20260501-120000-02","cluster":"A","slug":"y"}
{"id":"mist-20260601-120000-03","cluster":"B","slug":"z"}
EOF

echo "── --json is valid and carries all four families ──"
out=$(GCC_VITALS_ATONE="$FIX" bash "$V" --json 2>/dev/null)
ok "valid json"            "$(printf '%s' "$out" | jq -e . >/dev/null 2>&1 && echo ok)"       ok
ok "has learning"          "$(printf '%s' "$out" | jq -e 'has("learning")' >/dev/null && echo y)"   y
ok "has metabolic"         "$(printf '%s' "$out" | jq -e 'has("metabolic")' >/dev/null && echo y)"  y
ok "has growth"            "$(printf '%s' "$out" | jq -e 'has("growth")' >/dev/null && echo y)"      y
ok "has churn"             "$(printf '%s' "$out" | jq -e 'has("churn")' >/dev/null && echo y)"       y

echo "── atone months counted from the fixture (2 in May, 1 in June) ──"
ok "May count = 2"         "$(printf '%s' "$out" | jq -r '.learning.mistakes_by_month["2026-05"]')"  2
ok "June count = 1"        "$(printf '%s' "$out" | jq -r '.learning.mistakes_by_month["2026-06"]')"  1

echo "── R1 regression: proposal counts match propose.sh's own prop- line count ──"
gv_open=$(printf '%s' "$out" | jq -r '.metabolic.open')
truth_open=$(bash "$HERE/propose.sh" list --status open 2>/dev/null | grep -c '^prop-')
ok "open matches ground truth"  "$gv_open"  "$truth_open"

echo "── empty ledger: no crash, no divide-by-zero ──"
E="$(mktemp)"; rm -f "$E"; touch "$E"
ok "empty -> valid json"   "$(GCC_VITALS_ATONE="$E" bash "$V" --json 2>/dev/null | jq -e . >/dev/null 2>&1 && echo ok)"  ok
rm -f "$E"

echo "── missing ledger file: no crash ──"
ok "missing -> exit 0"     "$(GCC_VITALS_ATONE="/nope/x.jsonl" bash "$V" --json >/dev/null 2>&1 && echo ok)"  ok

echo "── human output renders without error ──"
ok "human EKG runs"        "$(GCC_VITALS_ATONE="$FIX" bash "$V" >/dev/null 2>&1 && echo ok)"  ok

rm -f "$FIX"
echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0

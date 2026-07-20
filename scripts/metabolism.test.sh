#!/usr/bin/env bash
# metabolism.test.sh — checks for the retirement ceremony.
# Isolation: METABOLISM_LEDGER + METABOLISM_RULES_DIR redirect off the live tree.
# Run: bash ~/.claude/scripts/metabolism.test.sh   (exit 0 = pass)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
M="$HERE/metabolism.sh"

LED="$(mktemp "${TMPDIR:-/tmp}/metab-XXXXXX")"; rm -f "$LED"
RD="$(mktemp -d "${TMPDIR:-/tmp}/metab-rules-XXXXXX")"
touch "$RD/some-rule.md"
export METABOLISM_LEDGER="$LED" METABOLISM_RULES_DIR="$RD"

pass=0; fail=0
ok(){ if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "  FAIL: $1 — got [$2] want [$3]"; fi; }
last(){ tail -1 "$LED" 2>/dev/null; }

echo "── a well-formed retirement records as PROPOSED, removes nothing ──"
id=$(bash "$M" retire some-rule --disposition superseded-by-hook \
       --reason "safe-delete.sh enforces this unconditionally now" \
       --evidence "superseded-by safe-delete.sh" --into safe-delete 2>/dev/null)
ok "prints a ret- id"            "$(printf '%s' "$id" | grep -c '^ret-')"      1
ok "status is proposed"          "$(last | jq -r .status)"                     proposed
ok "pathway is retire"           "$(last | jq -r .pathway)"                    retire
ok "records the rule"            "$(last | jq -r .rule)"                       some-rule
ok "records the evidence"        "$(last | jq -r .evidence)"                   "superseded-by safe-delete.sh"
ok "has a restorable_from sha"   "$(last | jq -e 'has("restorable_from")' >/dev/null && echo y)"  y
ok "the rule FILE still exists (nothing deleted)" "$([ -f "$RD/some-rule.md" ] && echo y)"        y

echo "── evidence and reason are MANDATORY (the whole point of the ceremony) ──"
bash "$M" retire r --disposition absorbed --reason "x" >/dev/null 2>&1
ok "missing --evidence -> exit 2"   "$?"  2
bash "$M" retire r --disposition absorbed --evidence "x" >/dev/null 2>&1
ok "missing --reason -> exit 2"     "$?"  2
bash "$M" retire r --reason x --evidence y >/dev/null 2>&1
ok "missing --disposition -> exit 2" "$?" 2

echo "── an invalid disposition is rejected (no free-text dispositions) ──"
bash "$M" retire r --disposition whatever --reason x --evidence y >/dev/null 2>&1
ok "bad disposition -> exit 2"      "$?"  2

echo "── dangling flag fails clean, never crashes on unbound \$2 ──"
bash "$M" retire r --reason >/dev/null 2>&1
ok "dangling --reason -> exit 2"    "$?"  2
err=$(bash "$M" retire r --reason 2>&1 >/dev/null)
ok "no 'unbound variable' leak"     "$(printf '%s' "$err" | grep -c 'unbound variable')"  0

echo "── missing slug rejected ──"
bash "$M" retire >/dev/null 2>&1; ok "no slug -> exit 2"  "$?"  2

echo "── list shows the proposed retirement ──"
ok "list finds it"  "$(bash "$M" list --status proposed 2>/dev/null | grep -c some-rule)"  1

echo "── malformed ledger line is skipped by list, not fatal ──"
printf 'not json\n' >> "$LED"
ok "list survives a garbage line"  "$(bash "$M" list 2>/dev/null | grep -c some-rule)"  1

rm -rf "$LED" "$RD"
echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
exit 0

#!/usr/bin/env bash
# Tests for policy.sh: the owner's thresholds, freshness, and the exit contract.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; P="$HERE/policy.sh"
T=$(mktemp -d); pass=0; fail=0
ok()  { pass=$((pass+1)); echo "  ok    $1"; }
bad() { fail=$((fail+1)); echo "  FAIL  $1"; }
lim() { printf '{"5h":{"pct":10},"week":{"pct":%s},"resets_at_weekly":"%s"}' "$1" "$(( $(date +%s) + 200000 ))" > "$T/limits.json"; }
cdx() { printf '{"rateLimits":{"secondary":{"usedPercent":%s,"resetsAt":%s}}}' "$1" "$(( $(date +%s) + 90000 ))" > "$T/codex.json"; }
run() { POLICY_LIMITS="$T/limits.json" POLICY_CODEX="$T/codex.json" bash "$P" "$@"; }

echo "== fable =="
lim 50; out=$(run fable); rc=$?; [ "$rc" -eq 0 ] && [[ "$out" == OK* ]] && ok "50%: OK, exit 0" || bad "50%: $out ($rc)"
lim 85; out=$(run fable); rc=$?; [ "$rc" -eq 1 ] && [[ "$out" == WARN* ]] && ok "85%: WARN, exit 1" || bad "85%: $out ($rc)"
printf '%s' "$out" | rg -q 'Model Plan' && ok "WARN asks what fable buys" || bad "WARN text: $out"
lim 95; out=$(run fable); rc=$?; [ "$rc" -eq 2 ] && [[ "$out" == STRONG* ]] && ok "95%: STRONG, exit 2" || bad "95%: $out ($rc)"
printf '%s' "$out" | rg -q 'ask the owner' && ok "STRONG nudges to ask the owner" || bad "STRONG text: $out"
lim 80; out=$(run fable); [[ "$out" == OK* ]] && ok "exactly 80 is OK (threshold is above)" || bad "80: $out"

echo "== general =="
lim 92; out=$(run general); rc=$?; [ "$rc" -eq 2 ] && printf '%s' "$out" | rg -q 'per session' && ok "92%: STRONG, names per-session snooze" || bad "general 92: $out"
lim 82; out=$(run general); rc=$?; [ "$rc" -eq 1 ] && ok "82%: WARN" || bad "general 82: $out ($rc)"

echo "== codex =="
cdx 30; out=$(run codex); rc=$?; [ "$rc" -eq 0 ] && ok "30%: OK" || bad "codex 30: $out"
cdx 85; out=$(run codex); rc=$?; [ "$rc" -eq 1 ] && printf '%s' "$out" | rg -q 'worth' && ok "85%: WARN, asks about value" || bad "codex 85: $out ($rc)"

echo "== freshness and shape =="
touch -t 202601010000 "$T/limits.json"; out=$(run fable); rc=$?; [[ "$out" == UNKNOWN* ]] && [ "$rc" -eq 0 ] && ok "stale limits: UNKNOWN, exit 0" || bad "stale: $out ($rc)"
lim 95; out=$(run fable --json); printf '%s' "$out" | jq -e '.tier=="STRONG" and .lane=="fable"' >/dev/null && ok "--json carries lane and tier" || bad "json: $out"
out=$(run nope 2>&1); rc=$?; [ "$rc" -eq 64 ] && ok "unknown lane refuses" || bad "unknown lane rc $rc"

echo "== MUTATION: without the 90 branch, 95 reads WARN =="
sed 's/-gt 90/-gt 990/' "$P" > "$T/mut.sh"; lim 95
out=$(POLICY_LIMITS="$T/limits.json" bash "$T/mut.sh" fable); [[ "$out" == WARN* ]] && ok "mutant drops to WARN, so the STRONG branch is load-bearing" || bad "mutant: $out"
echo "---- pass=$pass fail=$fail"; [ "$fail" -eq 0 ]

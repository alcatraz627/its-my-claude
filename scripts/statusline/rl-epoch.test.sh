#!/usr/bin/env bash
# _rl_to_epoch: an unknown reset time must not masquerade as the freshest one.
#
# Claude Code sends resets_at=9999999999 when it doesn't know when the window
# resets. The rate-limit freshness merge picks whichever source has the LATER
# resets_at, so a sentinel taken literally (year 2286) wins every merge forever
# and pins a stale local value over a fresher cached one. Unknown must read as 0.
#
# Extracts the function from statusline.sh and exercises it directly — the script
# itself expects a full Claude Code stdin payload and can't be run bare.

set -uo pipefail
SL="${1:-$HOME/.claude/scripts/statusline/statusline.sh}"

# pull just the function under test
eval "$(sed -n '/^_rl_to_epoch() {/,/^}/p' "$SL")"
type _rl_to_epoch >/dev/null 2>&1 || { echo "could not extract _rl_to_epoch from $SL"; exit 1; }

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }
check() { # label, input, expected
  local got; got=$(_rl_to_epoch "$2")
  [ "$got" = "$3" ] && ok "$1 (-> $got)" || bad "$1: got '$got', want '$3'"
}

NOW=$(date +%s)

echo "== the sentinel must read as unknown =="
check "9999999999 (Claude Code's 'I don't know')" "9999999999" "0"

echo
echo "== real values must survive untouched =="
check "a real epoch 1h out" "$((NOW + 3600))" "$((NOW + 3600))"
check "a real epoch in the past" "$((NOW - 3600))" "$((NOW - 3600))"
check "the live weekly reset from .limits.json" "1784566800" "1784566800"

echo
echo "== unknown / malformed =="
check "empty" "" "0"
check "null" "null" "0"
check "garbage" "not-a-time" "0"

echo
echo "== the boundary (14 days) =="
check "13 days out — plausible, keep" "$((NOW + 13*86400))" "$((NOW + 13*86400))"
check "15 days out — implausible, unknown" "$((NOW + 15*86400))" "0"

echo
echo "== the merge consequence: sentinel must NOT beat a real timestamp =="
real=$(_rl_to_epoch "$((NOW + 3600))")
sent=$(_rl_to_epoch "9999999999")
if (( sent > real )); then
  bad "sentinel still wins the freshness merge (sent=$sent > real=$real)"
else
  ok "a real timestamp beats the sentinel (real=$real > sent=$sent)"
fi

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

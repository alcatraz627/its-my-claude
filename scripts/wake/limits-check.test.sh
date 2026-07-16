#!/usr/bin/env bash
# limits-check.test.sh — is it worth waking into the current 5h window?
#
# The wake monitor must not burn the user's last quota on self-checks. It cannot
# schedule against the window's reset, because Claude Code sends
# resets_at=9999999999 when it doesn't know one — the sentinel IS the message.
# So the only honest signal is how full the window already is, and this is the
# thing that reads it.
#
# Every case here is a state the real file has actually been in, plus the two
# that would silently break it: a sentinel where a timestamp belongs, and a file
# that isn't there at all.
#
#   bash ~/.claude/scripts/wake/limits-check.test.sh

set -uo pipefail
CHECK="${CHECK_UNDER_TEST:-$(dirname "$0")/limits-check.sh}"

PASS=0; FAIL=0
ok()  { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

# Run the check against a synthetic limits file. Echoes "<verdict> <exit>".
run() { # $1 = json body ("" = no file at all)
  local T; T=$(mktemp -d); local f="$T/.limits.json"
  [ -n "$1" ] && printf '%s' "$1" > "$f"
  local out rc
  out=$(WAKE_LIMITS_FILE="$f" bash "$CHECK" 2>/dev/null); rc=$?
  rm -rf "$T"
  printf '%s %s' "$(printf '%s' "$out" | head -1 | cut -f1)" "$rc"
}

echo "== an open window is worth waking into =="
r=$(run '{"5h":{"pct":43},"week":{"pct":80},"resets_at":"9999999999"}')
[ "${r%% *}" = "OPEN" ] && ok "43% -> OPEN ($r)" || bad "43% gave '$r', want OPEN"
r=$(run '{"5h":{"pct":0},"week":{"pct":0},"resets_at":"9999999999"}')
[ "${r%% *}" = "OPEN" ] && ok "0% -> OPEN" || bad "0% gave '$r', want OPEN"

echo
echo "== a nearly-spent window is not =="
r=$(run '{"5h":{"pct":97},"week":{"pct":80},"resets_at":"9999999999"}')
[ "${r%% *}" = "NEAR-FULL" ] && ok "97% -> NEAR-FULL ($r)" || bad "97% gave '$r', want NEAR-FULL"
r=$(run '{"5h":{"pct":100},"week":{"pct":80},"resets_at":"9999999999"}')
[ "${r%% *}" = "NEAR-FULL" ] && ok "100% -> NEAR-FULL" || bad "100% gave '$r', want NEAR-FULL"

echo
echo "== the boundary is the boundary =="
r=$(run '{"5h":{"pct":89},"week":{"pct":0},"resets_at":"9999999999"}')
[ "${r%% *}" = "OPEN" ] && ok "89% -> OPEN (just under the default 90)" || bad "89% gave '$r'"
r=$(run '{"5h":{"pct":90},"week":{"pct":0},"resets_at":"9999999999"}')
[ "${r%% *}" = "NEAR-FULL" ] && ok "90% -> NEAR-FULL (at the default threshold)" || bad "90% gave '$r'"

echo
echo "== unknown must read as unknown, never as open =="
# A wake that treats missing data as "plenty of room" is the plausible-looking
# default this account keeps getting bitten by. It must say so instead.
r=$(run '')
[ "${r%% *}" = "UNKNOWN" ] && ok "no limits file -> UNKNOWN ($r)" || bad "missing file gave '$r', want UNKNOWN"
r=$(run '{"week":{"pct":80},"resets_at":"9999999999"}')
[ "${r%% *}" = "UNKNOWN" ] && ok "no 5h key -> UNKNOWN" || bad "absent 5h gave '$r', want UNKNOWN"
r=$(run 'not json at all')
[ "${r%% *}" = "UNKNOWN" ] && ok "malformed json -> UNKNOWN" || bad "malformed gave '$r', want UNKNOWN"
r=$(run '{"5h":{"pct":null},"resets_at":"9999999999"}')
[ "${r%% *}" = "UNKNOWN" ] && ok "null pct -> UNKNOWN" || bad "null pct gave '$r', want UNKNOWN"

echo
echo "== numbers the writer might plausibly emit =="
# bash -ge cannot compare "43.5" — it aborts. A float must floor, not blind the check.
r=$(run '{"5h":{"pct":43.5},"resets_at":"9999999999"}')
[ "${r%% *}" = "OPEN" ] && ok "float 43.5 -> OPEN (floored, not UNKNOWN)" || bad "float gave '$r', want OPEN"
r=$(run '{"5h":{"pct":97.9},"resets_at":"9999999999"}')
[ "${r%% *}" = "NEAR-FULL" ] && ok "float 97.9 -> NEAR-FULL" || bad "float gave '$r', want NEAR-FULL"
r=$(run '{"5h":{"pct":"43"},"resets_at":"9999999999"}')
[ "${r%% *}" = "OPEN" ] && ok "quoted \"43\" -> OPEN" || bad "quoted number gave '$r', want OPEN"
r=$(run '{"5h":{"pct":-5},"resets_at":"9999999999"}')
[ "${r%% *}" = "UNKNOWN" ] && ok "negative -5 -> UNKNOWN (broken writer, not headroom)" || bad "negative gave '$r', want UNKNOWN"
r=$(run '{"5h":{"pct":150},"resets_at":"9999999999"}')
[ "${r%% *}" = "NEAR-FULL" ] && ok "150 -> NEAR-FULL (over-spent is still spent)" || bad "150 gave '$r', want NEAR-FULL"

echo
echo "== magnitudes big enough to break the comparison itself =="
# jq renders >=16-digit numbers in scientific notation (1e+16). If that reaches the
# `-ge` it errors, the if reads false, and control falls through to the
# unconditional OPEN at the bottom — confident headroom off a comparison that never
# ran. This case is what pins the character-class check; without it, weakening that
# check to only-reject-empty leaves the suite green (validator finding, 2026-07-17).
r=$(run '{"5h":{"pct":9999999999999999},"resets_at":"9999999999"}')
[ "${r%% *}" = "UNKNOWN" ] && ok "16 digits (jq -> 1e+16) -> UNKNOWN" || bad "1e+16 gave '$r', want UNKNOWN — the char-class guard is not holding"
r=$(run '{"5h":{"pct":999999999999999},"resets_at":"9999999999"}')
[ "${r%% *}" = "UNKNOWN" ] && ok "15 digits (stays plain) -> UNKNOWN" || bad "15 digits gave '$r', want UNKNOWN — no percentage has 15 digits"

echo
echo "== -0 is zero, not '-0' =="
T=$(mktemp -d); printf '{"5h":{"pct":-0}}' > "$T/.limits.json"
d=$(WAKE_LIMITS_FILE="$T/.limits.json" bash "$CHECK" 2>/dev/null | cut -f2)
[ "$d" = "0" ] && ok "-0 reads as 0" || bad "-0 reported as '$d'"
rm -rf "$T"

echo
echo "== a broken threshold must not fail OPEN =="
# The bug this replaced: a digit-string too long for a 64-bit int passed the
# junk filter, aborted `-ge`, and fell through to OPEN exit 0 — a typo turning the
# guard off silently.
thr() { # $1 threshold, $2 pct  -> "verdict exit"
  local T; T=$(mktemp -d); printf '{"5h":{"pct":%s}}' "$2" > "$T/.limits.json"
  local out rc
  out=$(WAKE_LIMITS_FILE="$T/.limits.json" WAKE_NEAR_FULL_PCT="$1" bash "$CHECK" 2>/dev/null); rc=$?
  rm -rf "$T"; printf '%s %s' "$(printf '%s' "$out" | head -1 | cut -f1)" "$rc"
}
r=$(thr 9999999999999999999 95)
[ "${r%% *}" = "NEAR-FULL" ] && ok "19-digit threshold -> falls back to 90, 95% -> NEAR-FULL" || bad "overflow threshold gave '$r' — fail-open"
r=$(thr 150 95)
[ "${r%% *}" = "NEAR-FULL" ] && ok "threshold 150 (>100) -> falls back to 90" || bad "threshold 150 gave '$r'"
r=$(thr abc 95)
[ "${r%% *}" = "NEAR-FULL" ] && ok "threshold 'abc' -> falls back to 90" || bad "threshold abc gave '$r'"
r=$(thr '' 43)
[ "${r%% *}" = "OPEN" ] && ok "empty threshold -> falls back to 90, 43% -> OPEN" || bad "empty threshold gave '$r'"

echo
echo "== the threshold is tunable =="
r=$(WAKE_NEAR_FULL_PCT=50 bash -c "$(declare -f run); CHECK='$CHECK'; run '{\"5h\":{\"pct\":60},\"resets_at\":\"1\"}'" 2>/dev/null)
[ "${r%% *}" = "NEAR-FULL" ] && ok "60% with threshold 50 -> NEAR-FULL" || bad "tunable threshold gave '$r'"

echo
echo "== exit codes carry the verdict (callers may not parse text) =="
r=$(run '{"5h":{"pct":43},"resets_at":"9999999999"}');  [ "${r##* }" = "0" ] && ok "OPEN exits 0" || bad "OPEN exited ${r##* }"
r=$(run '{"5h":{"pct":97},"resets_at":"9999999999"}');  [ "${r##* }" = "1" ] && ok "NEAR-FULL exits 1" || bad "NEAR-FULL exited ${r##* }"
r=$(run '');                                            [ "${r##* }" = "2" ] && ok "UNKNOWN exits 2" || bad "UNKNOWN exited ${r##* }"

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

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
echo "== the merge itself, not just the function =="
# Everything above calls _rl_to_epoch directly, so it stays green even on a
# statusline whose merge never calls it (skeptical review, 2026-07-17). This drives
# the real script: stdin carries the SENTINEL, the cache carries a REAL timestamp.
# Pre-fix, the sentinel parsed to year 2286, won "later resets_at is fresher", and
# the stale stdin value pinned itself. The cached reading must win.
T=$(mktemp -d); mkdir -p "$T/.claude/widgets"
REAL=$((NOW + 3600))
printf '{"5h":{"pct":11},"week":{"pct":22},"resets_at":"%s","resets_at_weekly":"%s"}' "$REAL" "$REAL" \
  > "$T/.claude/widgets/.limits.json"
payload=$(jq -nc --arg cwd "$T" '{
  session_id:"aaaabbbb-1111-2222-3333-444455556666",
  model:{display_name:"Test"}, workspace:{current_dir:$cwd}, transcript_path:"/dev/null",
  rate_limits:{ five_hour:{used_percentage:99, resets_at:"9999999999"},
                seven_day:{used_percentage:88, resets_at:"9999999999"} }}')
printf '%s' "$payload" > "$T/payload.json"
out=$(PJ="$T/payload.json" SL="$SL" HOME="$T" perl -e 'my $p=fork; if($p==0){setpgrp(0,0); open(STDIN,"<",$ENV{PJ}); exec("bash",$ENV{SL}) or exit 127}
               local $SIG{ALRM}=sub{kill "KILL",-$p; exit 9}; alarm 25; waitpid($p,0); exit($?>>8)' 2>/dev/null)
clean=$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g')
if printf '%s' "$clean" | rg -q '7d:22%'; then
  ok "merge took the cached 22% over the sentinel-stamped 88%"
elif printf '%s' "$clean" | rg -q '7d:88%'; then
  bad "merge kept the stale 88% — the sentinel still wins"
else
  bad "could not read a 7d pct from the render (got: $(printf '%s' "$clean" | tr '\n' ' ' | cut -c1-90))"
fi
if printf '%s' "$clean" | rg -q '[0-9]{5,}h'; then
  bad "an absurd countdown rendered — the sentinel reached the display"
else
  ok "no year-2286 countdown in the render"
fi
rm -rf "$T"

echo
printf 'passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

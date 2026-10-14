#!/usr/bin/env bash
# Checks the compaction gate: owner /compact passes, auto is refused unless the
# session opted in or the machine-wide mute is set.
set -u
G="$(dirname "$0")/compact-gate.sh"
SB=$(mktemp -d /private/tmp/claude-501/compact-gate-XXXX)
export COMPACT_GATE_DIR="$SB/through" COMPACT_GATE_MUTE="$SB/mute"
pass=0; fail=0
check() { # name expected-exit trigger sid
  jq -cn --arg t "$3" --arg s "$4" '{trigger:$t,session_id:$s}' | bash "$G" hook 2>/dev/null
  local got=$?
  if [[ $got == "$2" ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $1: want $2 got $got"; fi
}
check "manual passes" 0 manual s1
check "auto refused" 2 auto s1
CLAUDE_CODE_SESSION_ID=s1 bash "$G" on >/dev/null
check "auto after on" 0 auto s1
check "other session still refused" 2 auto s2
CLAUDE_CODE_SESSION_ID=s1 bash "$G" off >/dev/null
check "auto after off" 2 auto s1
touch "$SB/mute"
check "auto with mute" 0 auto s2
trash "$SB"
echo "$pass passed, $fail failed"
[[ $fail == 0 ]]

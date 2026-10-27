#!/usr/bin/env bash
# atone-stop-gate.test.sh: an explicit /atone with no recorded event blocks the stop.
#
# Runs against a sandbox HOME. CLAUDE_CODE_CHILD_SESSION=1 is set on purpose:
# Claude Code sets it for every hook, and a check on it kept the gate silent
# from the day it shipped.
set -u
SB=$(mktemp -d /private/tmp/claude-501/asg-XXXX)
mkdir -p "$SB/.claude/atone/.session-state" "$SB/.claude/hooks"
ln -s "$HOME/.claude/scripts" "$SB/.claude/scripts"
: > "$SB/.claude/atone/events.jsonl"
M="$SB/.claude/atone/.session-state/asg01.pending-atone"
now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
arm() { jq -cn --arg ts "$now" '{explicit:true, ts:$ts}' > "$M"; }
run() { printf '%s' '{"session_id":"asg01"}' | env HOME="$SB" ATONE_NO_FEEDBACK=1 CLAUDE_CODE_CHILD_SESSION=1 "$@" bash "$HOME/.claude/scripts/hooks/atone-stop-gate.sh" | jq -r '.decision // empty'; }
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); echo "  ok    $3"; else fail=$((fail+1)); echo "  FAIL  $3 (got '$1')"; fi; }

arm
ok "$(run)" block "explicit /atone, nothing recorded: blocks, even with CHILD_SESSION=1"
ok "$(run)" block "blocks a second time"
ok "$(run)" "" "steps aside after two"
arm
ok "$(run ATONE_JUROR_SESSION=1)" "" "the juror's own session is never gated"
jq -cn --arg ts "$now" '{ts:$ts, id:"x"}' >> "$SB/.claude/atone/events.jsonl"
ok "$(run)" "" "an event recorded after the marker clears it"
echo "---- pass=$pass fail=$fail"
trash "$SB"
[ "$fail" -eq 0 ]

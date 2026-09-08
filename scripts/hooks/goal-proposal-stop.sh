#!/usr/bin/env bash
# goal-proposal-stop.sh — Stop hook: a proposed /goal is not a place to stop.
#
# The rule says print the paste line and work under it. Measured over 7 days on
# 2026-09-08: 84 of 99 mid-work proposals ended the turn with no tool call after
# them, the largest single halt source in the corpus. This blocks a turn whose
# final assistant message carries a bare "/goal ..." line and no tool call,
# once per message, then steps aside. Hand-off turns are exempt: a catchup's
# closing question and a core-dump's checkpoint are followed by nothing on
# purpose. Owner ruling 2026-09-08 (c): yes.
#
# Loop-safe: stop_hook_active in the input means the harness is already
# continuing after a block, and the same message is never blocked twice.
# Mute: touch ~/.claude/.no-goal-proposal-gate  (machine-wide until removed)
set -uo pipefail
[ -f "$HOME/.claude/.no-goal-proposal-gate" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty'); sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$tp" ] && [ -f "$tp" ] || exit 0
last=$(tail -n 400 "$tp" | jq -c 'select(.type=="assistant")' 2>/dev/null | tail -1)
[ -n "$last" ] || exit 0
has_tool=$(printf '%s' "$last" | jq -r '[.message.content[]? | select(.type=="tool_use")] | length')
[ "${has_tool:-0}" -eq 0 ] || exit 0
text=$(printf '%s' "$last" | jq -r '.message.content[]? | select(.type=="text") | .text')
printf '%s' "$text" | rg -q '^\s*/goal ' || exit 0
printf '%s' "$text" | rg -qi 'Which pending item|/catchup|checkpoint|core-dump|Resume with' && exit 0
h=$(printf '%s' "$text" | shasum | cut -c1-12)
STATE="/tmp/claude-goalprop-${sid:0:8}"
[ "$(cat "$STATE" 2>/dev/null)" = "$h" ] && exit 0
printf '%s' "$h" > "$STATE"
# The proposal is the moment to lint the wording, before the owner arms it; a
# lint that fires after the arm can only ask him to re-arm (forge-console,
# 2026-09-08). Findings ride the block so the paste line is fixed while working.
prop=$(printf '%s' "$text" | rg -o '^\s*/goal .*' | head -1 | sed 's/^[[:space:]]*\/goal //')
lint=""
[ -n "$prop" ] && lint=$(bash "$HOME/.claude/scripts/goal/goal.sh" lint "$prop" 2>&1 >/dev/null | rg -v '^linted\.$' || true)
reason='You printed a /goal paste line and ended the turn with no tool call after it. A proposal is not a stop: the rule says work under it while the line sits (rules/goal-statement-on-starting-work.md, Propose, do not arm). Make the next tool call toward the goal you just proposed. If the work genuinely waits on the owner, say so in one line as a blocked-on, not as a paste line. This block fires once per message; mute: touch ~/.claude/.no-goal-proposal-gate'
[ -n "$lint" ] && reason="$reason
The proposed goal also has lint findings; fix the wording before it is armed:
$lint"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'

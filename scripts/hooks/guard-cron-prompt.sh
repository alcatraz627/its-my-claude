#!/usr/bin/env bash
# guard-cron-prompt.sh — vets and records every prompt an agent schedules.
#
# A cron prompt arrives later as an ordinary "user" turn. Two things follow:
# it must never carry an approval line, or an agent could approve its own push
# or policy ask; and wake-breaker.sh must be able to recognise it when it fires,
# which it does by the prompt's hash, recorded here.
#
# Runs as PreToolUse on CronCreate.
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
prompt=$(printf '%s' "$input" | jq -r '.tool_input.prompt // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
lower=$(printf '%s' "$prompt" | tr 'A-Z' 'a-z')

approval='(approve|cancel) push|approve [a-z0-9._-]+ [0-9a-f]{6,}|deny [a-z0-9._-]+\.[a-z0-9._-]+'
if [[ "$lower" =~ $approval ]]; then
  jq -cn '{decision:"block", reason:"A cron prompt may not carry an approval line. Approvals are the owner'"'"'s to type; ask him in your own words instead."}'
  exit 0
fi

[ -n "$sid" ] && [ -n "$prompt" ] || exit 0
dir="/tmp/claude-wakes-${sid:0:8}"
mkdir -p "$dir" 2>/dev/null || exit 0
printf '%s' "$prompt" | shasum | cut -c1-16 >> "$dir/crons"
exit 0

#!/usr/bin/env bash
# UserPromptSubmit hook: increments conversation turn counter
# Writes to /tmp/claude-turns-$SESSION_ID (single number)
# Statusline reads this to show turn count

set -uo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
[[ -z "$session_id" ]] && exit 0

# Use first 8 chars of session ID for filename
sid_short="${session_id:0:8}"
COUNTER_FILE="/tmp/claude-turns-${sid_short}"

current=0
[[ -f "$COUNTER_FILE" ]] && current=$(cat "$COUNTER_FILE" 2>/dev/null | tr -d '[:space:]') || true
current=${current:-0}
echo $((current + 1)) > "$COUNTER_FILE"

exit 0

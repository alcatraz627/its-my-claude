#!/usr/bin/env bash
# permission-notify.sh — Extracts tool details from hook input, sends notification
# Called from Claude Code PermissionRequest hook
#
# Uses OSC 9 so the notification is Ghostty-attributed and clicking it navigates
# to the exact tab that needs permission — critical when multiple sessions are open.
# Plays a sound separately since OSC 9 has no audio support.

set -uo pipefail

if ! command -v jq &>/dev/null; then
  ( printf '\033]9;%s\007' "Claude Code — Permission Required: Tool approval needed" > /dev/tty ) 2>/dev/null || true
  exit 0
fi

input=$(cat)

# Skip notification if no user interaction is possible:
# - bypassPermissions/dontAsk/plan modes auto-approve without prompting
# - agent_id present means request came from a headless subagent (no interactive dialog)
permission_mode=$(echo "$input" | jq -r '.permission_mode // "default"' 2>/dev/null)
agent_id=$(echo "$input" | jq -r '.agent_id // ""' 2>/dev/null)
if [[ "$permission_mode" == "bypassPermissions" || "$permission_mode" == "dontAsk" || "$permission_mode" == "plan" || -n "$agent_id" ]]; then
  exit 0
fi

tool=$(echo "$input" | jq -r '.tool_name // "Unknown"' 2>/dev/null)
tool_input=$(echo "$input" | jq -r '.tool_input // {}' 2>/dev/null)

case "$tool" in
  Bash)
    summary=$(echo "$tool_input" | jq -r '.command // ""' 2>/dev/null | head -c 80)
    ;;
  Edit|Write)
    summary=$(echo "$tool_input" | jq -r '.file_path // ""' 2>/dev/null | xargs basename 2>/dev/null)
    ;;
  Read)
    summary=$(echo "$tool_input" | jq -r '.file_path // ""' 2>/dev/null | xargs basename 2>/dev/null)
    ;;
  WebFetch|WebSearch)
    summary=$(echo "$tool_input" | jq -r '.url // .query // ""' 2>/dev/null | head -c 80)
    ;;
  Agent)
    summary=$(echo "$tool_input" | jq -r '.description // ""' 2>/dev/null | head -c 80)
    ;;
  *)
    summary=$(echo "$tool_input" | jq -r 'to_entries | map(.key + ":" + (.value | tostring)[:30]) | join(", ")' 2>/dev/null | head -c 80)
    ;;
esac

# OSC 9: Ghostty-attributed notification — clicking navigates to this exact tab
# TTY_PATH can be overridden in tests (defaults to /dev/tty)
msg=$(printf '%s' "$tool: $summary" | tr -d '\000-\031\177')
( printf '\033]9;%s\007' "Permission Required — $msg" > "${TTY_PATH:-/dev/tty}" ) 2>/dev/null || true

# Play sound separately (OSC 9 has no audio support)
afplay /System/Library/Sounds/Ping.aiff &>/dev/null &

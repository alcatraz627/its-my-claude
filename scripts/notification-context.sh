#!/usr/bin/env bash
# notification-context.sh — Context-aware Claude Code notification handler
# Called from Claude Code Notification hook (idle_prompt, elicitation_dialog)
#
# Uses OSC 9 to send a notification via the terminal rather than terminal-notifier.
# This makes the notification appear attributed to Ghostty — clicking it navigates
# directly to the correct tab, which terminal-notifier cannot do.
#
# Context: reads the cached LLM topic for the session, falls back to last user
# message from transcript, then to directory name.

set -uo pipefail

input=$(cat)

# Extract fields from hook input
if command -v jq &>/dev/null; then
  session_id=$(echo "$input" | jq -r '.session_id // "default"' 2>/dev/null)
  notif_type=$(echo "$input"  | jq -r '.type // ""'             2>/dev/null)
  transcript=$(echo "$input"  | jq -r '.transcript_path // ""'  2>/dev/null)
  cwd=$(echo "$input"         | jq -r '.cwd // ""'              2>/dev/null)
else
  session_id="default"; notif_type=""; transcript=""; cwd=""
fi

# 1. Prefer LLM-generated topic (written by the Stop agent hook)
topic=$(cat "/tmp/claude-tab-topic-${session_id}" 2>/dev/null || true)

# 2. Fall back to last user message from transcript (same filter as update-tab-title.sh)
if [[ -z "$topic" && -n "$transcript" && -f "$transcript" ]]; then
  raw=$(grep '"type":"user"' "$transcript" 2>/dev/null | \
    grep -v '"tool_result"' | \
    jq -r '
      .message.content |
      (if type == "array" then map(select(.type == "text") | .text) | join(" ")
       elif type == "string" then .
       else empty end) |
      select(length > 0 and length < 500) |
      select(startswith("<") | not)
    ' 2>/dev/null | tail -1 || true)
  if [[ -n "$raw" ]]; then
    topic=$(printf '%.45s' "$raw")
    [[ ${#raw} -gt 45 ]] && topic="${topic}..."
  fi
fi

# 3. Fall back to directory name
if [[ -z "$topic" ]]; then
  topic=$(basename "${cwd:-$(pwd)}")
fi

context="Re: $topic"

# 4. Extract actionable detail for richer notifications
action_detail=""
if [[ "$notif_type" == "idle_prompt" ]]; then
  # Try to get what Claude was doing last (from tool counter)
  TOOL_FILE="/tmp/claude-tools-${PPID}"
  if [[ -f "$TOOL_FILE" ]]; then
    tool_total=$(grep '^_total=' "$TOOL_FILE" 2>/dev/null | cut -d= -f2) || true
    [[ -n "$tool_total" ]] && action_detail=" (${tool_total} tools used)"
  fi
fi

case "$notif_type" in
  idle_prompt)       label="Waiting${action_detail} —" ;;
  elicitation_dialog) label="MCP Input Needed —"       ;;
  *)                 label="Claude Code —"             ;;
esac

# OSC 9: terminal notification, attributed to Ghostty, navigates to the right tab on click.
# Format: ESC ] 9 ; <message> BEL — TTY_PATH can be overridden in tests
( printf '\033]9;%s\007' "$label $context" > "${TTY_PATH:-/dev/tty}" ) 2>/dev/null || true

# Bell: triggers Ghostty tab attention indicator + audio cue
( printf '\a' > "${TTY_PATH:-/dev/tty}" ) 2>/dev/null || true
afplay /System/Library/Sounds/Morse.aiff &>/dev/null &

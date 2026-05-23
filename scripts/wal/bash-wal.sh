#!/usr/bin/env bash
# bash-wal.sh — PreToolUse/PostToolUse hook for the Bash tool. Writes
# bash_intent (Pre) and bash_closed (Post) action entries to the session WAL
# so /catchup can see which shell command was in flight if a session crashes.
#
# Pair with the existing emit-event.sh: that writes to events.jsonl (global
# log), while this one writes to WAL (per-session recoverability log).
#
# Usage in settings.json:
#   Pre : "command": "/bin/bash ~/.claude/scripts/wal/bash-wal.sh pre"
#   Post: "command": "/bin/bash ~/.claude/scripts/wal/bash-wal.sh post"
# Both with matcher: "Bash".
#
# Hook input (stdin):
#   Pre : {session_id, cwd, tool_use_id, tool_input:{command, ...}}
#   Post: {session_id, cwd, tool_use_id, tool_input:{command}, tool_response:{interrupted, is_error}}
#
# WAL entries emitted (one per invocation):
#   {kind:"action", verb:"bash_intent", target:"<cmd head, 120 chars>",
#    outcome:"uid=<short-id>"}
#   {kind:"action", verb:"bash_closed", target:"<cmd head>",
#    outcome:"uid=<short-id> status=ok|error|interrupted"}
#
# Fails silently — never blocks the tool call.

set -uo pipefail

PHASE="${1:-}"
[ -z "$PHASE" ] && exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
[ -z "$INPUT" ] && INPUT="{}"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null || echo "")
CMD_PREVIEW=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null | tr '\n' ' ' | head -c 120)

[ -z "$SESSION_ID" ] && exit 0
[ -z "$CMD_PREVIEW" ] && exit 0

# Short tool-use id (last 8 chars of sanitized version) for pairing in logs
SAFE_UID=$(printf '%s' "$TOOL_USE_ID" | tr -c 'a-zA-Z0-9_-' '_')
SHORT_UID=$(printf '%s' "$SAFE_UID" | tail -c 8)
[ -z "$SHORT_UID" ] && SHORT_UID="noid"

VERB=""
OUTCOME=""
case "$PHASE" in
  pre)
    VERB="bash_intent"
    OUTCOME="uid=$SHORT_UID"
    ;;
  post)
    VERB="bash_closed"
    STATUS=$(echo "$INPUT" | jq -r '
      if (.tool_response.interrupted // false) == true then "interrupted"
      elif (.tool_response.is_error // false) == true then "error"
      else "ok" end
    ' 2>/dev/null || echo "unknown")
    OUTCOME="uid=$SHORT_UID status=$STATUS"
    ;;
  *)
    exit 0
    ;;
esac

if [ -x "$HOME/.claude/scripts/wal/wal.sh" ]; then
  (
    cd "$CWD" 2>/dev/null || cd "$HOME/.claude"
    bash "$HOME/.claude/scripts/wal/wal.sh" action "$SESSION_ID" "$VERB" "$CMD_PREVIEW" "$OUTCOME"
  ) >/dev/null 2>&1 || true
fi

exit 0

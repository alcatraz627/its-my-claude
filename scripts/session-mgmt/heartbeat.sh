#!/usr/bin/env bash
# heartbeat.sh — PostToolUse hook. Writes a WAL heartbeat entry every Nth tool
# call, so long-running sessions leave a breadcrumb trail even if they crash
# before Stop / PreCompact hooks can fire.
#
# Pair with turn-start.sh (UserPromptSubmit) + detect-stale-session.sh
# (SessionStart). Heartbeats give /catchup a tighter bound on "last known good"
# state than per-turn checkpoints alone.
#
# Hook input (stdin): {session_id, tool_name, cwd, ...}
#
# State:
#   ~/.claude/.turn-state/heartbeat-<sid> — plain-text integer counter.
#   Incremented on every PostToolUse, zero'd by turn-end-cleanup.sh on Stop.
#
# Interval:
#   Every CLAUDE_HEARTBEAT_INTERVAL tool calls (default 10). Override via env
#   for tests or to tune noise/recoverability tradeoff.
#
# Fails silently — never blocks the tool call.

set -uo pipefail

HEARTBEAT_INTERVAL="${CLAUDE_HEARTBEAT_INTERVAL:-10}"
STATE_DIR="$HOME/.claude/.turn-state"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
[ -z "$INPUT" ] && INPUT="{}"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0

SAFE_SID=$(printf '%s' "$SESSION_ID" | tr -c 'a-zA-Z0-9_-' '_' | head -c 120)
[ -z "$SAFE_SID" ] && exit 0

COUNTER_FILE="$STATE_DIR/heartbeat-$SAFE_SID"
PREV_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
# Guard against non-integer contents
case "$PREV_COUNT" in
  ''|*[!0-9]*) PREV_COUNT=0 ;;
esac
NEW_COUNT=$((PREV_COUNT + 1))
printf '%s' "$NEW_COUNT" > "$COUNTER_FILE" 2>/dev/null || true

# Only emit on interval boundaries
if [ "$((NEW_COUNT % HEARTBEAT_INTERVAL))" -ne 0 ]; then
  exit 0
fi

# Emit WAL heartbeat via wal.sh (it handles target resolution + escaping)
if [ -x "$HOME/.claude/scripts/wal/wal.sh" ] && [ -n "$CWD" ]; then
  (
    cd "$CWD" 2>/dev/null || cd "$HOME/.claude"
    bash "$HOME/.claude/scripts/wal/wal.sh" action "$SESSION_ID" "heartbeat" "$TOOL_NAME" "tools=$NEW_COUNT"
  ) >/dev/null 2>&1 || true
fi

exit 0

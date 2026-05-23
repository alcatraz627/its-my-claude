#!/usr/bin/env bash
# turn-start.sh — UserPromptSubmit hook. Writes a per-session turn-state file
# BEFORE Claude begins processing the user's prompt. If the turn dies mid-flight
# (API 5xx, network loss, kernel panic), this file is the only signal that a
# turn was in progress. Paired with detect-stale-session.sh (SessionStart hook)
# which surfaces it on next launch.
#
# Hook input (stdin): {session_id, prompt, cwd, ...}
#
# Output:
#   - ~/.claude/.turn-state/<sid>.json  — atomic state for this session's live turn
#   - WAL entry (turn_start) in session's wal.jsonl if WAL is resolvable
#
# Design notes:
# - Fails silently — never blocks the prompt.
# - Overwrites prior turn-state file for same session (last turn only).
# - Cleanup: Stop hook clears ~/.claude/.turn-state/<sid>.json on normal exit.

set -uo pipefail

STATE_DIR="$HOME/.claude/.turn-state"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
[ -z "$INPUT" ] && INPUT="{}"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null | head -c 400 || echo "")

[ -z "$SESSION_ID" ] && exit 0

# Sanitize session_id for filename
SAFE_SID=$(printf '%s' "$SESSION_ID" | tr -c 'a-zA-Z0-9_-' '_' | head -c 120)
[ -z "$SAFE_SID" ] && exit 0

TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Increment turn counter for this session (used by heartbeat script later)
COUNTER_FILE="$STATE_DIR/counter-$SAFE_SID"
PREV_COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
TURN_NUM=$((PREV_COUNT + 1))
printf '%s' "$TURN_NUM" > "$COUNTER_FILE" 2>/dev/null || true

# Atomic write of turn-state file
TMP_FILE=$(mktemp "$STATE_DIR/.tmp.XXXXXX" 2>/dev/null) || exit 0
STATE_FILE="$STATE_DIR/$SAFE_SID.json"

jq -cn --arg ts "$TS" --arg sid "$SESSION_ID" --arg cwd "$CWD" \
       --arg prompt "$PROMPT" --argjson turn "$TURN_NUM" \
  '{
    ts: $ts,
    session_id: $sid,
    cwd: $cwd,
    prompt_preview: $prompt,
    turn: $turn,
    status: "in_progress"
  }' > "$TMP_FILE" 2>/dev/null || { rm -f "$TMP_FILE"; exit 0; }

mv -f "$TMP_FILE" "$STATE_FILE" 2>/dev/null || { rm -f "$TMP_FILE"; exit 0; }

# Also emit a WAL turn_start entry (best effort). Use wal.sh for safe escaping.
# The WAL target resolution is handled by wal.sh itself.
if [ -x "$HOME/.claude/scripts/wal/wal.sh" ] && [ -n "$CWD" ]; then
  # Run wal.sh in a subshell with CWD set so it resolves project vs global correctly
  (
    cd "$CWD" 2>/dev/null || cd "$HOME/.claude"
    bash "$HOME/.claude/scripts/wal/wal.sh" action "$SESSION_ID" "turn_start" "turn $TURN_NUM" "$PROMPT"
  ) >/dev/null 2>&1 || true
fi

exit 0

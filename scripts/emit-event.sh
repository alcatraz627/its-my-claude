#!/usr/bin/env bash
# emit-event.sh — append ONE JSON line to ~/.claude/events.jsonl
# Invoked by hooks. Reads hook-input JSON from stdin. Never blocks: always exits 0.
#
# Usage (in settings.json):
#   "command": "~/.claude/scripts/emit-event.sh SessionStart"
#
# Output format (one line per event, JSONL). Core fields are always present; the
# enrichment fields (duration_ms, error, cost_delta_usd) only appear on the
# relevant event kinds.
#
#   {"ts": "...", "event": "SessionStart", "session_id": "...",
#    "cwd": "...", "project": "...", "tool": "...",
#    "duration_ms": 1234,        # PostToolUse, if its PreToolUse was seen
#    "error": true,               # PostToolUse, if tool_response signals failure
#    "cost_delta_usd": 0.042      # Stop/SubagentStop, if input carries cost fields
#   }
#
# Design notes:
# - Global log at ~/.claude/events.jsonl; project field lets you filter later
# - flock prevents interleaved writes when multiple async hooks fire at once
# - Any failure (missing jq, malformed stdin, disk full) is swallowed — we never
#   want a log emitter to disrupt the hook chain
# - Duration uses a tiny timestamp file per tool_use_id in ~/.claude/.tool-timers/
#   written at PreToolUse, read+unlinked at PostToolUse. Leaks are self-limiting
#   (tool IDs are unique) and files are ~15 bytes each

set -uo pipefail

EVENT="${1:-unknown}"
LOG="$HOME/.claude/events.jsonl"
LOCK="$HOME/.claude/.events.lock"
TIMER_DIR="$HOME/.claude/.tool-timers"

# Ensure log exists (create parent dir defensively)
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
touch "$LOG" 2>/dev/null || exit 0

# Expire stale tool-timer files (>1h) — orphans from crashed sessions.
# Runs every invocation; scanning a flat dir of tiny files is near-zero cost.
if [ -d "$TIMER_DIR" ]; then
  find "$TIMER_DIR" -maxdepth 1 -type f -mmin +60 -delete 2>/dev/null || true
fi

# Read stdin (may be empty for some events)
INPUT=$(cat 2>/dev/null || echo "{}")
[ -z "$INPUT" ] && INPUT="{}"

# Pull common fields. All default to empty string if missing.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || echo "")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""' 2>/dev/null || echo "")
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // ""' 2>/dev/null || echo "")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null | head -c 200 || echo "")
PROJECT=""
[ -n "$CWD" ] && PROJECT="$(basename "$CWD" 2>/dev/null || echo "")"

TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo "")

# Millisecond epoch. macOS `date` has no %N, so prefer python3 / perl, fall back
# to second-precision × 1000 (gives 0ms for quick tools, which is acceptable).
NOW_MS=$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null \
  || perl -MTime::HiRes=time -e 'printf("%d\n", time*1000)' 2>/dev/null \
  || echo "$(date +%s 2>/dev/null || echo 0)000")

DURATION_MS=""
ERROR=""
COST_DELTA=""

SESSION_ID_FILE="$HOME/.claude/.current-session-id"

case "$EVENT" in
  SessionStart)
    # Persist session_id to file so non-hook scripts can read it as a fallback.
    # "Last session wins" — acceptable since multi-session hooks get IDs via stdin.
    if [ -n "$SESSION_ID" ]; then
      printf '%s' "$SESSION_ID" > "$SESSION_ID_FILE" 2>/dev/null || true
    fi
    ;;

  PreToolUse)
    if [ -n "$TOOL_USE_ID" ]; then
      mkdir -p "$TIMER_DIR" 2>/dev/null || true
      # Sanitize tool_use_id for use as a filename (defensive — IDs are usually
      # alnum + underscore already).
      SAFE_ID=$(printf '%s' "$TOOL_USE_ID" | tr -c 'a-zA-Z0-9_-' '_' | head -c 120)
      [ -n "$SAFE_ID" ] && printf '%s' "$NOW_MS" > "$TIMER_DIR/$SAFE_ID" 2>/dev/null || true
    fi
    ;;

  PostToolUse)
    if [ -n "$TOOL_USE_ID" ]; then
      SAFE_ID=$(printf '%s' "$TOOL_USE_ID" | tr -c 'a-zA-Z0-9_-' '_' | head -c 120)
      TIMER_FILE="$TIMER_DIR/$SAFE_ID"
      if [ -n "$SAFE_ID" ] && [ -f "$TIMER_FILE" ]; then
        START_MS=$(cat "$TIMER_FILE" 2>/dev/null || echo "")
        if [ -n "$START_MS" ] && [ "$START_MS" -gt 0 ] 2>/dev/null; then
          DURATION_MS=$(( NOW_MS - START_MS ))
          [ "$DURATION_MS" -lt 0 ] && DURATION_MS=""
        fi
        # Clean up the timer file. This script isn't routed through the Bash-tool
        # PreToolUse safe-delete hook, so a direct unlink is fine.
        rm -f "$TIMER_FILE" 2>/dev/null || true
      fi
    fi
    # Detect error. Non-Bash tools use `.tool_response.is_error`; Bash uses
    # `.tool_response.interrupted`. Accept either.
    IS_ERR=$(echo "$INPUT" | jq -r '
      if (.tool_response.is_error // false) == true then "true"
      elif (.tool_response.interrupted // false) == true then "true"
      else "" end
    ' 2>/dev/null || echo "")
    [ "$IS_ERR" = "true" ] && ERROR="true"
    ;;

  Stop|SubagentStop)
    # Pull cost delta if the harness provides it. Different versions have used
    # different field names — check several.
    COST_DELTA=$(echo "$INPUT" | jq -r '
      .cost_delta_usd // .cost_delta // .total_cost_usd // .cost_usd // empty
    ' 2>/dev/null || echo "")
    ;;
esac

# Build JSON line with jq to guarantee valid escaping. Enrichment fields are
# coerced to the right JSON type and then stripped if empty/null.
LINE=$(jq -cn \
  --arg ts "$TS" \
  --arg event "$EVENT" \
  --arg session_id "$SESSION_ID" \
  --arg cwd "$CWD" \
  --arg project "$PROJECT" \
  --arg tool "$TOOL_NAME" \
  --arg tool_use_id "$TOOL_USE_ID" \
  --arg trigger "$TRIGGER" \
  --arg prompt "$PROMPT" \
  --arg duration_ms "$DURATION_MS" \
  --arg error "$ERROR" \
  --arg cost_delta "$COST_DELTA" \
  '{
    ts: $ts,
    event: $event,
    session_id: $session_id,
    cwd: $cwd,
    project: $project,
    tool: $tool,
    tool_use_id: $tool_use_id,
    trigger: $trigger,
    prompt_preview: $prompt,
    duration_ms: (if $duration_ms == "" then null else ($duration_ms | tonumber?) end),
    error: (if $error == "true" then true else null end),
    cost_delta_usd: (if $cost_delta == "" then null else ($cost_delta | tonumber?) end)
  } | with_entries(select(.value != "" and .value != null))' \
  2>/dev/null) || exit 0

[ -z "$LINE" ] && exit 0

# Append under lock
(
  flock -x 9 2>/dev/null || true
  printf '%s\n' "$LINE" >> "$LOG"
) 9>>"$LOCK" 2>/dev/null || true

exit 0

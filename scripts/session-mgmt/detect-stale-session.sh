#!/usr/bin/env bash
# detect-stale-session.sh — SessionStart hook. Detects whether the previous
# session terminated abnormally (API crash, network loss, kernel panic) and
# injects an additionalContext hint prompting /catchup.
#
# Stale signals (any ONE triggers the hint):
#   1. ~/.claude/.turn-state/*.json exists (turn-start.sh wrote it, turn-end-
#      cleanup.sh never ran → turn crashed mid-flight).
#   2. Global WAL (~/.claude/wal.jsonl) has a session_start without a matching
#      session_end, within the last 24h.
#
# Scope: checks the GLOBAL WAL only. Project-local WALs are checked by /catchup
# itself when invoked in that project. This hook is about surfacing the need.
#
# Output: stdout JSON with hookSpecificOutput.additionalContext populated if
# stale. Empty object otherwise. Never blocks SessionStart.

set -uo pipefail

STATE_DIR="$HOME/.claude/.turn-state"
GLOBAL_WAL="$HOME/.claude/wal.jsonl"

STALE_TURNS=()
STALE_SESSIONS=()

# Check 1: orphan turn-state files
if [ -d "$STATE_DIR" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # Only consider recent files (last 48h) — anything older is likely debris
    if [ -n "$(find "$f" -mtime -2 2>/dev/null)" ]; then
      sid=$(jq -r '.session_id // ""' "$f" 2>/dev/null)
      ts=$(jq -r '.ts // ""' "$f" 2>/dev/null)
      prompt=$(jq -r '.prompt_preview // ""' "$f" 2>/dev/null | head -c 80)
      [ -n "$sid" ] && STALE_TURNS+=("$sid @ $ts — \"$prompt\"")
    fi
  done < <(find "$STATE_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null)
fi

# Check 2: WAL has dangling session_start (no matching session_end) within 24h
if [ -f "$GLOBAL_WAL" ]; then
  # Pull the last 200 lines — enough to find a session_start and its matching
  # end if both exist recently. This is a defensive limit, not a correctness
  # one; /catchup itself does a thorough read.
  TAIL=$(tail -n 200 "$GLOBAL_WAL" 2>/dev/null)
  if [ -n "$TAIL" ]; then
    DANGLING=$(echo "$TAIL" | jq -rc --argjson now_s "$(date +%s)" '
      . as $e
      | select(.kind == "session_start")
      | select(((.ts | sub("Z$"; "") | sub("T"; " ") | sub("-"; "/") | sub("-"; "/") | strptime("%Y/%m/%d %H:%M:%S") | mktime) // 0) > ($now_s - 86400))
      | .session_id
    ' 2>/dev/null | sort -u)
    CLOSED=$(echo "$TAIL" | jq -rc 'select(.kind == "session_end") | .session_id' 2>/dev/null | sort -u)
    while IFS= read -r sid; do
      [ -z "$sid" ] && continue
      if ! echo "$CLOSED" | grep -qxF "$sid"; then
        STALE_SESSIONS+=("$sid")
      fi
    done <<< "$DANGLING"
  fi
fi

# If nothing stale, emit empty hook output and exit
if [ ${#STALE_TURNS[@]} -eq 0 ] && [ ${#STALE_SESSIONS[@]} -eq 0 ]; then
  echo '{}'
  exit 0
fi

# Build the hint
MSG="Previous session(s) did not close cleanly — possible crash, API error, or abrupt termination."
if [ ${#STALE_TURNS[@]} -gt 0 ]; then
  MSG="$MSG"$'\n\nOrphan turn-state files (turn started but never finished):'
  for t in "${STALE_TURNS[@]}"; do
    MSG="$MSG"$'\n  - '"$t"
  done
fi
if [ ${#STALE_SESSIONS[@]} -gt 0 ]; then
  MSG="$MSG"$'\n\nWAL sessions with no session_end (global log):'
  for s in "${STALE_SESSIONS[@]}"; do
    MSG="$MSG"$'\n  - '"$s"
  done
fi
MSG="$MSG"$'\n\nRun /catchup to restore context from the most recent checkpoint or WAL.'

jq -cn --arg msg "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $msg
  }
}' 2>/dev/null || echo '{}'

exit 0

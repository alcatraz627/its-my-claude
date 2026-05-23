#!/usr/bin/env bash
# PostToolUse hook: increments tool call counters per session
# Writes to /tmp/claude-tools-$PPID as key=value (tool_name=count)
# Statusline reads this file to show tool frequency
#
# Uses mkdir-based lock + atomic tmp→mv to prevent lost increments
# when multiple PostToolUse hooks fire in parallel.

set -uo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null) || true
[[ -z "$tool_name" ]] && exit 0

# Normalize tool names to short labels
case "$tool_name" in
  Read)    key="R" ;;
  Edit)    key="E" ;;
  Write)   key="W" ;;
  Bash)    key="B" ;;
  Glob)    key="G" ;;
  Grep)    key="Gr" ;;
  Agent)   key="Ag" ;;
  Skill)   key="Sk" ;;
  mcp__*)  key="MCP" ;;
  *)       key="O" ;;  # Other
esac

# Counter file keyed by the Claude process
COUNTER_FILE="/tmp/claude-tools-${PPID}"
LOCK_DIR="${COUNTER_FILE}.lockdir"

# mkdir-based lock (portable, atomic on all filesystems)
_lock()   { for _ in 1 2 3 4 5; do mkdir "$LOCK_DIR" 2>/dev/null && return 0; sleep 0.05; done; return 1; }
_unlock() { rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap _unlock EXIT

if ! _lock; then
  # Failed to acquire lock after retries — skip this increment rather than block
  exit 0
fi

# Atomic read-modify-write: rebuild entire file with updated counters
tmp="${COUNTER_FILE}.tmp"
found_key=0
found_total=0
{
  if [[ -f "$COUNTER_FILE" ]]; then
    while IFS='=' read -r k v; do
      [[ -z "$k" ]] && continue
      if [[ "$k" == "$key" ]]; then
        echo "${k}=$((v + 1))"
        found_key=1
      elif [[ "$k" == "_total" ]]; then
        echo "_total=$((v + 1))"
        found_total=1
      else
        echo "${k}=${v}"
      fi
    done < "$COUNTER_FILE"
  fi
  # Append new entries if not found
  (( found_key ))   || echo "${key}=1"
  (( found_total )) || echo "_total=1"
} > "$tmp"
mv -f "$tmp" "$COUNTER_FILE"

_unlock

# Auto-checkpoint: emit WAL checkpoint and additionalContext reminder at milestones.
# Read the new total from the counter file.
new_total=$(grep '^_total=' "$COUNTER_FILE" 2>/dev/null | cut -d= -f2)
new_total=${new_total:-0}

if [[ "$new_total" -eq 30 ]]; then
  # Milestone: suggest WAL checkpoint via additionalContext
  echo '{"additionalContext":"[auto-checkpoint] Tool count reached 30. Consider writing a WAL checkpoint now to preserve session state."}'
elif [[ "$new_total" -eq 60 ]]; then
  echo '{"additionalContext":"[auto-checkpoint] Tool count reached 60. This is a long session — consider running /core-dump mini before context loss."}'
fi

exit 0

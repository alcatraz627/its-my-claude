#!/usr/bin/env bash
# PostCompact hook: inject context recovery summary after compaction
# Returns additionalContext with WAL checkpoint + modified files
set -uo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || true
cwd="${cwd:-$(pwd)}"

recovery=""

# 1. Read WAL checkpoint
for wal_path in "$cwd/.claude/wal.md" "$HOME/.claude/wal.md"; do
  if [[ -f "$wal_path" ]]; then
    # Extract last CHECKPOINT section
    checkpoint=$(awk '/=== CHECKPOINT/,/^---$/{print}' "$wal_path" 2>/dev/null | tail -20)
    if [[ -n "$checkpoint" ]]; then
      # Extract key fields
      goal=$(echo "$checkpoint" | grep -i "goal:" | head -1 | sed -E 's/.*[Gg]oal: *//' | tr -s ' ' | sed 's/ *$//')
      current=$(echo "$checkpoint" | grep -i "current:" | head -1 | sed -E 's/.*[Cc]urrent: *//' | tr -s ' ' | sed 's/ *$//')
      next=$(echo "$checkpoint" | grep -i "next:" | head -1 | sed -E 's/.*[Nn]ext: *//' | tr -s ' ' | sed 's/ *$//')
      [[ -n "$goal" ]] && recovery+="Goal: $goal. "
      [[ -n "$current" ]] && recovery+="Current: $current. "
      [[ -n "$next" ]] && recovery+="Next: $next. "
    fi
    break
  fi
done

# 2. Read modified files from tool counter
TOOL_FILE="/tmp/claude-tools-${PPID}"
if [[ -f "$TOOL_FILE" ]]; then
  total_tools=$(grep '^_total=' "$TOOL_FILE" 2>/dev/null | cut -d= -f2) || true
  [[ -n "$total_tools" ]] && recovery+="Tools used: ${total_tools}. "
fi

# 3. Read turn count
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true
sid_short="${session_id:0:8}"
TURN_FILE="/tmp/claude-turns-${sid_short}"
turn_count=0
[[ -f "$TURN_FILE" ]] && turn_count=$(cat "$TURN_FILE" 2>/dev/null | tr -d '[:space:]') || true
[[ "${turn_count:-0}" -gt 0 ]] && recovery+="Turn count: ${turn_count}. "

# 4. Output recovery context (max ~500 chars)
if [[ -n "$recovery" ]]; then
  # Truncate to ~500 chars
  recovery="${recovery:0:500}"
  jq -n --arg ctx "[POST-COMPACT RECOVERY] $recovery" \
    '{systemMessage: $ctx}'
fi

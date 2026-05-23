#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): track Claude's own file edits
# Writes file_path + timestamp to temp file so FileChanged hook can filter self-edits
set -uo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || true
session_id=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null) || true

[[ -z "$file_path" || -z "$session_id" ]] && exit 0

sid="${session_id:0:8}"
EDITS_FILE="/tmp/claude-edits-${sid}"

# Atomic append + prune: build new file with fresh entries, then replace
now=$(date +%s)
tmp="${EDITS_FILE}.tmp"
{
  # Keep existing entries younger than 30s
  if [[ -f "$EDITS_FILE" ]]; then
    while IFS='|' read -r ts fp; do
      (( now - ${ts:-0} < 30 )) && echo "${ts}|${fp}"
    done < "$EDITS_FILE"
  fi
  # Append the new entry
  echo "${now}|${file_path}"
} > "$tmp"
mv -f "$tmp" "$EDITS_FILE"

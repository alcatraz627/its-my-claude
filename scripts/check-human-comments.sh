#!/usr/bin/env bash
# check-human-comments.sh — PreToolUse hook for Edit/Write
# Warns (non-blocking) when the target file contains human-authored comments
# near the edit location. Scans for NOTE(by human), HACK, IMPORTANT, MANUAL,
# DO NOT CHANGE, INTENTIONAL, and similar markers.
#
# Input: JSON on stdin with tool_input.file_path and tool_input.old_string
# Output: Warning message to stderr (non-blocking — exits 0 always)

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
OLD_STRING=$(echo "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null)

# shellcheck source=/dev/null
source ~/.claude/skills/shared/gum-tui.sh

# Skip if no file path
[ -z "$FILE_PATH" ] && exit 0

# Skip if file doesn't exist
[ -f "$FILE_PATH" ] || exit 0

# Pattern: common human-intent markers (case-insensitive)
MARKERS='NOTE.*(by human|manual|intentional)|HACK|DO NOT (CHANGE|MODIFY|REMOVE|TOUCH)|IMPORTANT:.*keep|DELIBERATELY|INTENTIONALLY'

# Check if the file has any human markers
MATCHES=$(grep -inE "$MARKERS" "$FILE_PATH" 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
  # Count how many markers
  COUNT=$(echo "$MATCHES" | wc -l | tr -d ' ')

  # Format warning — goes to stderr so it appears in the hook output
  gum_warn "HUMAN-COMMENTED VALUES DETECTED in $(basename "$FILE_PATH")"
  gum_warn "   Found $COUNT marker(s):"
  echo "$MATCHES" | head -5 | while read -r line; do
    gum_warn "   → $line"
  done
  if [ "$COUNT" -gt 5 ]; then
    gum_warn "   ... and $((COUNT - 5)) more"
  fi
  gum_warn "   Rule: Ask before overriding. Verify after changing."
fi

# Always exit 0 — this is a warning, not a blocker
exit 0

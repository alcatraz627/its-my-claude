#!/usr/bin/env bash
# track-edits-session.sh — PostToolUse[Write|Edit|MultiEdit], side-effect only.
#
# Records every file I edit this session into a session-scoped list so the Stop
# review gate can lint exactly the files I touched. Distinct from edit-tracker.sh
# (which keeps only a 30s window for self-edit filtering) — this list must live
# for the whole session, because "done" can come long after the edit.
set -uo pipefail

input=$(cat 2>/dev/null) || exit 0
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$fp" ] && [ -n "$sid" ] || exit 0

F="/tmp/claude-edited-files-${sid:0:8}"
# Append once; exact-line fixed-string dedup keeps the list small.
if [ ! -f "$F" ] || ! grep -qxF "$fp" "$F" 2>/dev/null; then
  printf '%s\n' "$fp" >> "$F"
fi
exit 0

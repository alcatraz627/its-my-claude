#!/usr/bin/env bash
# block-nested-claude.sh — reject tool calls that would create .claude/.claude/ nesting.
#
# Root cause this prevents:
#   When CWD is ~/.claude itself, a relative path like ".claude/output/..." resolves to
#   ~/.claude/.claude/output/... — NOT to ~/.claude/output. This has happened repeatedly
#   because skill templates (e.g. create-report) assume CWD is a project root with a
#   .claude/ subdirectory.
#
# Correct behavior when CWD is ~/.claude:
#   - Reports  -> ~/.claude/assets/reports/
#   - Scripts  -> ~/.claude/scripts/
#   - Skills   -> ~/.claude/skills/
#   - Scratch  -> ~/.claude/scratchpad/
#
# This hook reads tool_input JSON from stdin and blocks if any file path or command
# string contains "/.claude/.claude/" (the literal nested pattern).

set -uo pipefail

input=$(cat)

# Check Write/Edit file_path
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# Check Bash command
command_str=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Check NotebookEdit / MultiEdit notebook_path
notebook_path=$(echo "$input" | jq -r '.tool_input.notebook_path // empty' 2>/dev/null)

haystack="$file_path $command_str $notebook_path"

if echo "$haystack" | grep -q '/\.claude/\.claude/'; then
  cat >&2 <<EOF
BLOCKED: .claude/.claude/ nesting detected.

Offending path/command:
  $haystack

This happens when you run a relative path like ".claude/output/..." while CWD is
already ~/.claude — it resolves to ~/.claude/.claude/output/... (double-nested).

Correct targets when working inside ~/.claude:
  - Reports -> ~/.claude/assets/reports/
  - Scripts -> ~/.claude/scripts/
  - Skills  -> ~/.claude/skills/
  - Scratch -> ~/.claude/scratchpad/

Use absolute paths (/Users/.../.claude/assets/reports/...) or resolve the intended
location explicitly before calling the tool.
EOF
  exit 2
fi

exit 0

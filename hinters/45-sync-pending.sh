#!/usr/bin/env bash
# UserPromptSubmit hinter. If /tmp/claude-todo-pending-<sid>.json exists,
# emit a one-line hint asking Claude to seed the pending todos via TaskCreate,
# then unlink the file. Latency budget <100ms.

set -uo pipefail

[ -f "$HOME/.claude/sync-disabled" ] && exit 0
[ -f "$HOME/.claude/scripts/sync-todos/.hinter-off" ] && exit 0

PROMPT=$(cat 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

SID="${CLAUDE_SESSION_ID:-}"
[ -z "$SID" ] && [ -f "$HOME/.claude/.current-session-id" ] && \
  SID=$(cat "$HOME/.claude/.current-session-id" 2>/dev/null)
[ -z "$SID" ] && exit 0

CLEAN=$(printf '%s' "$SID" | tr -c 'A-Za-z0-9_-' '_')
PENDING="/tmp/claude-todo-pending-${CLEAN}.json"
[ -f "$PENDING" ] || exit 0

COUNT=$(jq -r '.unchecked_todos | length' "$PENDING" 2>/dev/null || echo 0)
[ "$COUNT" -gt 0 ] || { rm -f "$PENDING"; exit 0; }

# Emit hint with first 3 todos as preview.
PREVIEW=$(jq -r '.unchecked_todos[:3] | .[]' "$PENDING" 2>/dev/null | sed 's/^/  - /')
printf '[sync-todos] %d workspace todo(s) carried over — seed them into your task list via TaskCreate at the start of your response, then delete %s:\n%s\n' \
  "$COUNT" "$PENDING" "$PREVIEW"

#!/bin/bash
# Agent CLI for the kanban board — thin launcher; all logic lives in cli.ts.
# See: bash ~/.claude/scripts/kanban/kanban.sh help
BUN="$(command -v bun)" || { echo "kanban: bun not installed — fix: brew install oven-sh/bun/bun" >&2; exit 1; }
exec "$BUN" "$(dirname "${BASH_SOURCE[0]}")/cli.ts" "$@"

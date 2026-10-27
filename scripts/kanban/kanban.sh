#!/bin/bash
# Agent CLI for the kanban board: thin launcher; all logic lives in cli.ts.
# See: bash ~/.claude/scripts/kanban/kanban.sh help
#
# Mothballed (owner, 2026-10-14: "we may come back to it in the future, it is
# good visually and functionally it was the usage where it dropped"): while
# ~/.claude/kanban/.mothballed exists, only read verbs run. The freeze used to be
# text only, and an agent created a board through it on 2026-10-06.
KROOT="${KANBAN_ROOT:-$HOME/.claude/kanban}"
if [ -f "$KROOT/.mothballed" ] && [ "${KANBAN_UNFREEZE:-0}" != "1" ]; then
  case "${1:-help}" in
    help|--help|-h|status|show|owed|selected|changed|brief|check|open|view) ;;
    decide) [ "${2:-}" = "list" ] || { echo "kanban: the board is mothballed (owner, 2026-10-14); only 'decide list' and read verbs run. Override for an owner-asked change: KANBAN_UNFREEZE=1" >&2; exit 3; } ;;
    *) echo "kanban: the board is mothballed (owner, 2026-10-14); '$1' would write to it, so it is refused. Read verbs still work (status, show, owed, selected, changed, brief, check, open, view, decide list). Override only when the owner asked for this change: KANBAN_UNFREEZE=1" >&2
       exit 3 ;;
  esac
fi
BUN="$(command -v bun)" || { echo "kanban: bun not installed: fix: brew install oven-sh/bun/bun" >&2; exit 1; }
exec "$BUN" "$(dirname "${BASH_SOURCE[0]}")/cli.ts" "$@"

#!/usr/bin/env bash
# shell-mem.sh — Dispatcher for the shell-command tracking subsystem.
#
# Subcommands map to scripts under ~/.claude/scripts/shell-mem/. Each
# subcommand delegates to the original script (which still works
# standalone for back-compat). Centralizes naming and exposes a single
# `--help` surface.
#
# Renamed 2026-05-17 from diy-mem (see migration 0014).
#
# Usage:
#   shell-mem.sh <subcommand> [args]
#   shell-mem.sh --help
#
# Subcommands (hook callers):
#   init-session         — SessionStart: register session in shell-logs
#   track-bash           — PostToolUse[Bash]: record command intent
#   mark-done-bash       — PostToolUse[BashOutput]: record completion
#   pre-compact-shell    — PreCompact: snapshot active shell state
#   session-end-shell    — Stop: finalize session log
#   inject-shell-state   — UserPromptSubmit: inject recent context
#
# Subcommands (utilities):
#   shell-log-active     — list active background commands
#   shell-log-append     — append a log entry
#   shell-log-cleanup    — prune old log entries
#   shell-log-file       — print today's log file path
#   shell-log-mark-done  — mark a tracked command done
#   shell-log-search     — search across logs
#   shell-log-tail       — tail recent entries
#
# Help: shell-mem.sh <subcommand> --help (delegated to underlying script)

set -uo pipefail

DIR="$HOME/.claude/scripts/shell-mem"
SUBCOMMAND="${1:-}"

if [[ -z "$SUBCOMMAND" || "$SUBCOMMAND" == "--help" || "$SUBCOMMAND" == "-h" ]]; then
  sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
  exit 0
fi

shift  # remove subcommand from args
TARGET="$DIR/$SUBCOMMAND.sh"

if [[ ! -f "$TARGET" ]]; then
  printf 'shell-mem: unknown subcommand: %s\n' "$SUBCOMMAND" >&2
  printf 'Run `shell-mem.sh --help` for the list.\n' >&2
  exit 2
fi

exec bash "$TARGET" "$@"

#!/usr/bin/env bash
# std::claude::startup — Login-time maintenance orchestrator.
#
# Fires once per user-login session via the LaunchAgent at
# ~/Library/LaunchAgents/dev.claude-startup.plist (RunAtLoad=true).
# On this single-user macOS box the user restarts ~weekly without logging
# out, so "per login" effectively means "per reboot" — which is the right
# cadence for the maintenance tasks below.
#
# Each task is a separate script under tasks/<name>.sh. Tasks must:
#   - accept --dry-run (no side effects, but print the same stats)
#   - print a one-line summary on completion (used by this orchestrator)
#   - include a `# REVIVAL:` comment block at top explaining how to undo
#
# Usage:
#   bash ~/.claude/scripts/startup/run.sh             # run all tasks
#   bash ~/.claude/scripts/startup/run.sh --dry-run   # show what would happen
#   bash ~/.claude/scripts/startup/run.sh --task NAME # run one task by name
#   bash ~/.claude/scripts/startup/run.sh --list      # list tasks
#
# Log: ~/.claude/logs/startup.log (appended)

set -uo pipefail

LOG="${HOME}/.claude/logs/startup.log"
mkdir -p "${LOG%/*}"

TASKS_DIR="${BASH_SOURCE%/*}/tasks"
DRY_RUN=0
ONLY_TASK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --task)    ONLY_TASK="${2:-}"; shift ;;
    --list)
      printf 'Available tasks:\n'
      for f in "$TASKS_DIR"/*.sh; do
        printf '  - %s\n' "$(basename "${f%.sh}")"
      done
      exit 0
      ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

started=$(date "+%Y-%m-%d %H:%M:%S")
{
  printf '\n=== std::claude::startup @ %s ===\n' "$started"
  printf 'dry_run=%d only_task=%q\n' "$DRY_RUN" "$ONLY_TASK"
} | tee -a "$LOG"

run_task() {
  local task_file="$1"
  local name; name=$(basename "${task_file%.sh}")
  if [[ -n "$ONLY_TASK" && "$name" != "$ONLY_TASK" ]]; then
    return 0
  fi
  printf '\n--- task: %s ---\n' "$name" | tee -a "$LOG"
  local args=()
  (( DRY_RUN )) && args+=(--dry-run)
  if bash "$task_file" "${args[@]}" 2>&1 | tee -a "$LOG"; then
    printf '[OK]  %s\n' "$name" | tee -a "$LOG"
  else
    printf '[FAIL] %s (exit non-zero — see log above)\n' "$name" | tee -a "$LOG"
  fi
}

# Run all tasks in lexical order. Numeric prefixes (10-, 20-, 30-) control order.
shopt -s nullglob
for task_file in "$TASKS_DIR"/*.sh; do
  run_task "$task_file"
done

finished=$(date "+%Y-%m-%d %H:%M:%S")
printf '\n=== finished @ %s ===\n' "$finished" | tee -a "$LOG"

#!/usr/bin/env bash
# hook-orchestrator/run.sh — Parallel orchestrator for fanned-out hook events.
#
# Replaces N settings.json blocks for one event with ONE block that forks
# all registered tasks in parallel. Preserves the per-task parallelism
# Claude Code's hook system already provides — net cost is ONE extra parent
# process (~5–10 ms) per event firing.
#
# Reads task list from: ~/.claude/scripts/hook-orchestrator/<event>.tasks
# Format: one shell command per line. Lines starting with # are comments.
# Blank lines are ignored.
#
# Each task receives the SAME stdin (the hook input JSON) via `tee` fan-out.
# Each task runs with a timeout (TASK_TIMEOUT). Failures are logged and
# swallowed — orchestrator always exits 0 within ORCHESTRATOR_TIMEOUT.
#
# Usage (settings.json):
#   "command": "~/.claude/scripts/hook-orchestrator/run.sh SessionStart"
#
# Log: ~/.claude/logs/hook-orchestrator.log
# Mute single task: prefix its line with `# DISABLED ` in the .tasks file

set -uo pipefail

EVENT="${1:-}"
[[ -n "$EVENT" ]] || { printf 'usage: %s <event-name>\n' "$0" >&2; exit 2; }

CFG="$HOME/.claude/scripts/hook-orchestrator/${EVENT}.tasks"
LOG="$HOME/.claude/logs/hook-orchestrator.log"
TASK_TIMEOUT="${HOOK_ORCH_TASK_TIMEOUT:-30}"          # per-task seconds
ORCH_TIMEOUT="${HOOK_ORCH_TOTAL_TIMEOUT:-60}"          # whole orchestrator

mkdir -p "$(dirname "$LOG")"

[[ -f "$CFG" ]] || { echo "[orch] no tasks file for $EVENT; exiting" >> "$LOG"; exit 0; }

# Buffer stdin once, fan out to each task.
INPUT=$(cat)
START_TS=$(date "+%Y-%m-%d %H:%M:%S")

# Read non-comment, non-blank lines as task commands.
TASKS=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  TASKS+=("$line")
done < "$CFG"

(( ${#TASKS[@]} == 0 )) && { echo "[orch] $EVENT — no enabled tasks" >> "$LOG"; exit 0; }

# Fork each task with stdin = $INPUT and bounded timeout.
PIDS=()
NAMES=()
for cmd in "${TASKS[@]}"; do
  name=$(printf '%s' "$cmd" | sed 's|.*scripts/||;s| .*||' | head -c 40)
  NAMES+=("$name")
  if command -v timeout >/dev/null 2>&1; then
    ( printf '%s' "$INPUT" | timeout "$TASK_TIMEOUT" bash -c "$cmd" ) >/dev/null 2>&1 &
  elif command -v gtimeout >/dev/null 2>&1; then
    ( printf '%s' "$INPUT" | gtimeout "$TASK_TIMEOUT" bash -c "$cmd" ) >/dev/null 2>&1 &
  else
    ( printf '%s' "$INPUT" | bash -c "$cmd" ) >/dev/null 2>&1 &
  fi
  PIDS+=($!)
done

# Wait for all, with a wall-clock cap. Detached wait via background watcher.
(
  sleep "$ORCH_TIMEOUT"
  for pid in "${PIDS[@]}"; do
    kill -9 "$pid" 2>/dev/null || true
  done
) >/dev/null 2>&1 &
WATCHER=$!
disown "$WATCHER" 2>/dev/null || true

# Wait for each task individually, collect exit codes.
RESULTS=()
for i in "${!PIDS[@]}"; do
  wait "${PIDS[$i]}" 2>/dev/null
  RESULTS+=($?)
done

# Cancel watcher — all done.
{ kill -9 "$WATCHER" 2>/dev/null; wait "$WATCHER" 2>/dev/null; } >/dev/null 2>&1 || true

# Log a compact summary line.
ok=0; fail=0; for rc in "${RESULTS[@]}"; do (( rc == 0 )) && ok=$((ok+1)) || fail=$((fail+1)); done
echo "[orch] $START_TS $EVENT: ok=$ok fail=$fail tasks=${#TASKS[@]}" >> "$LOG"
if (( fail > 0 )); then
  for i in "${!RESULTS[@]}"; do
    (( ${RESULTS[$i]} != 0 )) && echo "[orch]   FAIL ${NAMES[$i]} (rc=${RESULTS[$i]})" >> "$LOG"
  done
fi

exit 0

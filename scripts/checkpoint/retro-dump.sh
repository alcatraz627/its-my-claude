#!/usr/bin/env bash
# scripts/checkpoint/retro-dump.sh — Run /core-dump retroactively on ONE session.
#
# Spawns: claude -p --resume <uuid> --no-session-persistence
#         "/core-dump mini --no-prompt --name retroactive-<uuid8>"
#
# The --no-session-persistence flag prevents the retro run from creating a NEW
# transcript entry. The mini mode keeps cost bounded — we just want a structured
# summary, not a deep analysis.
#
# Usage:
#   retro-dump.sh --uuid UUID                 # run on a specific uuid
#   retro-dump.sh --queue                     # process the queue (--max-per-run cap)
#
# Args:
#   --max-per-run N         default 3 (per invocation; total budget cap)
#   --timeout-seconds N     default 120 (kill stuck retro-dumps)

set -uo pipefail

UUID=""
QUEUE_MODE=0
MAX_PER_RUN=3
TIMEOUT_S=120

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uuid)            UUID="$2"; shift ;;
    --queue)           QUEUE_MODE=1 ;;
    --max-per-run)     MAX_PER_RUN="$2"; shift ;;
    --timeout-seconds) TIMEOUT_S="$2"; shift ;;
  esac
  shift
done

CLAUDE_BIN="${CLAUDE_BIN:-claude}"
QUEUE_DIR="${HOME}/.claude/checkpoints/retro-queue"
LOG="${HOME}/.claude/logs/retro-dump.log"
mkdir -p "$(dirname "$LOG")" "$QUEUE_DIR"

run_one() {
  local uuid="$1" queue_file="$2"
  local short="${uuid:0:8}"
  local start_ts; start_ts=$(date "+%Y-%m-%dT%H:%M:%SZ")
  printf '[%s] start retro-dump %s\n' "$start_ts" "$uuid" >> "$LOG"

  # Run with timeout to bound cost.
  local cmd=(
    "$CLAUDE_BIN"
    -p
    --resume "$uuid"
    --no-session-persistence
    "/core-dump mini --no-prompt --name retroactive-$short"
  )

  if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT_S" "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$TIMEOUT_S" "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  else
    "${cmd[@]}" >> "$LOG" 2>&1
    rc=$?
  fi

  local end_ts; end_ts=$(date "+%Y-%m-%dT%H:%M:%SZ")
  printf '[%s] end retro-dump %s (rc=%d)\n' "$end_ts" "$uuid" "$rc" >> "$LOG"

  # Remove queue file regardless — if it failed, we don't keep retrying forever.
  # Add to a failed/ subdir for inspection.
  if [[ -n "$queue_file" && -f "$queue_file" ]]; then
    if (( rc == 0 )); then
      rm -f "$queue_file"
    else
      mkdir -p "$QUEUE_DIR/failed"
      mv "$queue_file" "$QUEUE_DIR/failed/$(basename "$queue_file").rc${rc}.$(date +%s)" 2>/dev/null || rm -f "$queue_file"
    fi
  fi

  return $rc
}

if (( QUEUE_MODE )); then
  count=0
  for qf in "$QUEUE_DIR"/*.queued; do
    [[ -f "$qf" ]] || continue
    (( count >= MAX_PER_RUN )) && break
    uuid=$(basename "$qf" | sed 's/\.queued$//')
    run_one "$uuid" "$qf"
    count=$((count + 1))
  done
  printf 'processed %d queued retro-dumps (cap=%d)\n' "$count" "$MAX_PER_RUN"
elif [[ -n "$UUID" ]]; then
  run_one "$UUID" ""
else
  printf 'usage: %s --uuid UUID  |  %s --queue\n' "$0" "$0" >&2
  exit 2
fi

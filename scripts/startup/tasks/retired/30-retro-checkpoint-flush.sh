#!/usr/bin/env bash
# 30-retro-checkpoint-flush.sh — std::claude::startup task.
#
# Sweeps the retro-dump queue at login time. Also does a broad rescan to catch
# long-tail sessions that SessionStart hook never saw (because the user hasn't
# revisited the project).
#
# REVIVAL:
#   This task is opt-in via env var. To disable: set DISABLE_RETRO_FLUSH=1 in
#   settings.json env block. Failed retro-dumps are preserved in
#   ~/.claude/checkpoints/retro-queue/failed/ for manual inspection — they're
#   NOT auto-retried.
#
# Cost: each retro-dump is an LLM call. Capped at MAX_PER_RUN=3 by default.

set -uo pipefail

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
  esac
  shift
done

if [[ "${DISABLE_RETRO_FLUSH:-}" == "1" ]]; then
  echo "retro-flush: disabled via DISABLE_RETRO_FLUSH=1"
  exit 0
fi

QUEUE_DIR="${HOME}/.claude/checkpoints/retro-queue"

if (( DRY_RUN )); then
  # Dry-run: discover candidates WITHOUT enqueueing or executing.
  candidates=$("$HOME/.claude/scripts/checkpoint/retro-scan.sh" --print --min-turns 5 --max-age-days 7 --limit 20 2>&1 | grep -c '^{' || true)
  queued=$(find "$QUEUE_DIR" -maxdepth 1 -name '*.queued' -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "retro-flush (dry-run): $candidates new candidates discoverable, $queued already in queue, would process up to 3"
  exit 0
fi

# Live: enqueue + drain
"$HOME/.claude/scripts/checkpoint/retro-scan.sh" --enqueue --min-turns 5 --max-age-days 7 --limit 20 2>&1 | tail -1

queued=$(find "$QUEUE_DIR" -maxdepth 1 -name '*.queued' -type f 2>/dev/null | wc -l | tr -d ' ')

if (( queued == 0 )); then
  echo "retro-flush: nothing queued"
  exit 0
fi

"$HOME/.claude/scripts/checkpoint/retro-dump.sh" --queue --max-per-run 3 2>&1 | tail -1

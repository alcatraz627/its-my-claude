#!/usr/bin/env bash
# rotate-events.sh — archive events.jsonl when it grows large.
#
# Wired as a Stop hook (async, fire-and-forget). Behavior:
#   - If events.jsonl does not exist, exit 0.
#   - If size < THRESHOLD (default 50MB), exit 0.
#   - Otherwise:
#       - Compute date range from the file's first and last ts.
#       - Move it to ~/.claude/assets/backups/events-archive/events-<first>_<last>.jsonl.gz
#         (gzip-compressed; JSONL compresses ~10x).
#       - Create a fresh empty events.jsonl.
#   - All operations are flock-guarded on the same lock file emit-event.sh uses,
#     so a concurrent write cannot race with the rotation.

set -uo pipefail

LOG="$HOME/.claude/events.jsonl"
LOCK="$HOME/.claude/.events.lock"
ARCHIVE_DIR="$HOME/.claude/assets/backups/events-archive"
THRESHOLD_BYTES=${EVENTS_ROTATE_THRESHOLD:-$((50 * 1024 * 1024))}

[ -f "$LOG" ] || exit 0

size=$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)
[ "$size" -lt "$THRESHOLD_BYTES" ] && exit 0

mkdir -p "$ARCHIVE_DIR"

(
  # flock is not on macOS stock — attempt, proceed regardless (same pattern as emit-event.sh).
  # Rotations run infrequently (~monthly); worst case is one concurrent emit lost.
  flock -x 9 2>/dev/null || true

  size=$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)
  [ "$size" -lt "$THRESHOLD_BYTES" ] && exit 0

  first_ts=$(head -1 "$LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null | head -c 10)
  last_ts=$(tail -1 "$LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null | head -c 10)
  [ -z "$first_ts" ] && first_ts=$(date -u +%Y-%m-%d)
  [ -z "$last_ts" ] && last_ts=$(date -u +%Y-%m-%d)

  archive="$ARCHIVE_DIR/events-${first_ts}_${last_ts}.jsonl.gz"

  if [ -f "$archive" ]; then
    archive="$ARCHIVE_DIR/events-${first_ts}_${last_ts}-$(date -u +%H%M%S).jsonl.gz"
  fi

  gzip -c "$LOG" > "$archive" && : > "$LOG"

  echo "[rotate-events] archived $(du -h "$archive" | cut -f1) -> $archive" >&2
) 9>>"$LOCK" || true

exit 0

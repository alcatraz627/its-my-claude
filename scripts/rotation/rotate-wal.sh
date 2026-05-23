#!/usr/bin/env bash
# rotate-wal.sh — archive wal.jsonl when it grows large.
#
# Wired as a Stop hook (async, fire-and-forget). Behavior mirrors rotate-events.sh:
#   - Rotates BOTH the global ~/.claude/wal.jsonl AND any project-local .claude/wal.jsonl
#     discovered from the session's CWD (the Stop hook receives the CWD in its JSON input).
#   - If size < THRESHOLD (default 5MB — WAL is smaller than events by nature), exit 0.
#   - Otherwise:
#       - Compute date range from first/last ts.
#       - Move to ~/.claude/assets/backups/wal-archive/wal-<project>-<first>_<last>.jsonl.gz
#       - Create a fresh empty wal.jsonl.
#   - flock-guarded with graceful degradation (macOS has no stock flock).
#
# Threshold override: WAL_ROTATE_THRESHOLD=<bytes>.

set -uo pipefail

ARCHIVE_DIR="$HOME/.claude/assets/backups/wal-archive"
THRESHOLD_BYTES=${WAL_ROTATE_THRESHOLD:-$((5 * 1024 * 1024))}

# Parse Stop-hook JSON from stdin to get the CWD (may be empty when run standalone).
STDIN_JSON=""
if [ -t 0 ]; then
  STDIN_JSON=""
else
  STDIN_JSON=$(cat || true)
fi

SESSION_CWD=""
if [ -n "$STDIN_JSON" ]; then
  SESSION_CWD=$(echo "$STDIN_JSON" | jq -r '.cwd // empty' 2>/dev/null)
fi

mkdir -p "$ARCHIVE_DIR"

rotate_one() {
  local LOG="$1"
  local LABEL="$2"   # short label used in archive filename, e.g. "global" or project dirname

  [ -f "$LOG" ] || return 0

  local size
  size=$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)
  [ "$size" -lt "$THRESHOLD_BYTES" ] && return 0

  local LOCK="${LOG}.lock"

  (
    flock -x 9 2>/dev/null || true

    size=$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)
    [ "$size" -lt "$THRESHOLD_BYTES" ] && exit 0

    local first_ts last_ts archive
    first_ts=$(head -1 "$LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null | head -c 10)
    last_ts=$(tail -1 "$LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null | head -c 10)
    [ -z "$first_ts" ] && first_ts=$(date -u +%Y-%m-%d)
    [ -z "$last_ts" ] && last_ts=$(date -u +%Y-%m-%d)

    archive="$ARCHIVE_DIR/wal-${LABEL}-${first_ts}_${last_ts}.jsonl.gz"
    if [ -f "$archive" ]; then
      archive="$ARCHIVE_DIR/wal-${LABEL}-${first_ts}_${last_ts}-$(date -u +%H%M%S).jsonl.gz"
    fi

    gzip -c "$LOG" > "$archive" && : > "$LOG"
    echo "[rotate-wal] archived $(du -h "$archive" | cut -f1) -> $archive" >&2
  ) 9>>"$LOCK" || true
}

# Always try global WAL
rotate_one "$HOME/.claude/wal.jsonl" "global"

# If we have a CWD and it has a .claude/wal.jsonl, rotate that too
if [ -n "$SESSION_CWD" ] && [ -f "$SESSION_CWD/.claude/wal.jsonl" ]; then
  PROJECT_LABEL=$(basename "$SESSION_CWD" | tr -c 'a-zA-Z0-9_-' '_' | head -c 40)
  rotate_one "$SESSION_CWD/.claude/wal.jsonl" "$PROJECT_LABEL"
fi

exit 0

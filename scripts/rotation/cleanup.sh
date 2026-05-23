#!/usr/bin/env bash
# cleanup.sh — periodic housekeeping for ~/.claude/
#
# Usage: bash ~/.claude/scripts/rotation/cleanup.sh
#
# Tasks:
#   1. Expire tool-timer files older than 1 hour
#   2. (Add future cleanup tasks below)
#
# Safe to run at any time (idempotent). Uses `trash` (macOS) for deletions.
# Cron example (every hour):
#   0 * * * * bash /Users/alcatraz627/.claude/scripts/rotation/cleanup.sh >> /tmp/claude-cleanup.log 2>&1

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
DRY_RUN="${CLEANUP_DRY_RUN:-false}"

log() {
    echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"
}

expire_file() {
    local f="$1"
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN: would trash $f"
    else
        trash "$f" && log "Trashed: $f" || log "WARN: could not trash $f"
    fi
}

# --- 1. Expire tool-timer files older than 1 hour ---
log "Scanning for stale timer files (>60 min old)..."

timer_count=0
while IFS= read -r -d '' f; do
    expire_file "$f"
    timer_count=$((timer_count + 1))
done < <(find "$CLAUDE_DIR" -maxdepth 2 -name "*.timer" -mmin +60 -print0 2>/dev/null)

while IFS= read -r -d '' f; do
    expire_file "$f"
    timer_count=$((timer_count + 1))
done < <(find "$CLAUDE_DIR" -maxdepth 2 -name "tool-timer-*" -mmin +60 -print0 2>/dev/null)

if [[ $timer_count -eq 0 ]]; then
    log "No stale timer files found."
else
    log "Expired $timer_count timer file(s)."
fi

# --- 2. Future cleanup tasks can be added here ---

log "cleanup.sh complete."

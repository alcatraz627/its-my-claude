#!/usr/bin/env bash
# prune-backups.sh — trash backup files older than N days.
#
# Scope:
#   ~/.claude/assets/backups/     (Phase 1+2 settings backups, older upgrade artifacts)
#   ~/.claude/assets/backups/events-archive/  (rotated events.jsonl)
#   ~/.claude/assets/backups/wal-archive/     (rotated wal.jsonl)
#
# Default retention: 180 days. Override with BACKUP_RETENTION_DAYS env.
#
# Modes:
#   --preview, -n    Show what would be pruned, do not delete. Also the /doctor mode.
#   --apply          Actually move to Trash.
#   (no flag)        Same as --preview.
#
# Uses `trash` (macOS) so recoverable from Finder.

set -uo pipefail

RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-180}
BACKUPS_DIR="$HOME/.claude/assets/backups"
MODE="preview"

while [ $# -gt 0 ]; do
  case "$1" in
    --preview|-n) MODE="preview"; shift ;;
    --apply) MODE="apply"; shift ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0 ;;
    *) shift ;;
  esac
done

if [ ! -d "$BACKUPS_DIR" ]; then
  echo "[prune-backups] no backups dir at $BACKUPS_DIR"
  exit 0
fi

# Find candidates — files and top-level dated directories (e.g. 20260417-phase12-upgrade/)
# older than RETENTION_DAYS.
candidates=$(find "$BACKUPS_DIR" -mindepth 1 -maxdepth 2 -mtime +"$RETENTION_DAYS" \
             \( -type f -o -type d \) 2>/dev/null | sort)

count=$(echo -n "$candidates" | grep -c . || true)
total_size=0

if [ "$count" -eq 0 ]; then
  echo "[prune-backups] nothing older than ${RETENTION_DAYS} days"
  exit 0
fi

echo "[prune-backups] retention=${RETENTION_DAYS}d  mode=${MODE}"
echo

while IFS= read -r item; do
  [ -z "$item" ] && continue
  size=$(du -sh "$item" 2>/dev/null | cut -f1)
  age_days=$(( ( $(date +%s) - $(stat -f%m "$item" 2>/dev/null || stat -c%Y "$item" 2>/dev/null || echo 0) ) / 86400 ))
  rel="${item#$BACKUPS_DIR/}"
  printf "  %4dd  %6s  %s\n" "$age_days" "$size" "$rel"
done <<< "$candidates"

echo
if [ "$MODE" = "preview" ]; then
  echo "[prune-backups] preview only. Re-run with --apply to move $count item(s) to Trash."
  exit 0
fi

# Apply mode
moved=0
while IFS= read -r item; do
  [ -z "$item" ] && continue
  if trash "$item" 2>/dev/null; then
    moved=$((moved + 1))
  fi
done <<< "$candidates"

echo "[prune-backups] moved $moved/$count item(s) to Trash"

#!/usr/bin/env bash
# atone-snapshot.sh — daily backup of ~/.claude/atone/.
#
# Uses rsync --link-dest to hardlink unchanged files against yesterday's
# snapshot, so storage cost ≈ delta size, not full-copy. With atone's
# append-only data, a year of dailies ≈ a few MB total instead of GBs.
#
# Retention tiers (Grandfather-Father-Son):
#   - Daily: 30 days
#   - Weekly (Sunday): 12 weeks → _weekly/
#   - Monthly (1st):   FOREVER → _monthly/
#   - Anything rotating out of daily/weekly goes to _archive/ (compressed
#     after 7 days, never auto-deleted)
#
# Snapshot files get chflags uappnd. macOS file flags are per-inode and so
# propagate across hardlinks automatically — every snapshot stays protected
# without re-flagging.
#
# Invoked by: ~/Library/LaunchAgents/com.alcatraz.atone-snapshot.plist (daily 03:00 IST)
# Manual run: bash ~/.claude/scripts/atone-snapshot.sh

set -euo pipefail

SRC="$HOME/.claude/atone"
DST_ROOT="$HOME/.claude/atone-snapshots"
LOG="$DST_ROOT/_log.txt"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)
DST="$DST_ROOT/$TODAY"

mkdir -p "$DST_ROOT" "$DST_ROOT/_archive" "$DST_ROOT/_weekly" "$DST_ROOT/_monthly"
touch "$LOG"

# Bail if source is empty (pre-migration)
if [ ! -d "$SRC" ] || [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
  echo "$(date -Iseconds) snapshot skipped: source empty" >> "$LOG"
  exit 0
fi

# Daily snapshot
if [ -d "$DST_ROOT/$YESTERDAY" ]; then
  rsync -a --delete --link-dest="$DST_ROOT/$YESTERDAY" "$SRC/" "$DST/"
else
  rsync -a --delete "$SRC/" "$DST/"
fi

# Apply append-only flag (no-op on already-flagged inodes from hardlinks)
find "$DST" -type f -exec chflags uappnd {} \; 2>/dev/null || true

# Promote to weekly tier (Sundays — date +%u == 7)
if [ "$(date +%u)" = "7" ]; then
  if [ ! -e "$DST_ROOT/_weekly/$TODAY" ]; then
    cp -al "$DST" "$DST_ROOT/_weekly/$TODAY" 2>/dev/null || rsync -a --link-dest="$DST" "$DST/" "$DST_ROOT/_weekly/$TODAY/"
  fi
fi

# Promote to monthly tier (1st of month)
if [ "$(date +%d)" = "01" ]; then
  if [ ! -e "$DST_ROOT/_monthly/$TODAY" ]; then
    cp -al "$DST" "$DST_ROOT/_monthly/$TODAY" 2>/dev/null || rsync -a --link-dest="$DST" "$DST/" "$DST_ROOT/_monthly/$TODAY/"
  fi
fi

# Rotate daily tier (> 30 days → _archive/)
find "$DST_ROOT" -maxdepth 1 -type d -name '20*' -mtime +30 -exec mv {} "$DST_ROOT/_archive/" \; 2>/dev/null || true

# Rotate weekly tier (> 84 days → _archive/)
find "$DST_ROOT/_weekly" -maxdepth 1 -type d -name '20*' -mtime +84 -exec mv {} "$DST_ROOT/_archive/" \; 2>/dev/null || true

# Compress archive entries > 7 days old (hardlinks broken inside tar, but
# archive is the cold tier and per-entry compression saves real disk).
find "$DST_ROOT/_archive" -maxdepth 1 -type d -name '20*' -mtime +7 2>/dev/null | while read -r d; do
  base=$(basename "$d")
  parent=$(dirname "$d")
  tar -czf "$parent/$base.tar.gz" -C "$parent" "$base" && rm -rf "$d" 2>/dev/null || true
done

# Size trip-wire
SIZE_MB=$(du -sm "$DST_ROOT" 2>/dev/null | awk '{print $1}')
if [ -n "$SIZE_MB" ] && [ "$SIZE_MB" -gt 500 ]; then
  echo "$(date -Iseconds) WARN: atone-snapshots > 500MB ($SIZE_MB MB)" >> "$LOG"
fi

echo "$(date -Iseconds) snapshot ok: $DST (total: ${SIZE_MB:-?}MB)" >> "$LOG"

# Stale session-state cleanup: markers older than 24h are orphans (session ended,
# /clear changed CLAUDE_SESSION_ID, etc). Remove them so they don't pile up.
STATE_DIR="$HOME/.claude/atone/.session-state"
if [ -d "$STATE_DIR" ]; then
  find "$STATE_DIR" -type f -mtime +1 -delete 2>/dev/null || true
fi

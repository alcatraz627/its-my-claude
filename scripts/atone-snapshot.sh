#!/usr/bin/env bash
# atone-snapshot.sh — daily backup of ~/.claude/atone/.
#
# Each day starts as an APFS clone of the newest snapshot (copy-on-write, so
# unchanged files share their blocks and storage cost ≈ the day's changes), then
# rsync brings it up to date and every file is sealed again. Hardlinks were used
# before, but macOS refuses to hardlink a file carrying uappnd, so once a
# snapshot was sealed every later one silently became a full copy.
#
# Retention tiers (Grandfather-Father-Son):
#   - Daily: 30 days
#   - Weekly (Sunday): 12 weeks → _weekly/
#   - Monthly (1st):   FOREVER → _monthly/
#   - Anything rotating out of daily/weekly goes to _archive/ (never auto-deleted)
#
# Snapshot files get chflags uappnd. A clone is a new inode, so unsealing it to
# refresh it leaves the snapshot it came from sealed.
#
# Invoked by: the gcc scheduler job "atone-snapshot" (gcc-schedule show atone-snapshot)
# Manual run: bash ~/.claude/scripts/atone-snapshot.sh
# Test run:   ATONE_SNAPSHOT_SRC=<dir> ATONE_SNAPSHOT_ROOT=<dir> bash atone-snapshot.sh

set -euo pipefail

SRC="${ATONE_SNAPSHOT_SRC:-$HOME/.claude/atone}"
DST_ROOT="${ATONE_SNAPSHOT_ROOT:-$HOME/.claude/atone-snapshots}"
LOG="$DST_ROOT/_log.txt"
TODAY=$(date +%Y-%m-%d)
DST="$DST_ROOT/$TODAY"
# Newest earlier snapshot, so a skipped day or a long gap still dedupes against it.
PREV=$(ls -1 "$DST_ROOT" 2>/dev/null | rg '^20[0-9-]{8}$' | rg -v "^$TODAY\$" | sort | tail -1 || true)

mkdir -p "$DST_ROOT" "$DST_ROOT/_archive" "$DST_ROOT/_weekly" "$DST_ROOT/_monthly"
touch "$LOG"

# Bail if source is empty (pre-migration)
if [ ! -d "$SRC" ] || [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
  echo "$(date -Iseconds) snapshot skipped: source empty" >> "$LOG"
  exit 0
fi

# One snapshot per day. Today's files are already sealed append-only, so a second
# rsync into them fails halfway and leaves the run looking broken.
if [ -d "$DST" ]; then
  echo "$(date -Iseconds) snapshot skipped: $TODAY already taken" >> "$LOG"
  exit 0
fi

# Daily snapshot. The folder's own .git is left out (and dropped from a clone that
# still has it): it is already a history, and at 326 MB it was nearly all of each copy.
if [ -n "$PREV" ] && [ -d "$DST_ROOT/$PREV" ]; then
  cp -cR "$DST_ROOT/$PREV" "$DST" 2>/dev/null || true
fi
[ -d "$DST" ] && chflags -R nouappnd "$DST" 2>/dev/null
rsync -a --delete --delete-excluded --exclude=.git "$SRC/" "$DST/"

# Apply append-only flag (no-op on already-flagged inodes from hardlinks)
find "$DST" -type f -exec chflags uappnd {} \; 2>/dev/null || true

# Promote to weekly tier (Sundays — date +%u == 7)
if [ "$(date +%u)" = "7" ]; then
  if [ ! -e "$DST_ROOT/_weekly/$TODAY" ]; then
    cp -cR "$DST" "$DST_ROOT/_weekly/$TODAY" 2>/dev/null || rsync -a "$DST/" "$DST_ROOT/_weekly/$TODAY/"
  fi
fi

# Promote to monthly tier (1st of month)
if [ "$(date +%d)" = "01" ]; then
  if [ ! -e "$DST_ROOT/_monthly/$TODAY" ]; then
    cp -cR "$DST" "$DST_ROOT/_monthly/$TODAY" 2>/dev/null || rsync -a "$DST/" "$DST_ROOT/_monthly/$TODAY/"
  fi
fi

# Rotate daily tier (> 30 days → _archive/)
find "$DST_ROOT" -maxdepth 1 -type d -name '20*' -mtime +30 -exec mv {} "$DST_ROOT/_archive/" \; 2>/dev/null || true

# Rotate weekly tier (> 84 days → _archive/)
find "$DST_ROOT/_weekly" -maxdepth 1 -type d -name '20*' -mtime +84 -exec mv {} "$DST_ROOT/_archive/" \; 2>/dev/null || true

# The archive tier is left as plain hardlinked directories. It used to be tarred
# and then removed, but snapshot files carry uappnd, so the removal failed
# silently and every run re-tarred the same entries. Hardlinks keep the cost at
# the size of the changes, so there is nothing to win by compressing.

# Size trip-wire
SIZE_MB=$(du -sm "$DST_ROOT" 2>/dev/null | awk '{print $1}')
if [ -n "$SIZE_MB" ] && [ "$SIZE_MB" -gt 500 ]; then
  echo "$(date -Iseconds) WARN: atone-snapshots > 500MB ($SIZE_MB MB)" >> "$LOG"
fi

echo "$(date -Iseconds) snapshot ok: $DST (total: ${SIZE_MB:-?}MB)" >> "$LOG"

# Stale session-state cleanup: markers older than 24h are orphans (session ended,
# /clear changed CLAUDE_SESSION_ID, etc). Remove them so they don't pile up.
STATE_DIR="$SRC/.session-state"
if [ -d "$STATE_DIR" ]; then
  find "$STATE_DIR" -type f -mtime +1 -delete 2>/dev/null || true
fi

#!/usr/bin/env bash
# store-backup.sh — snapshot a task store before anything rewrites it.
#
# The migration plan had no backup directive at all, and its own losslessness
# check compared a copy against itself, so nothing in it could restore a store it
# damaged. This is the missing half: it produces the BEFORE that
# migration-check.py diffs the AFTER against, and it is the thing you restore
# from when the diff says the migration was wrong.
#
# It takes the same per-store lock task.sh writes under, so a snapshot is never
# caught halfway through somebody else's write. A lock it cannot take is a
# REFUSAL, not a warning: a torn backup is worse than none, because it looks like
# a backup.
#
# Usage:
#   store-backup.sh <sid8>            snapshot one store
#   store-backup.sh --all             snapshot every non-empty store
#   store-backup.sh <sid8> --out DIR  snapshot somewhere specific
#   store-backup.sh --list            what snapshots exist
#   store-backup.sh --restore <path> <sid8>   put one back
set -uo pipefail

TASKS="$HOME/.claude/tasks"
BACKUPS="$TASKS/.backups"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT=""; TARGET=""; ALL=0; LIST=0; RESTORE=""; RESTORE_SID=""

while [ $# -gt 0 ]; do case "$1" in
  --all) ALL=1; shift ;;
  --list) LIST=1; shift ;;
  --out) OUT="$2"; shift 2 ;;
  --restore) RESTORE="$2"; RESTORE_SID="${3:-}"; shift 3 ;;
  -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
  -*) { printf 'store-backup.sh: unknown flag %s\n' "$1"
        printf '  acceptable: --all --list --out --restore -h\n'; } >&2; exit 2 ;;
  *) TARGET="${1:0:8}"; shift ;;
esac; done

if [ "$LIST" = 1 ]; then
  [ -d "$BACKUPS" ] || { echo "no snapshots yet under $BACKUPS"; exit 0; }
  for d in "$BACKUPS"/*/; do
    [ -d "$d" ] || continue
    n=$(find "$d" -name '*.json' | wc -l | tr -d ' ')
    s=$(find "$d" -maxdepth 1 -type d -name 'session-*' | wc -l | tr -d ' ')
    printf '  %s   %s store(s), %s rows\n' "$(basename "$d")" "$s" "$n"
  done
  exit 0
fi

if [ -n "$RESTORE" ]; then
  [ -n "$RESTORE_SID" ] || { echo "store-backup.sh --restore <path> <sid8>: need the store to restore into" >&2; exit 2; }
  src="$RESTORE/session-$RESTORE_SID"
  [ -d "$src" ] || { echo "store-backup.sh: no session-$RESTORE_SID inside $RESTORE" >&2; exit 4; }
  dst="$TASKS/session-$RESTORE_SID"
  # The live store is moved aside rather than deleted. A restore that discards
  # the thing it is replacing gives you one shot at being right about which copy
  # was the good one.
  if [ -d "$dst" ]; then
    aside="$dst.superseded-$STAMP"
    mv "$dst" "$aside" || { echo "store-backup.sh: could not move the live store aside" >&2; exit 5; }
    echo "  live store moved aside: $aside"
  fi
  cp -Rf "$src" "$dst" || { echo "store-backup.sh: restore failed" >&2; exit 5; }
  echo "restored session-$RESTORE_SID from $RESTORE"
  echo "  rows: $(find "$dst" -name '*.json' | wc -l | tr -d ' ')"
  exit 0
fi

[ "$ALL" = 1 ] || [ -n "$TARGET" ] || { sed -n '2,25p' "$0"; exit 2; }

DEST="${OUT:-$BACKUPS/$STAMP}"
mkdir -p "$DEST" || { echo "store-backup.sh: cannot create $DEST" >&2; exit 5; }

snapshot_one() {  # snapshot_one <store dir>
  local d="$1" sid lock i=0
  sid=$(basename "$d")
  lock="$d/.task-sh.lock"
  # Same lock discipline as task.sh: mkdir is the atomic primitive, and 5s is the
  # same ceiling, so a snapshot cannot outwait a writer that has genuinely hung.
  while ! mkdir "$lock" 2>/dev/null; do
    i=$((i+1))
    [ "$i" -gt 50 ] && { echo "  REFUSED $sid: lock held >5s, a snapshot taken mid-write is not a backup" >&2; return 1; }
    sleep 0.1
  done
  cp -Rf "$d" "$DEST/$sid"
  local rc=$?
  rmdir "$lock" 2>/dev/null
  # Do not copy the lock itself into the snapshot: restoring it would leave a
  # store that every writer then waits 5s on before giving up.
  rmdir "$DEST/$sid/.task-sh.lock" 2>/dev/null
  [ "$rc" = 0 ] || { echo "  FAILED $sid: copy returned $rc" >&2; return 1; }
  printf '  %s  %s rows\n' "$sid" "$(find "$DEST/$sid" -name '*.json' | wc -l | tr -d ' ')"
}

fails=0
if [ "$ALL" = 1 ]; then
  for d in "$TASKS"/session-*/; do
    [ -d "$d" ] || continue
    [ -n "$(find "$d" -maxdepth 1 -name '*.json' -print -quit)" ] || continue
    snapshot_one "$d" || fails=$((fails+1))
  done
else
  d="$TASKS/session-$TARGET"
  [ -d "$d" ] || { echo "store-backup.sh: no store session-$TARGET" >&2; exit 4; }
  snapshot_one "$d" || fails=$((fails+1))
fi

echo "snapshot: $DEST"
if [ -n "$TARGET" ]; then
  echo
  echo "after the change, diff it:"
  echo "  python3 $HOME/.claude/scripts/task-table/migration-check.py \\"
  echo "    $DEST/session-$TARGET $TASKS/session-$TARGET --allow <fields the change declares>"
  echo "put it back:"
  echo "  bash $HOME/.claude/scripts/task-table/store-backup.sh --restore $DEST $TARGET"
fi
[ "$fails" = 0 ]

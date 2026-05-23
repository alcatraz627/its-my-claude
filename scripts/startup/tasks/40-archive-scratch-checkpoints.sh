#!/usr/bin/env bash
# 40-archive-scratch-checkpoints.sh — std::claude::startup task.
#
# Moves root-level _YYYYMMDD-*.claude.md scratch checkpoints older than
# RETAIN_DAYS into ~/.claude/assets/checkpoints/YYYYMM/. Preserves the
# active checkpoint files (symlinks + precompact + last-checkpoint).
#
# REVIVAL:
#   To restore an archived checkpoint to root:
#     mv ~/.claude/assets/checkpoints/YYYYMM/<name> ~/.claude/
#   Files keep their original names. The convention says they live at root
#   only while ACTIVE (current session's scratch). After 30 days, root
#   accumulation = noise; archival is reversible.
#
# Rationale (per conventions/scratch-files.md): "monthly archive to
# assets/checkpoints/YYYYMM/" — this task implements that.

set -uo pipefail

DRY_RUN=0
RETAIN_DAYS=30
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=1 ;;
    --retain-days) RETAIN_DAYS="$2"; shift ;;
  esac
  shift
done

cd "$HOME/.claude" || exit 1
ROOT="$HOME/.claude"
TARGET_BASE="$ROOT/assets/checkpoints"

moved=0
kept=0
for f in _2026*-*.claude.md; do
  [[ -f "$f" ]] || continue
  # Skip if newer than RETAIN_DAYS
  if [[ -z "$(find "$f" -mtime "+${RETAIN_DAYS}" 2>/dev/null)" ]]; then
    kept=$((kept + 1)); continue
  fi
  # Derive YYYYMM from filename prefix
  ym=$(echo "$f" | sed 's/^_\([0-9]\{6\}\).*/\1/')
  if [[ ! "$ym" =~ ^[0-9]{6}$ ]]; then
    kept=$((kept + 1)); continue
  fi
  target_dir="$TARGET_BASE/$ym"
  if (( DRY_RUN )); then
    echo "  would move: $f → $target_dir/"
    moved=$((moved + 1))
  else
    mkdir -p "$target_dir"
    /bin/mv -f "$f" "$target_dir/" && moved=$((moved + 1))
  fi
done

if (( DRY_RUN )); then
  printf 'would archive %d files older than %dd (keeping %d recent)\n' "$moved" "$RETAIN_DAYS" "$kept"
else
  printf 'archived %d files older than %dd to %s/YYYYMM/ (kept %d recent at root)\n' "$moved" "$RETAIN_DAYS" "$TARGET_BASE" "$kept"
fi

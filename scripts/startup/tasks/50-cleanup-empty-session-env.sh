#!/usr/bin/env bash
# 50-cleanup-empty-session-env.sh — std::claude::startup task.
#
# Removes EMPTY subdirs under ~/.claude/session-env/ older than RETAIN_DAYS.
# Uses `rmdir` (NOT `rm -r` or `trash`) — fails-safe on non-empty dirs.
#
# Why: Claude Code creates a session-env/<uuid>/ subdir per session for env
# snapshots but appears to never populate them (observed: 834/834 empty).
# Anthropic-managed dir per FOLDERS.md but this defensive cleanup is safe:
# rmdir refuses to delete any non-empty dir, so if Anthropic ever starts
# populating them, this task becomes a no-op.
#
# REVIVAL:
#   Restoration is unnecessary — empty subdirs are recreated by Claude Code
#   on next session start. If you NEED to confirm the dir existed for
#   audit/forensic reasons, check the Claude Code log directly.

set -uo pipefail

DRY_RUN=0
RETAIN_DAYS=7
DIR="${HOME}/.claude/session-env"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --retain-days) RETAIN_DAYS="$2"; shift ;;
  esac
  shift
done

[[ -d "$DIR" ]] || { echo "no session-env dir"; exit 0; }

removed=0
total_empty=0
while IFS= read -r d; do
  total_empty=$((total_empty + 1))
  # Only attempt if older than RETAIN_DAYS
  if [[ -z "$(find "$d" -maxdepth 0 -mtime "+${RETAIN_DAYS}" 2>/dev/null)" ]]; then
    continue
  fi
  if (( DRY_RUN )); then
    removed=$((removed + 1))
  else
    # rmdir fails-safe — refuses to delete non-empty dirs
    rmdir "$d" 2>/dev/null && removed=$((removed + 1))
  fi
done < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -empty 2>/dev/null)

if (( DRY_RUN )); then
  printf 'would rmdir %d empty session-env subdirs older than %dd (of %d empty)\n' "$removed" "$RETAIN_DAYS" "$total_empty"
else
  printf 'rmdir %d empty session-env subdirs older than %dd (of %d empty)\n' "$removed" "$RETAIN_DAYS" "$total_empty"
fi

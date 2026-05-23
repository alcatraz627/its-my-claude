#!/usr/bin/env bash
# review-scope.sh — list the files changed in the current work session.
#
# Union of two sources so nothing slips through:
#   1. git diff against HEAD (tracked changes) + untracked files, within the
#      CWD's repo;
#   2. the session edit-tracker (/tmp/claude-edited-files-<sid8>), which catches
#      work in non-git trees or before a commit.
# Prints absolute paths to existing files, one per line, deduped.
#
# Usage: review-scope.sh [<session-id-8>]

set -uo pipefail
sid8="${1:-}"
{
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    root=$(git rev-parse --show-toplevel)
    git -C "$root" diff --name-only HEAD 2>/dev/null | sed "s|^|$root/|"
    git -C "$root" ls-files --others --exclude-standard 2>/dev/null | sed "s|^|$root/|"
  fi
  [ -n "$sid8" ] && [ -f "/tmp/claude-edited-files-$sid8" ] && cat "/tmp/claude-edited-files-$sid8"
} 2>/dev/null | sort -u | while IFS= read -r f; do [ -n "$f" ] && [ -f "$f" ] && echo "$f"; done

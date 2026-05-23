#!/usr/bin/env bash
# review-marker.sh — tracks which changed code files /skeptical-review has
# covered this session, so the Stop gate can require a review only for the
# UNREVIEWED DELTA — not re-trigger on every later turn.
#
# The "signature" is the set of changed code-file PATHS (content-independent):
# fixing review findings in already-reviewed files does NOT re-trigger; touching
# new code files does. Marker file: /tmp/claude-review-done-<sid8> holds the
# sorted list of reviewed paths.
#
# Usage: review-marker.sh {files|unreviewed|count|write} <sid8>
#   files       all changed code files this session
#   unreviewed  changed code files NOT yet covered by a review
#   count       number of unreviewed code files
#   write       mark all current changed code files as reviewed

set -uo pipefail
cmd="${1:-}"; sid8="${2:-}"
[ -n "$cmd" ] && [ -n "$sid8" ] || { echo "usage: review-marker.sh {files|unreviewed|count|write} <sid8>" >&2; exit 2; }

MARK="/tmp/claude-review-done-${sid8}"
CODE_RE='\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|sh|bash|rb|java|kt|swift|c|cc|cpp|h|hpp|sql)$'
# Paths that are artifacts / reports / generated / vendored — NOT production
# source. A change here is never "code that needs adversarial review" (a release
# bundle, a report dir, node_modules). This is what stopped the gate firing on
# 25 markdown reports under <proj>/.claude/release-v-5.0/.
EXCLUDE_RE='/(node_modules|dist|build|coverage|vendor|__pycache__|\.next|\.venv|\.git|release[^/]*|reports|output|session-notes|assets|[A-Za-z0-9_-]*-review)/'

current() {
  ~/.claude/scripts/review-scope.sh "$sid8" 2>/dev/null \
    | rg "$CODE_RE" 2>/dev/null \
    | rg -v "$EXCLUDE_RE" 2>/dev/null \
    | sort -u
}
unreviewed() {
  if [ -f "$MARK" ]; then comm -23 <(current) <(sort -u "$MARK" 2>/dev/null); else current; fi
}

case "$cmd" in
  files)      current ;;
  unreviewed) unreviewed ;;
  count)      n=$(unreviewed | awk 'NF{c++} END{print c+0}'); printf '%s\n' "${n:-0}" ;;
  write)      current > "$MARK.tmp" && mv -f "$MARK.tmp" "$MARK" ;;
  *) echo "usage: review-marker.sh {files|unreviewed|count|write} <sid8>" >&2; exit 2 ;;
esac

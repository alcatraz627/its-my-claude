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
# Usage: review-marker.sh {files|unreviewed|count|write|edited|edited-unreviewed} [<sid>]
#   files             all changed code files this session (git diff plus edit tracker)
#   unreviewed        changed code files NOT yet covered by a review
#   count             number of unreviewed code files
#   write             mark all current changed code files as reviewed
#   edited            code files this session edited itself (edit tracker only, so
#                     another session's uncommitted work in the same repo is never
#                     counted); the set the Stop review nudge judges
#   edited-unreviewed those of them NOT yet covered by a review
#
# <sid> is a session id in any form: the full UUID, its first 8 characters, or
# omitted (or "-") to use $CLAUDE_CODE_SESSION_ID. It is cut to 8 characters before
# it names the marker. The reader and the writer used to build the marker name from
# whatever each was handed, so a review that wrote "<full uuid>" left a marker the
# gate never read, and the gate then asked for a review that had already happened.
set -uo pipefail
cmd="${1:-}"; sid8="${2:-}"
[ "$sid8" = "-" ] && sid8=""
[ -n "$sid8" ] || sid8="${CLAUDE_CODE_SESSION_ID:-}"
sid8="${sid8:0:8}"
USAGE="usage: review-marker.sh {files|unreviewed|count|write|edited|edited-unreviewed} [<session id>]"
[ -n "$cmd" ] && [ -n "$sid8" ] || { echo "$USAGE" >&2; exit 2; }

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
edited() {
  { [ -f "/tmp/claude-edited-files-$sid8" ] && cat "/tmp/claude-edited-files-$sid8"; } 2>/dev/null \
    | while IFS= read -r f; do [ -n "$f" ] && [ -f "$f" ] && echo "$f"; done \
    | rg "$CODE_RE" 2>/dev/null \
    | rg -v "$EXCLUDE_RE" 2>/dev/null \
    | sort -u
}
unreviewed() {
  if [ -f "$MARK" ]; then comm -23 <(current) <(sort -u "$MARK" 2>/dev/null); else current; fi
}

edited_unreviewed() {
  if [ -f "$MARK" ]; then comm -23 <(edited) <(sort -u "$MARK" 2>/dev/null); else edited; fi
}

case "$cmd" in
  files)      current ;;
  edited)     edited ;;
  edited-unreviewed) edited_unreviewed ;;
  unreviewed) unreviewed ;;
  count)      n=$(unreviewed | awk 'NF{c++} END{print c+0}'); printf '%s\n' "${n:-0}" ;;
  # The pipeline can exit non-zero with correct output (an rg with no match), so
  # the marker is promoted on the output, not the status.
  write)      [ -x ~/.claude/scripts/review-scope.sh ] || { echo "review-marker: review-scope.sh missing; marker left as is" >&2; exit 1; }
              { current || true; } > "$MARK.tmp"; mv -f "$MARK.tmp" "$MARK"
              echo "review-marker: $(awk 'NF{c++} END{print c+0}' "$MARK") file(s) marked reviewed in $MARK" ;;
  *) echo "$USAGE" >&2; exit 2 ;;
esac

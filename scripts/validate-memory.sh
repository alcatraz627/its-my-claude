#!/usr/bin/env bash
# validate-memory.sh — scan memory/*.md files for referenced paths and verify they exist.
#
# Motivation: reference-type memories point to external resources (scripts, docs,
# config files). If those resources move or get deleted, the memory silently rots.
# This script surfaces those stale references.
#
# Behavior:
#   - Walks ~/.claude/projects/*/memory/*.md (default) OR --path <dir>.
#   - Extracts file paths that look like references:
#       * Absolute paths:    /Users/... or $HOME/... or ~/...
#       * Backtick-quoted:   `/path/...` or `~/path/...`
#       * Code blocks:       paths inside ```bash``` fences
#   - Verifies each path exists. Reports stale ones grouped by memory file.
#
# Exit codes:
#   0 — all references valid
#   1 — at least one stale reference found (useful for CI / Stop hooks)
#
# Usage:
#   validate-memory.sh                    # scan default path
#   validate-memory.sh --path <dir>       # scan custom path
#   validate-memory.sh --quiet            # only print stale ones

set -uo pipefail

SCAN_PATH="$HOME/.claude/projects"
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --path) SCAN_PATH="$2"; shift 2 ;;
    --quiet|-q) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,19p' "$0"
      exit 0 ;;
    *) shift ;;
  esac
done

[ "$QUIET" -eq 0 ] && echo "[validate-memory] scanning $SCAN_PATH"

stale_total=0
checked_total=0
files_with_stale=0

# Find all memory .md files (exclude MEMORY.md index)
memory_files=$(find "$SCAN_PATH" -type f -name '*.md' 2>/dev/null | grep '/memory/' | grep -v '/MEMORY\.md$' || true)

if [ -z "$memory_files" ]; then
  echo "[validate-memory] no memory files found under $SCAN_PATH"
  exit 0
fi

while IFS= read -r mfile; do
  [ -z "$mfile" ] && continue

  # Extract candidate paths. Three patterns:
  #   /absolute/paths
  #   ~/home-relative/paths
  #   `/backticked/paths` or `~/backticked/paths`
  # Then filter out placeholder patterns that are never real file references:
  #   /path/to/...            — doc-example placeholder
  #   ...YYYY... ...MM-DD...  — date/time templates
  #   ...<placeholder>...     — angle-bracket templates
  #   ...{placeholder}...     — brace templates
  #   Triple-slash starts (//...) — malformed/fragment
  #   Bare /api/, /docs/ with no suffix — URL route fragments, not files
  paths=$(grep -oE '(\`?~?/?[A-Za-z0-9_./-]+(\.[A-Za-z0-9]+|/))+' "$mfile" 2>/dev/null \
          | sed -E 's/[`,;.]+$//; s/^`//; s/`$//' \
          | grep -E '^(/|~/|\$HOME/)' \
          | grep -v '^/$' \
          | grep -v '^//' \
          | grep -vE '/path/to/' \
          | grep -vE 'YYYY|MM-DD|HH-MM' \
          | grep -vE '[<{][^>}]*[>}]' \
          | grep -vE '^/(api|docs)/$' \
          | sort -u)

  stale_in_file=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    checked_total=$((checked_total + 1))

    # Expand ~ and $HOME
    expanded="${p/#\~/$HOME}"
    expanded="${expanded/#\$HOME/$HOME}"

    # Strip any line-number suffix like :42 or L10-20
    expanded_clean=$(echo "$expanded" | sed -E 's/:[0-9]+$//; s/ L[0-9]+(-[0-9]+)?$//')

    if [ ! -e "$expanded_clean" ]; then
      stale_in_file+="    ✗ $p"$'\n'
      stale_total=$((stale_total + 1))
    fi
  done <<< "$paths"

  if [ -n "$stale_in_file" ]; then
    files_with_stale=$((files_with_stale + 1))
    rel="${mfile#$HOME/}"
    echo
    echo "~/$rel"
    printf '%s' "$stale_in_file"
  fi
done <<< "$memory_files"

echo
if [ "$stale_total" -eq 0 ]; then
  [ "$QUIET" -eq 0 ] && echo "[validate-memory] ✓ all $checked_total references valid"
  exit 0
fi

echo "[validate-memory] ✗ $stale_total stale reference(s) across $files_with_stale memory file(s) (checked $checked_total total)"
exit 1

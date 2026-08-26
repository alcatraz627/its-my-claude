#!/usr/bin/env bash
# update-insights.sh — prepends a run entry to _insights.claude.md
# Usage: bash update-insights.sh "<entry-file>" "<topics-dir>"
#
# <entry-file> must be a file containing the formatted entry block.
# Entry is prepended (newest at top) after the file header.

set -euo pipefail

ENTRY_FILE="${1:-}"
TOPICS_DIR="${2:-$HOME/Documents/Claude/Topics}"
INSIGHTS="$TOPICS_DIR/_insights.claude.md"

if [[ -z "$ENTRY_FILE" || ! -f "$ENTRY_FILE" ]]; then
  echo "Usage: update-insights.sh <entry-file> [topics-dir]" >&2
  echo "  <entry-file> must exist and contain the formatted entry." >&2
  exit 1
fi

# Bootstrap insights file if absent
if [[ ! -f "$INSIGHTS" ]]; then
cat > "$INSIGHTS" << 'EOF'
# Cogitate Insights
> Prepend-only log of post-run lessons. Newest entries at top.
> Read the last 5–10 entries at session start to inform current run.

---

EOF
fi

# Prepend entry after the header block (after the first ---)
# Strategy: split on first "---\n\n", inject entry there.
HEADER=$(awk '/^---$/{found++} found==1{print; next} found<1{print}' "$INSIGHTS")
BODY=$(awk '/^---$/{found++} found>=1 && NR>1{print}' "$INSIGHTS")

{
  echo "$HEADER"
  echo ""
  cat "$ENTRY_FILE"
  echo ""
  echo "---"
  echo ""
  echo "$BODY"
} > "$INSIGHTS.tmp" && mv "$INSIGHTS.tmp" "$INSIGHTS"

echo "Insights updated: $INSIGHTS"

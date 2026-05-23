#!/usr/bin/env bash
# list-styles.sh — List all available report styles
# Usage: bash .claude/skills/create-report/scripts/list-styles.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STYLES_DIR="$SKILL_DIR/styles"

echo ""
echo "  Available report styles"
echo "  ─────────────────────────────────────────────────"
echo ""

# Default style (always available, lives at the root level)
printf "  %-14s %s  %s\n" "default" "📄" "Dark sidebar report with accent colors, font/color/width pickers"

# Custom styles from styles/ directory
if [ -d "$STYLES_DIR" ]; then
  for meta in "$STYLES_DIR"/*/meta.json; do
    [ -f "$meta" ] || continue
    dir=$(dirname "$meta")
    name=$(basename "$dir")

    # Parse meta.json fields
    desc=$(python3 -c "import json; print(json.load(open('$meta'))['description'])" 2>/dev/null || echo "No description")
    emoji=$(python3 -c "import json; print(json.load(open('$meta'))['emoji'])" 2>/dev/null || echo "•")

    # Check if template.ts exists (style is implemented)
    if [ -f "$dir/template.ts" ]; then
      status=""
    else
      status=" (not yet implemented)"
    fi

    printf "  %-14s %s  %s%s\n" "$name" "$emoji" "$desc" "$status"
  done
fi

echo ""
echo "  Usage: /create-report <markdown_path> [--style <name>]"
echo ""

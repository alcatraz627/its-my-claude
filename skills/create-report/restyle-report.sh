#!/usr/bin/env bash
# restyle-report.sh — Regenerate a /create-report output in a different style (no Claude needed)
# Usage: bash ~/.claude/skills/create-report/restyle-report.sh <report_dir> <style>
# Available styles: default, notion, dashboard, magazine, terminal, data-table, feed, corporate
set -euo pipefail

REPORT_DIR="${1:?Usage: restyle-report.sh <report_dir> <style>}"
STYLE="${2:-default}"
SKILL="$HOME/.claude/skills/create-report/generate-html.ts"

# Resolve to absolute path
REPORT_DIR="$(cd "$REPORT_DIR" && pwd)"

if [[ ! -f "$REPORT_DIR/data.json" ]]; then
  echo "Error: No data.json found in $REPORT_DIR" >&2
  echo "Make sure you're pointing to a /create-report output directory." >&2
  exit 1
fi

OUT="$REPORT_DIR/$STYLE"
echo "Generating style: $STYLE..."
npx tsx "$SKILL" "$REPORT_DIR/data.json" "$OUT/index.html" --style "$STYLE"
echo "→ $OUT/index.html"
open -a "Google Chrome" "$OUT/index.html" 2>/dev/null || echo "Open: file://$OUT/index.html"

#!/usr/bin/env bash
# Auto-extracted from atone-consolidate.sh by the split refactor (2026-05-15).
# This file is intended to be sourced (not executed) by atone-consolidate.sh.
# Functions defined here rely on env vars + helpers from atone-common.sh
# and atone-consolidate/helpers.sh.

# ─── Topics report ────────────────────────────────────────────────

build_topics_report() {
  local out="$TOPICS_DIR/atone-consolidate-$TODAY.md"
  {
    echo "# atone consolidation — $TODAY"
    echo
    echo "Generated: $NOW_UTC"
    echo
    echo "## Counts"
    echo
    jq . "$META"
    echo
    echo "## Top 5 patterns"
    echo
    cat "$DERIVED/_tldr.txt" 2>/dev/null
    echo
    echo "## Files regenerated"
    echo
    echo "- ~/.claude/mistake-patterns.md"
    echo "- ~/.claude/atone/derived/index.md"
    echo "- ~/.claude/atone/derived/archive.md"
    echo "- ~/.claude/atone/derived/clusters/{A,B,C,D,E}*.md"
    echo "- ~/.claude/atone/derived/triggers.json"
    echo "- ~/.claude/atone/derived/_tldr.txt"
    [ -f "$AFFIRM_EVENTS" ] && [ -s "$AFFIRM_EVENTS" ] && echo "- ~/.claude/compliments.md"
  } > "$out"
  _ok "wrote $out"
}


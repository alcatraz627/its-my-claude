#!/usr/bin/env bash
# file-preview.sh — rich, fast, dependency-degrading file preview for fzf
# --preview panes (and any TUI picker). Give it a path; it prints a colorized,
# bounded preview suited to the file's kind, degrading gracefully when a richer
# renderer is missing (jq → bat → head). Built for plug-and-play reuse across
# gcc TUI tools:  fzf --preview '~/.claude/scripts/tui/file-preview.sh {}'
#
# Contract: argv[1] = path. Always exits 0 (a preview must never break the host
# TUI). Honors PREVIEW_LINES (default 60). Color is forced on — preview panes
# want ANSI; a non-color host simply shows the codes, which is harmless.
set -o pipefail

f="${1:-}"
[ -n "$f" ] || { echo "(no file)"; exit 0; }
[ -e "$f" ] || { echo "(not found: $f)"; exit 0; }
if [ -d "$f" ]; then ls -la "$f" 2>/dev/null | head -n "${PREVIEW_LINES:-60}"; exit 0; fi
[ -f "$f" ] || { file -b "$f" 2>/dev/null; exit 0; }

lines="${PREVIEW_LINES:-60}"
ext="$(printf '%s' "${f##*.}" | tr '[:upper:]' '[:lower:]')"
_bat() { command -v bat >/dev/null 2>&1 && bat --color=always --style=numbers --line-range ":$lines" "$@"; }

case "$ext" in
  json)
    # Single parse, size-gated: jq reads the whole file, so only pretty-print
    # small JSON; large blobs get a bounded syntax-highlight/head instead of a
    # multi-second hover stall. jq pretty-prints a valid JSONL stream too; it
    # only falls back (empty output) when jq errors on genuinely invalid JSON.
    sz="$(wc -c < "$f" 2>/dev/null || echo 0)"
    if command -v jq >/dev/null 2>&1 && [ "${sz:-0}" -lt 2000000 ]; then
      out="$(jq -C . "$f" 2>/dev/null | head -n "$lines")"
      if [ -n "$out" ]; then printf '%s\n' "$out"; else _bat -l json "$f" || head -n "$lines" "$f"; fi
    else
      _bat -l json "$f" || head -n "$lines" "$f"
    fi ;;
  csv)  _bat -l csv "$f" || head -n "$lines" "$f" ;;
  tsv)  _bat -l tsv "$f" || _bat -l csv "$f" || head -n "$lines" "$f" ;;
  xlsx)
    printf 'xlsx · %s\n' "$(du -h "$f" 2>/dev/null | cut -f1)"
    # sheet names without a python/uv round-trip — read the workbook part directly
    unzip -p "$f" xl/workbook.xml 2>/dev/null \
      | grep -o 'name="[^"]*"' | sed 's/name="/  sheet: /; s/"$//' | head -20 ;;
  *)    _bat "$f" || head -n "$lines" "$f" 2>/dev/null || file -b "$f" ;;
esac
exit 0

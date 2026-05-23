#!/usr/bin/env bash
# 10-cleanup-tmp-state.sh — Remove stale /tmp/claude-* state files across ALL
# prefixes (tab, turns, tools, edits, timeline, net, fchg, statusline, last, ctxwatch, …).
#
# REVIVAL:
#   These files are session-scoped state and are recreated on demand by their
#   owning hooks/scripts. Only files older than RETAIN_DAYS are dropped, so
#   any active session's state (touched recently) is safe.
#
# Renamed 2026-05-17 from 10-cleanup-tab-state.sh — now covers all /tmp/claude-*
# prefixes uniformly, not just tab-state. See migration 0010.

set -uo pipefail

DRY_RUN=0
RETAIN_DAYS=7

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --retain-days) RETAIN_DAYS="${2:-7}"; shift ;;
  esac
  shift
done

# Per-prefix counts (for readable summary)
prefixes=(tab turns tools edits timeline net fchg statusline last ctxwatch)
total_removed=0
total_current=0

for p in "${prefixes[@]}"; do
  removed=0; current=0
  while IFS= read -r -d '' f; do
    current=$((current + 1))
    if [[ -z "$(find "$f" -mtime "+${RETAIN_DAYS}" 2>/dev/null)" ]]; then
      continue  # too recent
    fi
    if (( DRY_RUN )); then
      removed=$((removed + 1))
    else
      rm -f "$f" 2>/dev/null && removed=$((removed + 1))
    fi
  done < <(find /tmp -maxdepth 1 -name "claude-${p}-*" -type f -print0 2>/dev/null)
  total_removed=$((total_removed + removed))
  total_current=$((total_current + current))
  (( current > 0 )) && printf '  %-12s removed=%d / total=%d\n' "$p" "$removed" "$current"
done

if (( DRY_RUN )); then
  printf 'would remove %d files older than %dd (across %d total /tmp/claude-* files)\n' "$total_removed" "$RETAIN_DAYS" "$total_current"
else
  printf 'removed %d /tmp/claude-* files older than %dd (of %d total)\n' "$total_removed" "$RETAIN_DAYS" "$total_current"
fi

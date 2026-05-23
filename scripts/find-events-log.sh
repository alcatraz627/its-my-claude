#!/usr/bin/env bash
# find-events-log.sh — resolve the path of the global Claude events log.
#
# Why this exists: rather than every skill hardcoding ~/.claude/events.jsonl,
# they call this helper. If the path ever moves (e.g. rotated to
# events-2026-04.jsonl), only this script changes.
#
# Usage:
#   LOG=$(bash ~/.claude/scripts/find-events-log.sh)   # current active log
#   LOG=$(bash ~/.claude/scripts/find-events-log.sh --all)  # current + rotated
#
# Output: one absolute path per line.

set -uo pipefail

DEFAULT="$HOME/.claude/events.jsonl"

case "${1:-current}" in
  --all|all)
    # Include rotated logs if any (pattern: events-YYYY-MM.jsonl)
    ls -1 "$HOME/.claude/events-"*.jsonl 2>/dev/null || true
    [ -f "$DEFAULT" ] && echo "$DEFAULT"
    ;;
  *)
    echo "$DEFAULT"
    ;;
esac

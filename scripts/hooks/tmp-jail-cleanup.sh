#!/usr/bin/env bash
# SessionEnd: remove this session's /tmp-jail marker. Tidiness only — orphan
# markers are harmless (keyed to a dead session_id that no live session reuses).
# Fail-open and silent.
set -uo pipefail
input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null) || exit 0
[ -n "$sid" ] || exit 0
rm -f "$HOME/.claude/run/tmpjail/$sid" 2>/dev/null || true
exit 0

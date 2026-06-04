#!/usr/bin/env bash
# UserPromptSubmit hinter — surface workspace todos carried over for a new/revived
# session (written by SessionStart pull.sh) so the agent seeds them via TaskCreate.
#
# Hinters get only the prompt text on stdin — no session id (CLAUDE_SESSION_ID is
# empty here). So, like 46/47, pick the newest recent pending file and fire ONLY
# when exactly one session is unambiguous; with two concurrent pending files we
# stay silent rather than inject session A's todos into session B (was: fell back
# to the global .current-session-id slot — cross-session injection). Latency <100ms.

set -uo pipefail

[ -f "$HOME/.claude/sync-disabled" ] && exit 0
[ -f "$HOME/.claude/scripts/sync-todos/.hinter-off" ] && exit 0

# Trailing slash on /tmp/ is required (it's a symlink; BSD find won't descend it
# otherwise). Sweep stale pending files; consider only recent ones.
find /tmp/ -maxdepth 1 -name 'claude-todo-pending-*.json' -mmin +120 -delete 2>/dev/null
recent=$(find /tmp/ -maxdepth 1 -name 'claude-todo-pending-*.json' -mmin -60 2>/dev/null)
[ -n "$recent" ] || exit 0
[ "$(printf '%s\n' "$recent" | grep -c .)" = "1" ] || exit 0
PENDING="$recent"

COUNT=$(jq -r '.unchecked_todos | length' "$PENDING" 2>/dev/null || echo 0)
[ "$COUNT" -gt 0 ] || { rm -f "$PENDING" 2>/dev/null; exit 0; }

PREVIEW=$(jq -r '.unchecked_todos[:3] | .[]' "$PENDING" 2>/dev/null | sed 's/^/  - /')
rm -f "$PENDING" 2>/dev/null
printf '[sync-todos] %d workspace todo(s) carried over — seed them into your task list via TaskCreate at the start of your response:\n%s\n' \
  "$COUNT" "$PREVIEW"

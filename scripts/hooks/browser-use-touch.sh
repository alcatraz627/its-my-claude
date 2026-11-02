#!/usr/bin/env bash
# Records that an agent just used its testing browser, so the leak reaper counts
# only real agent use as activity and never a page's own background traffic.
# PostToolUse on the Playwright and Chrome DevTools MCP tools. Details:
# features/dev-servers.md
input=$(cat 2>/dev/null) || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
dir="$HOME/.claude/dev-servers/reap-leaks/browser-touch"
mkdir -p "$dir" 2>/dev/null
touch "$dir/$sid" 2>/dev/null
exit 0

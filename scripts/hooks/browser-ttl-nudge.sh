#!/usr/bin/env bash
# Asks an agent, once per session, how long its testing browser should be allowed
# to sit idle, as it starts one. A nudge and never a block: these browsers get left
# behind by accident, not malice (owner, 2026-11-02). Limits: features/dev-servers.md
#
# PreToolUse on the browser MCP tools and on Bash. Mute: touch ~/.claude/.no-browser-ttl-nudge
[ -f "$HOME/.claude/.no-browser-ttl-nudge" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$sid" ] || exit 0
dir="$HOME/.claude/dev-servers/reap-leaks/nudged"
[ -f "$dir/$sid" ] && exit 0

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
case "$tool" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
    printf '%s' "$cmd" | rg -qi 'playwright|puppeteer|selenium|chromedriver|--headless|--remote-debugging' 2>/dev/null || exit 0 ;;
  mcp__plugin_playwright_playwright__*|mcp__plugin_chrome-devtools-mcp_chrome-devtools__*) ;;
  *) exit 0 ;;
esac

mkdir -p "$dir" 2>/dev/null
touch "$dir/$sid" 2>/dev/null
jq -cn --arg c "Starting a testing browser? Pick how long it may sit idle before it is stopped. The default is 15 minutes for an automated copy of the installed Chrome when the owner has no Chrome open, because it stops them opening Chrome, and 2 hours otherwise. 15 minutes suits most work, so do nothing if that fits. For longer work run: python3 ~/.claude/scripts/dev-servers/reap-leaks.py ttl MINUTES \"why\". The most is 240 minutes, and do not go past 120 unless the work really needs it." \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", additionalContext:$c}}'
exit 0

#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Checks when the testing-browser nudge speaks and when it stays quiet.
# Run: bash ~/.claude/scripts/hooks/browser-ttl-nudge.test.sh
HOOK="$(cd "$(dirname "$0")" && pwd)/browser-ttl-nudge.sh"
MARKS="$HOME/.claude/dev-servers/reap-leaks/nudged"
fails=0; total=0

bash_input() { jq -cn --arg c "$2" --arg s "$1" '{session_id:$s, tool_name:"Bash", tool_input:{command:$c}}'; }
mcp_input() { jq -cn --arg s "$1" '{session_id:$s, tool_name:"mcp__plugin_playwright_playwright__browser_navigate", tool_input:{url:"x"}}'; }

check() { # name, expected (speaks|quiet), hook output
  total=$((total + 1))
  case "$2:$3" in
    speaks:*additionalContext*|quiet:) echo "PASS $1" ;;
    *) echo "FAIL $1: $3"; fails=$((fails + 1)) ;;
  esac
}

A="nudge-test-a-$$"; B="nudge-test-b-$$"; C="nudge-test-c-$$"
check "an ordinary command stays quiet" quiet "$(bash_input "$A" 'ls -la' | "$HOOK")"
out=$(bash_input "$A" 'node drive-playwright.mjs' | "$HOOK")
check "a Playwright script gets the nudge" speaks "$out"
total=$((total + 1))
if printf '%s' "$out" | rg -q 'reap-leaks.py ttl' && printf '%s' "$out" | rg -q '240' && printf '%s' "$out" | rg -q '120'; then
  echo "PASS it names the command and both limits"
else echo "FAIL it names the command and both limits"; fails=$((fails + 1)); fi
total=$((total + 1))
if printf '%s' "$out" | rg -q 'permissionDecision'; then echo "FAIL it must never block"; fails=$((fails + 1))
else echo "PASS it never blocks"; fi
check "only once per session" quiet "$(bash_input "$A" 'node drive-playwright.mjs' | "$HOOK")"
check "the browser MCP gets the nudge" speaks "$(mcp_input "$B" | "$HOOK")"
check "a headless flag gets the nudge" speaks "$(bash_input "$C" 'chrome --headless about:blank' | "$HOOK")"

for s in "$A" "$B" "$C"; do trash "$MARKS/$s" 2>/dev/null; done
echo; echo "$((total - fails))/$total passed"
[ "$fails" = 0 ]

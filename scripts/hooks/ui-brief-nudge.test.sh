#!/usr/bin/env bash
export HOOK_TEST=1  # keeps real hooks fired here out of the live ledger
# Checks when the UI brief nudge speaks and when it stays quiet, on paths taken from real edits.
# Run: bash ~/.claude/scripts/hooks/ui-brief-nudge.test.sh
HOOK="$(cd "$(dirname "$0")" && pwd)/ui-brief-nudge.sh"
MARKS="$HOME/.claude/state/ui-brief-nudged"
BEFORE=$(mktemp)
ls "$MARKS" > "$BEFORE" 2>/dev/null
fails=0; total=0

edit() { # session, file, optional agent id
  jq -cn --arg s "$1" --arg f "$2" --arg a "${3:-}" '{session_id:$s, tool_name:"Edit", tool_input:{file_path:$f}} + (if $a == "" then {} else {agent_id:$a} end)'
}
check() { # name, expected (speaks|quiet), hook output
  total=$((total + 1))
  case "$2:$3" in
    speaks:*additionalContext*|quiet:) echo "PASS $1" ;;
    *) echo "FAIL $1: $3"; fails=$((fails + 1)) ;;
  esac
}

A="ui-brief-test-a-$$"; B="ui-brief-test-b-$$"; C="ui-brief-test-c-$$"; D="ui-brief-test-d-$$"
SYS="$HOME/Code/Claude/sys-pier"
OTHER="$HOME/.claude/scripts/pages"

out=$(edit "$A" "$SYS/hub/page/hub.css" | "$HOOK")
check "a stylesheet gets the brief" speaks "$out"
total=$((total + 1))
if printf '%s' "$out" | rg -q 'conventions/ui-brief.md'; then echo "PASS it names the brief"
else echo "FAIL it names the brief"; fails=$((fails + 1)); fi
total=$((total + 1))
if printf '%s' "$out" | rg -q 'permissionDecision'; then echo "FAIL it must never block"; fails=$((fails + 1))
else echo "PASS it never blocks"; fi
check "only once in a project" quiet "$(edit "$A" "$SYS/hub/page/hub.js" | "$HOOK")"
check "a sub-agent in that project gets its own" speaks "$(edit "$A" "$SYS/hub/page/hub.css" agent-1 | "$HOOK")"
check "and only once as well" quiet "$(edit "$A" "$SYS/hub/page/hub.css" agent-1 | "$HOOK")"
check "another project speaks again" speaks "$(edit "$A" "$OTHER/kit.css" | "$HOOK")"

check "JS in a page folder counts" speaks "$(edit "$B" "$SYS/hub/page/hub.js" | "$HOOK")"
check "a server script does not" quiet "$(edit "$C" "$SYS/hub/server.cjs" | "$HOOK")"
check "plain JS outside a page folder does not" quiet "$(edit "$C" "$SYS/adapters/pm2.js" | "$HOOK")"
check "a markdown doc does not" quiet "$(edit "$C" "$SYS/README.md" | "$HOOK")"
check "a Python script does not" quiet "$(edit "$C" "$SYS/.claude/ui/checks/services.py" | "$HOOK")"
check "a built bundle does not" quiet "$(edit "$C" "$SYS/dist/app.css" | "$HOOK")"
check "a dependency does not" quiet "$(edit "$C" "$SYS/node_modules/x/a.css" | "$HOOK")"
check "a test file does not" quiet "$(edit "$C" "$SYS/src/app.test.tsx" | "$HOOK")"
check "a report page does not" quiet "$(edit "$C" "$HOME/.claude/assets/reports/x/page.html" | "$HOOK")"
check "a React component does" speaks "$(edit "$D" "$HOME/Code/Versable/speedway/src/App.tsx" | "$HOOK")"
check "bad input stays quiet" quiet "$(printf 'not json' | "$HOOK")"
check "no file path stays quiet" quiet "$(jq -cn '{session_id:"x", tool_name:"Edit", tool_input:{}}' | "$HOOK")"

# Remove only the marks this run added.
for m in "$MARKS"/*; do
  [ -e "$m" ] || continue
  rg -qxF "$(basename "$m")" "$BEFORE" || trash "$m" 2>/dev/null
done
trash "$BEFORE" 2>/dev/null
echo; echo "$((total - fails))/$total passed"
[ "$fails" = 0 ]

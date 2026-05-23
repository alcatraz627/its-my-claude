#!/usr/bin/env bash
# PostToolUse hook for BashOutput — detects test commands and writes
# pass/fail results to /tmp/claude-test-$PPID for the statusline.
# Always exits 0 to avoid blocking the main agent.

INPUT=$(cat 2>/dev/null) || INPUT="{}"

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || COMMAND=""
[[ -z "$COMMAND" ]] && exit 0

# Detect test commands (common test runners)
is_test=0
case "$COMMAND" in
  *npm\ test*|*npm\ run\ test*|*npx\ jest*|*npx\ vitest*) is_test=1 ;;
  *yarn\ test*|*pnpm\ test*|*bun\ test*) is_test=1 ;;
  *pytest*|*python\ -m\ pytest*|*python\ -m\ unittest*) is_test=1 ;;
  *jest\ *|*vitest\ *|*mocha\ *|*ava\ *) is_test=1 ;;
  *go\ test*|*cargo\ test*|*mix\ test*|*rspec*) is_test=1 ;;
  *make\ test*|*make\ check*) is_test=1 ;;
esac
[[ $is_test -eq 0 ]] && exit 0

# Get exit code and stdout from the tool result
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // .tool_result.exitCode // "0"' 2>/dev/null) || EXIT_CODE="0"
OUTPUT=$(echo "$INPUT" | jq -r '.tool_result.stdout // .tool_result.output // ""' 2>/dev/null) || OUTPUT=""

# Try to extract test counts from output
total=0; failed=0; passed=0

# Jest/Vitest pattern: "Tests: 3 failed, 12 passed, 15 total"
if echo "$OUTPUT" | grep -qiE '(tests?|test suites?).*total'; then
  total=$(echo "$OUTPUT" | grep -oiE '[0-9]+ total' | tail -1 | grep -oE '[0-9]+') || total=0
  failed=$(echo "$OUTPUT" | grep -oiE '[0-9]+ failed' | tail -1 | grep -oE '[0-9]+') || failed=0
  passed=$(echo "$OUTPUT" | grep -oiE '[0-9]+ passed' | tail -1 | grep -oE '[0-9]+') || passed=0
fi

# Pytest pattern: "5 passed, 2 failed" or "5 passed"
if [[ $total -eq 0 ]] && echo "$OUTPUT" | grep -qiE '[0-9]+ passed'; then
  passed=$(echo "$OUTPUT" | grep -oiE '[0-9]+ passed' | tail -1 | grep -oE '[0-9]+') || passed=0
  failed=$(echo "$OUTPUT" | grep -oiE '[0-9]+ failed' | tail -1 | grep -oE '[0-9]+') || failed=0
  total=$((passed + failed))
fi

# Go test pattern: "ok  ./... 1.234s" or "FAIL ./..."
if [[ $total -eq 0 ]] && echo "$OUTPUT" | grep -qE '^(ok|FAIL)\s'; then
  passed=$(echo "$OUTPUT" | grep -c '^ok' 2>/dev/null) || passed=0
  failed=$(echo "$OUTPUT" | grep -c '^FAIL' 2>/dev/null) || failed=0
  total=$((passed + failed))
fi

# Fallback: use exit code if no counts found
if [[ $total -eq 0 ]]; then
  total=1
  if [[ "$EXIT_CODE" == "0" ]]; then
    failed=0
  else
    failed=1
  fi
fi

# Determine status
if [[ $failed -gt 0 || "$EXIT_CODE" != "0" ]]; then
  status="fail"
else
  status="pass"
fi

# Write marker file for statusline to read
# In hook context, PPID is Claude Code's PID — matches statusline's $PPID
MARKER="/tmp/claude-test-${PPID}"
printf '%s\n' "test_status=$status" "test_total=$total" "test_failed=$failed" > "$MARKER" 2>/dev/null || true

exit 0

#!/usr/bin/env bash
# PostToolUse hook for Bash — captures exit code into /tmp/claude-last-exit-$PPID
# so the statusline can show exit:N when the last command failed.
# Always exits 0 to avoid blocking the main agent.

INPUT=$(cat 2>/dev/null) || INPUT="{}"

# BashOutput: tool_result.exit_code (primary) or tool_result.exitCode (alt key)
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // .tool_result.exitCode // "0"' 2>/dev/null) || EXIT_CODE="0"

# Validate: must be a non-negative integer
[[ "$EXIT_CODE" =~ ^[0-9]+$ ]] || EXIT_CODE="0"

printf '%s' "$EXIT_CODE" > "/tmp/claude-last-exit-${PPID}" 2>/dev/null || true
exit 0

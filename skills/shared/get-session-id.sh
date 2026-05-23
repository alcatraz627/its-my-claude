#!/usr/bin/env bash
# get-session-id.sh — resolve the current Claude session ID.
#
# Usage (source it, then call the function):
#   source ~/.claude/skills/shared/get-session-id.sh
#   SID=$(get_session_id)
#
# Resolution order:
#   1. CLAUDE_SESSION_ID env var (if set by caller or future harness support)
#   2. ~/.claude/.current-session-id file (written by SessionStart hook)
#   3. Empty string (no session context available)
#
# Designed to be fast — no jq, no subshells on the happy path.

get_session_id() {
    # 1. Explicit env var
    if [ -n "${CLAUDE_SESSION_ID:-}" ]; then
        printf '%s' "$CLAUDE_SESSION_ID"
        return
    fi

    # 2. File written by SessionStart → emit-event.sh
    local sid_file="$HOME/.claude/.current-session-id"
    if [ -f "$sid_file" ]; then
        local sid
        sid=$(cat "$sid_file" 2>/dev/null || echo "")
        if [ -n "$sid" ]; then
            printf '%s' "$sid"
            return
        fi
    fi

    # 3. No session context
    printf ''
}

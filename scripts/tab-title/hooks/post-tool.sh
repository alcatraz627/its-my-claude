#!/usr/bin/env bash
# tab-title/hooks/post-tool.sh — PostToolUse hook (async).
# Decrements the in-flight tool counter and clears TRANSIENT_FOCUS when no
# tool is running. Manual focus (set via set-focus.sh) is then visible again.

set -uo pipefail
command -v jq &>/dev/null || exit 0
source "${HOME}/.claude/scripts/tab-title/lib.sh"

input=$(cat)
sid=$(echo "$input" | jq -r '.session_id // empty')
[[ -n "$sid" ]] || exit 0

tab_load_state "$sid" || exit 0
TRANSIENT_DEPTH=$(( ${TRANSIENT_DEPTH:-0} - 1 ))
(( TRANSIENT_DEPTH < 0 )) && TRANSIENT_DEPTH=0
if (( TRANSIENT_DEPTH == 0 )); then
  TRANSIENT_FOCUS=""
fi
tab_save_state "$sid"
# No tab_emit — same reason as pre-tool.sh: PreTool/PostTool /dev/tty
# doesn't reach the visible terminal under Claude Code's hook arrangement.

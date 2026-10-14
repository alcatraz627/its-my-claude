#!/usr/bin/env bash
# ui-verified-hint.sh — UserPromptSubmit: hand the agent the warning that
# ui-verified-stop.py queued at the end of the last turn.
#
# A Stop hook has no non-blocking way to talk to the agent: a systemMessage reaches
# only the owner. The frame-description check is meant to be a warning the agent
# weighs, so the Stop hook leaves its note in /tmp and this hook delivers it as
# context on the next prompt, once. Same split as speculative-atone-stop.sh and
# speculative-atone-hint.sh.
# Mute: touch ~/.claude/.no-ui-verified-gate (the same file that mutes the Stop hook).
set -uo pipefail
[ -f "$HOME/.claude/.no-ui-verified-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null || echo "{}")
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
note="/tmp/claude-uiverified-note-${sid:0:8}"
[ -s "$note" ] || exit 0

msg=$(cat "$note" 2>/dev/null)
rm -f "$note" 2>/dev/null
[ -n "$msg" ] || exit 0
jq -cn --arg c "$msg" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}' 2>/dev/null || true
exit 0

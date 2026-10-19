#!/usr/bin/env bash
# decision-surface-nudge.sh — PreToolUse hook on AskUserQuestion.
#
# Points the agent at the right surface when a question to the owner is
# really a decision set or a visual comparison. More than one question goes
# through /decision-wizard (inline menu for a few simple picks, a decision
# page at :5106/dp/ above that). Options carrying a `preview` mean the owner
# is comparing visuals, which /mock-app renders as real mocks in a gallery on
# one decision page; a monospace preview box is a sketch, not a mock.
#
# ADVISORY, never blocks: a single genuine pick still goes through as asked.
#
# Output contract: {hookSpecificOutput:{hookEventName:"PreToolUse",
# additionalContext:<msg>}} on stdout, exit 0 always. Silent on any doubt.
#
# Mute:          touch ~/.claude/.no-decision-surface-nudge
# One-shot skip: DECISION_SURFACE_OFF=1
# Telemetry:     warn-log.sh --hook decision-surface-nudge --action nudge

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
printf '%s' "$INPUT" | jq empty 2>/dev/null || exit 0

[ "${DECISION_SURFACE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.no-decision-surface-nudge" ] && exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "AskUserQuestion" ] || exit 0

COUNT=$(printf '%s' "$INPUT" | jq -r '(.tool_input.questions // []) | length')
PREVIEWS=$(printf '%s' "$INPUT" | jq -r '[(.tool_input.questions // [])[] | (.options // [])[] | select((.preview // "") != "")] | length')

MSG=""
if [ "${PREVIEWS:-0}" -gt 0 ]; then
  MSG="This question compares visuals. Render real options with /mock-app and show them as a gallery on one decision page; a text preview box is a sketch the owner has to imagine."
elif [ "${COUNT:-0}" -gt 1 ]; then
  MSG="This asks the owner $COUNT questions. Route them through /decision-wizard: default what you have a confident pick for, ask only the open calls, inline menu for three or fewer simple picks, a decision page above that."
fi
[ -n "$MSG" ] || exit 0

bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook decision-surface-nudge --action nudge --heeded unknown >/dev/null 2>&1 || true
jq -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$m}}'
exit 0

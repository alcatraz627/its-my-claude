#!/usr/bin/env bash
# Asks an agent to confirm with the owner when another agent's message claims the owner's
# authority and wants a change outside the session (owner ruling D6, 2026-11-03). A nudge,
# never a block. Mail through the claude-ipc broker gets this from its own frame; this hook
# covers teammate and cross-session messages, which arrive as user turns and skip the broker.
#
# The owner's own typing is never checked, and the detector lives in claude-ipc so there is
# only one copy. An older claude-ipc without claim-check just stays silent.
# UserPromptSubmit. Mute: touch ~/.claude/.no-authority-claim-note
[ -f "$HOME/.claude/.no-authority-claim-note" ] && exit 0
input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
bin="${CLAUDE_IPC_BIN:-claude-ipc}"
command -v "$bin" >/dev/null 2>&1 || exit 0

prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
case "$prompt" in
  "Another Claude session sent"*|"<teammate-message"*|"<cross-session-message"*) ;;
  *) exit 0 ;;
esac

# Name the sender in the question. The attribute names are the harness's own.
sender=$(printf '%s' "$prompt" | sed -n -E 's/.*<(teammate-message|cross-session-message)[^>]*(teammate_id|from)="([^"]+)".*/\3/p' | sed -n '1p')
note=$(printf '%s' "$prompt" | "$bin" claim-check --from "${sender:-A peer}" 2>/dev/null) || exit 0
[ -n "$note" ] || exit 0

jq -cn --arg c "$note" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$c}}'
exit 0

#!/usr/bin/env bash
# warn-kill-9.sh — PreToolUse[Bash] hook. Warns on `kill -9 <pid>` usage.
#
# Why: -9 (SIGKILL) skips SIGTERM cleanup. For daemons writing files
# (subconscious, statusline-daemon, llm-mini ollama), this corrupts
# in-flight writes. SIGTERM first lets the process flush + close gracefully.
#
# Non-blocking: injects additionalContext to the agent (which surfaces it to the
# user). Mute: touch ~/.claude/.no-kill-9-hint

set -uo pipefail
[[ -f "$HOME/.claude/.no-kill-9-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Match `kill -9 <pid>` or `kill -SIGKILL`. Allow `kill -9 $!` (intentional
# script idiom for backgrounded watchers — explicit context).
if echo "$CMD" | rg -q '(^|\s|;|&&|\|\|)\s*kill\s+(-9|-SIGKILL)\b' 2>/dev/null; then
  if ! echo "$CMD" | rg -q 'kill\s+-9\s+\$!' 2>/dev/null; then
    msg="[hint] \`kill -9\` (SIGKILL) skips cleanup — daemons writing files may corrupt in-flight writes. Try SIGTERM first: 'kill <pid>' (default, lets it flush), then 'sleep 1; kill -9 <pid>' only if still running. (mute: touch ~/.claude/.no-kill-9-hint)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
    jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
  fi
fi

exit 0

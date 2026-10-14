#!/usr/bin/env bash
# warn-kill-9.sh — PreToolUse[Bash] hook. Warns on `kill -9 <pid>` usage.
#
# Why: -9 (SIGKILL) skips SIGTERM cleanup. For daemons writing files
# (subconscious, statusline-daemon, llm-mini ollama), this corrupts
# in-flight writes. SIGTERM first lets the process flush + close gracefully.
#
# Non-blocking. Since 2026-09-05 a fire is recorded to the warn ledger only: the hook
# is registered async on PreToolUse and that stdout never reaches the model.
# Mute: touch ~/.claude/.no-kill-9-hint

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
    # Confirm this INVOKES kill -9 rather than quoting it, e.g. an echo or a
    # doc string describing the idiom. Second stage only; fails open.
    if [ -r "$HOME/.claude/scripts/hooks/hook-common.sh" ]; then
      . "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true
      type hook_cmd_skeleton >/dev/null 2>&1 &&
        ! printf '%s' "$CMD" | hook_cmd_skeleton \
          | rg -q '(^|\s|;|&&|\|\|)\s*kill\s+(-9|-SIGKILL)\b' 2>/dev/null && exit 0
    fi
    # Ledger only: registered async on PreToolUse, whose stdout the harness never
    # returns (canary 2026-09-05; owner ruling: strip the payload, keep the telemetry).
    # To revive the nudge, register synchronous and emit additionalContext here.
    bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook warn-kill-9 --action nudge --heeded unknown >/dev/null 2>&1 || true
  fi
fi

exit 0

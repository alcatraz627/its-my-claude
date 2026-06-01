#!/usr/bin/env bash
# prefer-read-over-head-tail-file.sh — PreToolUse[Bash] nudge.
# Companion to prefer-read-over-cat. Fires on `head -N <file>` / `tail -N <file>`
# WITHOUT piping or redirection (i.e., pure file-inspection use).
#
# 1044 head + 560 tail uses observed in 7d of shell-logs, but ~90% are stream
# slicing (`cmd | head -N`) — that's legitimate, not flagged.
#
# Only flag the no-pipe / no-redirect case where Read with offset/limit is
# strictly better (line-numbered output, accurate citing).
#
# Mute: touch ~/.claude/.no-head-tail-hint

set -uo pipefail
[[ -f "$HOME/.claude/.no-head-tail-hint" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
[[ -z "$INPUT" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# Skip if there's a pipe (stream slicing) or redirect (legitimate)
echo "$CMD" | rg -q '\||>' 2>/dev/null && exit 0
# Skip heredoc
echo "$CMD" | rg -q '<<\s*\w+' 2>/dev/null && exit 0

# Match: head/tail with -N flag and a file path arg (not -, not -f)
if echo "$CMD" | rg -q '(^|;|&&|\|\|)\s*(head|tail)\s+-\d+\s+[^-\s|>]\S*\s*(;|$|&&|\|\|)' 2>/dev/null; then
  msg="[hint] \`head -N <file>\` / \`tail -N <file>\` → consider the Read tool with offset+limit: line-numbered output (accurate file:line cites), respects token budget, no shell-quote/path issues. For 'cmd | head -N' (stream slicing) keep head/tail. (mute: touch ~/.claude/.no-head-tail-hint)  →→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
  jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
fi
exit 0

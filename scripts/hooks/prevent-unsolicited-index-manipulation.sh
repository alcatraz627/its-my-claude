#!/usr/bin/env bash
# prevent-unsolicited-index-manipulation.sh — PreToolUse hook on Bash.
#
# Graduated from atone pattern: unsolicited-index-manipulation (S3, 2026-05-14).
# The incident: agent shipped `git reset HEAD frontend/` as part of a staging
# suggestion, wiping minutes of the user's curated index state.
#
# This hook BLOCKS git commands that destructively touch the index unless:
#   - Command was invoked via a whitelisted atone-suite script
#   - Command is wrapped in an explicit safety phrase
#     (env: ATONE_INDEX_OK=1, set via `ATONE_INDEX_OK=1 git reset ...`)
#
# Records a fired-and-useful feedback event when it blocks.
#
# Exit codes: 0=allow, 2=block (claude shows stderr to user).

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# Allowlist atone-suite scripts so they can manipulate index for legitimate ops
if echo "$CMD" | grep -qE '/\.claude/scripts/atone'; then
  exit 0
fi

# Explicit per-command opt-in (user-requested or pre-approved chain)
if echo "$CMD" | grep -qE '\bATONE_INDEX_OK=1\b'; then
  exit 0
fi

# Patterns that modify the user's curated index — DESTRUCTIVE to in-flight work
if echo "$CMD" | grep -qE '\bgit\s+(reset(\s+HEAD|\s+--mixed|\s+--soft)?\s+[^-]|restore\s+--staged\b|rm\s+--cached\b|stash(\s|$))'; then

  # Record a feedback event so we can measure hook effectiveness
  ( bash "$HOME/.claude/scripts/atone.sh" feedback \
      --kind fired-and-useful \
      --slug unsolicited-index-manipulation \
      --trigger-id trig-unsolicited-index-manipulation \
      --notes "PreToolUse hook blocked git index-modification command" \
      >/dev/null 2>&1 & ) &

  cat >&2 <<EOF
[prevent-unsolicited-index] BLOCKED — git command modifies the user's curated index

  command: $(echo "$CMD" | head -c 200)

This is graduated from atone slug 'unsolicited-index-manipulation' (S3).
The user's git index is their work — even a "non-destructive" reset wipes
minutes of curated staging state.

To bypass this hook for one command (when the user explicitly asked):
  ATONE_INDEX_OK=1 <your-git-command>

Or use targeted 'git add <paths>' to narrow what gets staged, instead of
'git reset' to drop other things first.

Atone show: bash ~/.claude/scripts/atone.sh show mist-20260514-120000-m00
EOF
  exit 2
fi

exit 0

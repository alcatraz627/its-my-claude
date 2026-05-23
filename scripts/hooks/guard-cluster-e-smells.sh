#!/usr/bin/env bash
# guard-cluster-e-smells.sh — PreToolUse[Write|Edit|MultiEdit], SYNCHRONOUS.
#
# Runs the shared atone-lint catalog against the code I am ABOUT TO write.
#   - A BLOCK-level smell (precise, e.g. IIFE/scope-wrapper in JSX) → denies the
#     edit via {"decision":"block"} so the smell never lands. This is the only
#     PreToolUse mechanism that actually reaches the agent (async stdout does not).
#   - A WARN-level smell (heuristic, e.g. review surface w/ destructive actions)
#     → prints an advisory and allows the edit; it cannot be mechanically
#     confirmed, so it must not block.
#
# Backstopped by the Stop review gate (hooks/review-gate-stop.sh), which re-runs
# the same catalog at "done" time on every file touched this session.
#
# Mute: touch ~/.claude/.no-cluster-e-nudge

set -uo pipefail
[ -f "$HOME/.claude/.no-cluster-e-nudge" ] && exit 0

LINT="$HOME/.claude/scripts/atone-lint.sh"
[ -x "$LINT" ] || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0

file_path=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file_path" ] && exit 0

payload=$(printf '%s' "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  // empty' 2>/dev/null)
[ -z "$payload" ] && exit 0

# Strip the leading "severity<TAB>rule<TAB>slug<TAB>" columns, keep the message.
msg_lines() { awk -F'\t' 'NF>=4 {print "  • " $4}'; }

block_hits=$(printf '%s' "$payload" | "$LINT" --path "$file_path" --block-only 2>/dev/null)
if [ -n "$block_hits" ]; then
  reason="⚠ atone-lint BLOCK — this edit to ${file_path} introduces a smell you have corrected before:
$(printf '%s' "$block_hits" | msg_lines)

Blocked at write-time because it recurs. Conform to the sibling inline pattern
instead of wrapping a function. Genuine exception? mute: touch ~/.claude/.no-cluster-e-nudge"
  bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-cluster-e-smells --heeded unknown >/dev/null 2>&1 &
  jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || true
  exit 0
fi

# No block-level smell — surface any warn-level advisory (non-blocking).
all_hits=$(printf '%s' "$payload" | "$LINT" --path "$file_path" 2>/dev/null)
if [ -n "$all_hits" ]; then
  echo "[hint] atone-lint — review this edit ($file_path):"
  printf '%s' "$all_hits" | msg_lines
fi
exit 0

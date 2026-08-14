#!/usr/bin/env bash
# guard-ai-signature.sh — no harness signatures in anything a human reads.
#
# The commit-trailer ban (memory feedback_no-claude-commit-trailers, atone
# mist-20260811-145935-47) kept leaking onto non-commit surfaces: a PR body
# shipped the footer after the ban was recorded, because the ban's reason is
# "no harness signatures in things humans read" and only commits were gated.
# This gate covers the rest: any Write/Edit that ADDS a signature line to a
# document blocks. Owner disposition D2a, triage 2026-08-14.
#
# Diff-aware like guard-prose-quality: only ADDED lines count, so editing a
# file that already quotes a trailer (a policy doc, an RCA) passes untouched.
# The gcc's policy surfaces are excluded wholesale: they quote these strings
# in order to ban them, and a gate that blocks its own documentation is the
# mention-vs-invocation bug in a new costume.
#
# Mute: touch ~/.claude/.no-ai-signature-gate (machine-wide until removed).
set -uo pipefail
[ -f "$HOME/.claude/.no-ai-signature-gate" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat 2>/dev/null)
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$fp" ] || exit 0

case "$fp" in
  # Policy and ledger surfaces that legitimately QUOTE signature strings.
  "$HOME/.claude/rules/"*|"$HOME/.claude/conventions/"*|"$HOME/.claude/features/"*|\
  "$HOME/.claude/memory/"*|"$HOME/.claude/atone/"*|"$HOME/.claude/COMMIT.md"|\
  "$HOME/.claude/CLAUDE.md"|"$HOME/.claude/scripts/hooks/"*|\
  *test*|*spec*|*fixture*|*mock*) exit 0 ;;
esac

content=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
[ -n "$content" ] || exit 0

old=$(printf '%s' "$input" | jq -r '.tool_input.old_string // empty' 2>/dev/null)
if [ -z "$old" ] && [ -f "$fp" ]; then
  old=$(cat "$fp" 2>/dev/null)
fi
if [ -n "$old" ]; then
  content=$(OLD="$old" NEW="$content" python3 -c '
import os
old = set(os.environ.get("OLD", "").splitlines())
new = os.environ.get("NEW", "").splitlines()
print("\n".join(l for l in new if l not in old))' 2>/dev/null)
  [ -n "$content" ] || exit 0
fi

hits=$(printf '%s' "$content" | rg -n -i \
  'Co-Authored-By:.*Claude|Claude-Session:|Generated with \[?Claude Code|🤖 Generated with|noreply@anthropic\.com' \
  2>/dev/null | head -3)
[ -n "$hits" ] || exit 0

. "$HOME/.claude/scripts/hooks/hook-common.sh" 2>/dev/null || true
if type hook_box_kind >/dev/null 2>&1; then
  reason=$(printf 'This write ADDS a harness signature to a document a human reads.\nOffending:\n%s\n→ remove the signature line(s), then retry; the ban covers every artifact surface, not just commits\nQuote in a policy doc? those paths are excluded; log a false positive via hook-feedback.sh.\nMute: touch ~/.claude/.no-ai-signature-gate' "$hits" | hook_box_kind gate ai-signature)
else
  reason="AI-SIGNATURE GATE: this write adds a harness signature line. Remove it and retry. Offending: $hits"
fi

jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0

#!/usr/bin/env bash
# guard-comment-hygiene.sh — PreToolUse hook on Edit/Write/MultiEdit.
#
# Warns, at write time, when the content about to land carries tier-1 comment
# archeology — [claude@] tags, plan refs (Phase/Track/Round), pre/post-fix
# notes, decorative banners. The existing cleanup-comments-nudge.sh catches the
# same thing at end-of-turn; this catches it BEFORE the write, naming the line,
# so it gets fixed before it lands rather than flagged after.
#
# Graduated from atone slug source-comment-hygiene (S3, persisting despite
# rules/comments.md). Filed as proposals.jsonl prop-20260531-120409-8a.
#
# ADVISORY — always exits 0, never blocks. Reuses the cleanup-comments detector
# so the definition of "finding" stays single-sourced with /cleanup-comments.
#
# Mute:          touch ~/.claude/.comment-hygiene-off
# One-shot skip: COMMENT_HYGIENE_OFF=1

set -uo pipefail

INPUT=$(cat 2>/dev/null || echo "{}")
command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
echo "$INPUT" | jq empty 2>/dev/null || exit 0

[ "${COMMENT_HYGIENE_OFF:-0}" = "1" ] && exit 0
[ -f "$HOME/.claude/.comment-hygiene-off" ] && exit 0

DETECT="$HOME/.claude/skills/cleanup-comments/detect.py"
[ -f "$DETECT" ] || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Edit | Write | MultiEdit) ;; *) exit 0 ;; esac

FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FP" ] && exit 0

# Only languages the detector understands (its comment-syntax table).
case "$FP" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.py) ;;
  *) exit 0 ;;
esac

# The content about to be written, per tool. For Edit/MultiEdit this is just
# the new text — exactly the slice the agent is responsible for this turn.
NEW_CONTENT=""
case "$TOOL" in
  Write)     NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty') ;;
  Edit)      NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty') ;;
  MultiEdit) NEW_CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n") // empty') ;;
esac
[ -z "$NEW_CONTENT" ] && exit 0

# Detector keys off the file extension for comment syntax, so the probe file
# must carry the target's extension.
ext="${FP##*.}"
probe=$(mktemp "/tmp/comment-hygiene-XXXXXX") || exit 0
probe_ext="${probe}.${ext}"
mv "$probe" "$probe_ext" 2>/dev/null || { rm -f "$probe"; exit 0; }
trap 'rm -f "$probe_ext"' EXIT
printf '%s' "$NEW_CONTENT" >"$probe_ext" 2>/dev/null || exit 0

# Tier-1 only — the mechanical, high-confidence strip findings. Report the
# matched comment text, not a line number: for Edit the number is relative to
# the snippet, so the text is the unambiguous handle.
findings=$(python3 "$DETECT" "$probe_ext" 2>/dev/null | jq -r '
  .files[]?.findings[]? | select(.tier == "tier1_strip")
  | "    [\(.category)] \(.text)"' 2>/dev/null)

[ -z "$findings" ] && exit 0

cat >&2 <<EOF
[comment-hygiene] new content for $(basename "$FP") carries comment archeology:

$findings

  These rot the moment the work ships (rules/comments.md). Strip them from this
  write — plan refs, [claude@] tags, pre/post-fix notes, decorative banners.

  Mute: touch ~/.claude/.comment-hygiene-off   ·   One-shot: COMMENT_HYGIENE_OFF=1
EOF
exit 0

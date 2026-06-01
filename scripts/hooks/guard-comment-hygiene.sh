#!/usr/bin/env bash
# guard-comment-hygiene.sh — PreToolUse hook on Edit/Write/MultiEdit.
#
# Warns, at write time, when the content about to land carries comment-style
# smells: tier-1 archeology ([claude@] tags, plan refs, pre/post-fix notes,
# banners), emoji AI-tells, or a long comment block (an essay that should be a
# doc). The existing cleanup-comments-nudge.sh catches archeology at end-of-turn;
# this catches it BEFORE the write, naming the finding, so it's fixed before it
# lands. Em-dash is deliberately not flagged (legitimate prose punctuation).
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

# Mechanical strip findings (tier1) + emoji (a near-pure AI-tell — humans rarely
# emoji source comments). Em-dash is deliberately excluded: it's legitimate prose
# punctuation, so flagging it floods with false positives. Report the matched
# text, not a line number (for Edit the number is snippet-relative).
findings=$(python3 "$DETECT" "$probe_ext" 2>/dev/null | jq -r '
  .files[]?.findings[]?
  | select(.tier == "tier1_strip" or (.tier == "tier2_voice" and .category == "emoji"))
  | "    [\(.category)] \(.text)"' 2>/dev/null)

# Verbose-essay tell: the detector is judgment-only here, but a long run of
# consecutive comment lines is a decent mechanical proxy (rules/comments.md:
# docstrings >8 lines move to a doc). Count the longest comment-prefix run.
longest_run=$(printf '%s\n' "$NEW_CONTENT" | awk '
  /^[[:space:]]*(\/\/|#|\*)/ { run++; if (run > max) max = run; next }
  { run = 0 }
  END { print max + 0 }')
long_block=""
if [ "${longest_run:-0}" -gt 12 ]; then
  long_block="    [long-comment-block] ${longest_run} consecutive comment lines — consider a doc"
fi

[ -z "$findings" ] && [ -z "$long_block" ] && exit 0

# Join the two finding sources (either may be empty).
report_body="$findings"
if [ -n "$long_block" ]; then
  [ -n "$report_body" ] && report_body="$report_body
$long_block" || report_body="$long_block"
fi

msg="[comment-hygiene] new content for $(basename "$FP") has comment-style smells:
$report_body
rules/comments.md: strip archeology (plan refs, [claude@] tags, banners), drop emoji/AI-tells, move long comment blocks (>8 lines) to a doc. (mute: touch ~/.claude/.comment-hygiene-off)"

# additionalContext (stdout JSON) → the agent — the only non-blocking channel any
# audience reads (user-transcript channels are all invisible; see
# hooks-tui-limits). The directive makes the agent relay this to the user.
msg="$msg
→→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."
jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
exit 0

#!/usr/bin/env bash
# guard-comment-verbosity.sh — PostToolUse[Edit|Write|MultiEdit], SYNCHRONOUS nudge.
#
# Catches the "code essay" the user keeps hand-pruning: an over-long docstring or
# a wall of comments that got added this turn. The sibling guard-comment-hygiene
# (PreToolUse) blocks decorative banners / plan-refs / archeology — the NOISE
# dimension. This one owns the VERBOSITY dimension: length. It nudges (never
# blocks) so a fuzzy signal can't earn a mute.
#
# Fires ONLY on a clearly-excessive block in the ADDED content:
#   - a docstring / block comment over ~10 non-blank prose lines (module/file
#     headers get a higher ~16 bar), OR
#   - a run of more than ~10 consecutive full-line comments (tightened from 8
#     after corpus replay showed 9-line runs are routinely legitimate).
# Tuned HARD for precision (rules/comments.md: docstrings >8 lines move to a doc):
# a single-line comment, a 2-4 line docstring, a license header, a structured API
# doc (@param/@returns), a pragma block (eslint-disable/@ts-/noqa), a decorative
# banner (comment-hygiene's job — never double-fired here), and a module
# orientation all pass. "Prose restates the code" is left to the agent — a line
# regex can't tell an essay from a load-bearing caveat (cleanup-comments/detect.py
# makes the same call), so length is the only mechanical proxy encoded here.
#
# Output: additionalContext on stdout (the one non-blocking channel the agent
# reads). Exit 0 always. Silent on any doubt (no jq/python3, wrong file type).
# Mute: touch ~/.claude/.no-comment-verbosity-gate

set -uo pipefail
[ -f "$HOME/.claude/.no-comment-verbosity-gate" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

DETECT="$(dirname "${BASH_SOURCE[0]}")/comment-verbosity-detect.py"
[ -f "$DETECT" ] || exit 0

INPUT=$(cat 2>/dev/null || echo "{}")
echo "$INPUT" | jq empty 2>/dev/null || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in Edit | Write | MultiEdit) ;; *) exit 0 ;; esac

FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FP" ] && exit 0
case "$FP" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs | *.mts | *.cts | *.py) ;;
  *) exit 0 ;;
esac

# The text this turn is responsible for. For Edit/MultiEdit that's the new_string
# only — exactly the slice the agent just authored (matches comment-hygiene).
NEW_CONTENT=$(echo "$INPUT" | jq -r '
  .tool_input.content
  // .tool_input.new_string
  // ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  // empty' 2>/dev/null)
[ -z "$NEW_CONTENT" ] && exit 0

# The detector keys comment syntax off the extension, so the probe must carry it.
ext="${FP##*.}"
probe=$(mktemp "${TMPDIR:-/tmp}/comment-verbosity-XXXXXX") || exit 0
probe_ext="${probe}.${ext}"
mv "$probe" "$probe_ext" 2>/dev/null || { rm -f "$probe"; exit 0; }
trap 'rm -f "$probe_ext"' EXIT
printf '%s' "$NEW_CONTENT" >"$probe_ext" 2>/dev/null || exit 0

result=$(python3 "$DETECT" "$probe_ext" 2>/dev/null)
[ -z "$result" ] && exit 0

worst_lines=$(printf '%s' "$result" | jq -r '.worst.lines // 0' 2>/dev/null)
[ "${worst_lines:-0}" -gt 0 ] 2>/dev/null || exit 0

# Render the findings (worst first, cap 3) into the nudge body.
body=$(printf '%s' "$result" | jq -r '
  [.findings[] | {lines, kind, start, threshold, sample}]
  | sort_by(-.lines) | .[:3][]
  | "    [\(.kind)] \(.lines) prose lines at line \(.start) (>\(.threshold)) — \(.sample // "")"
  ' 2>/dev/null)
[ -z "$body" ] && exit 0

# Telemetry from birth. Never let it touch stdout / exit status.
bash "$HOME/.claude/scripts/hooks/warn-log.sh" --hook guard-comment-verbosity --action nudge --heeded unknown --cwd "$(printf '%s' "$INPUT" | jq -r '.cwd//empty' 2>/dev/null)" --target "$FP" >/dev/null 2>&1 || true

msg="[comment-verbosity] the content just written to $(basename "$FP") carries an over-long comment block:
$body
rules/comments.md: a docstring over ~8 lines is an essay — move the depth to a doc and link it; strip WHAT-restates-the-code prose, keep the WHY. This is a nudge (never a block); trim it or leave it. Banners/plan-refs are a separate gate. (mute: touch ~/.claude/.no-comment-verbosity-gate)
→→ SURFACE this to the user in your reply as a bordered callout (rules/surface-hook-nudges-to-user.md)."

jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $c}}' 2>/dev/null || true
exit 0

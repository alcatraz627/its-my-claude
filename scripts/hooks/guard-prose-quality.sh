#!/bin/bash
# Hard gate: banned prose tells cannot ship into written artifacts. Blocks a
# Write/Edit that puts earnest-prose em-dashes (owner budget: zero), a
# verdict-first opener, or a heavily slop-scored body into a prose file
# (.md/.html/.txt). Chat replies are the prose-smell Stop hook's surface;
# this guard covers the layer that shipped the 2026-07-28 banner incident
# (atone ai-smell-prose-against-stored-voice): prose written INTO files.
#
# Scoring engine: scripts/style/prose-lint.py (strips code fences, inline
# code, blockquotes, and table rows first — quoted defect examples never
# count). Style-system paths that quote banned material by design are exempt.
# Mute (owner only): touch ~/.claude/.no-prose-quality-gate  ·  migration 0041
set -uo pipefail
[ -f "$HOME/.claude/.no-prose-quality-gate" ] && exit 0

input=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
mode=""
case "$fp" in
  *.md|*.html|*.txt) mode="prose" ;;
  *.ts|*.tsx|*.js|*.jsx|*.vue|*.svelte|*.py) mode="code" ;;
  *) exit 0 ;;
esac
case "$fp" in
  *test*|*spec*|*__tests__*|*fixture*|*mock*) exit 0 ;;
esac
case "$fp" in
  */style/*|*/atone/*|*/i-dream/*|*/sweep/*|*language-quality*|*/ste-writing/*|*/node_modules/*|*/derived/*|*thesaurus*) exit 0 ;;
esac

content=$(printf '%s' "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
[ -n "$content" ] || exit 0

if [ "$mode" = "code" ]; then
  findings=$(printf '%s' "$content" | python3 "$HOME/.claude/scripts/style/code-copy-lint.py" --json - 2>/dev/null | jq -r '.findings[:3] | map("  [" + (.tells|join("|")) + "] " + .text) | join("\n")' 2>/dev/null)
  if [ -n "$findings" ]; then
    jq -n --arg r "COPY BLOCKED for $fp — user-facing string literals carry banned language tells:
$findings
UI copy follows the same rules as prose (conventions/language-quality.md): no connective dashes, no unverified claims, no marketing words. Reword the strings and retry. Placeholder glyphs and comments are not counted." '{decision:"block", reason:$r}'
  fi
  exit 0
fi

report=$(printf '%s' "$content" | python3 "$HOME/.claude/scripts/style/prose-lint.py" --json - 2>/dev/null) || exit 0
dashes=$(printf '%s' "$report" | jq -r '.violations.two_split_dash // 0' 2>/dev/null)
verdict=$(printf '%s' "$report" | jq -r '.violations.verdict_first_opener // 0' 2>/dev/null)
score=$(printf '%s' "$report" | jq -r '.score // 0' 2>/dev/null)

fail=""
[ "${dashes:-0}" -gt 0 ] 2>/dev/null && fail="$fail ${dashes} connective em/en-dash(es) in earnest prose (owner budget: zero; quotes/code/tables are already excluded)."
[ "${verdict:-0}" -gt 0 ] 2>/dev/null && fail="$fail Verdict-first opener (facts before conclusions; the done-verdict is the owner's)."
over=$(python3 -c "print(1 if float('${score:-0}' or 0) > 8 else 0)" 2>/dev/null)
[ "${over:-0}" = "1" ] && fail="$fail prose-lint score ${score}/100w (block line: 8)."

if [ -n "$fail" ]; then
  spans=$(printf '%s' "$report" | jq -r '[.spans.two_split_dash[]?, .spans.verdict_first_opener[]?] | .[:3] | map("  > " + .) | join("\n")' 2>/dev/null)
  jq -n --arg r "PROSE BLOCKED for $fp —$fail
$spans
Rewrite per conventions/language-quality.md (short sentences, no two-split chains, facts first), then retry. Check any draft: python3 ~/.claude/scripts/style/prose-lint.py" '{decision:"block", reason:$r}'
  exit 0
fi
exit 0

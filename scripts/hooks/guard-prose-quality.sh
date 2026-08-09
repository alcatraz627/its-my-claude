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
  *.json)
    # Only user-facing-copy JSON is gated; internal configs, catalogs, and
    # caches carry conventions of their own (mcp-catalog's dashes, report data).
    case "$fp" in
      *decision-page*|*/decision-pages/*|*locale*|*i18n*|*/lang/*|*strings.json|*copy.json) mode="code" ;;
      *) exit 0 ;;
    esac ;;
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

# An .html file is often an application, not a document. Its <style> and
# <script> bodies are code and score as gibberish prose (a CSS token block
# measured 14.95 against a block line of 8). Judge only the markup's text.
if [ "$mode" = "prose" ]; then
  case "$fp" in
    *.html)
      content=$(printf '%s' "$content" | python3 -c 'import re,sys
s=sys.stdin.read()
s=re.sub(r"(?is)<style\b.*?(</style>|\Z)"," ",s)
s=re.sub(r"(?is)<script\b.*?(</script>|\Z)"," ",s)
# An Edit payload is a bare fragment, so tag-stripping alone misses it. Drop
# lines whose shape is code: braces, arrows, var(), a selector head, or a
# declaration. A bare semicolon is NOT a marker; house prose is full of them.
# A statement ending in a semicolon AND carrying an assignment or a call is
# code though, which is what a braceless JS line looks like. Comments stay:
# they carry no terminator, so they still reach the linter as the prose they are.
CODE = re.compile(r"[{}]|=>|var\(--|^\s*[.#@][\w-]+[\s,{]|^\s*:root|[\w-]+\s*:\s*\S+;|[=(].*;\s*$")
# A dash is the owner zero-budget tell, and a UI string carrying one IS prose,
# so no shape rule may strip that line. Without this, prose ending in ";"
# escapes scoring entirely.
KEEP = re.compile(r"[–—]")
sys.stdout.write("\n".join(l for l in s.split("\n") if KEEP.search(l) or not CODE.search(l)))' 2>/dev/null)
      # A pure code/markup edit leaves no prose worth judging.
      words=$(printf '%s' "$content" | tr -cs "[:alpha:]" " " | wc -w | tr -d " ")
      [ "${words:-0}" -ge 25 ] 2>/dev/null || exit 0
      ;;
  esac
fi

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

#!/usr/bin/env bash
# atone-rca-lint.sh — validates an RCA file BEFORE atone.sh add locks it.
#
# Called automatically from atone.sh add when --rca-content or --rca-file is
# present. Fails fast with specific reasons; agent must fix and retry.
#
# Checks (each one a separate exit point with clear message):
#   1. Has YAML frontmatter (--- ... --- block at top)
#   2. H1 is on a single line (no mid-line break before the next line of body)
#   3. No ellipsis characters (…) in table cells — signal of pre-rendered output
#   4. No row of every-line-2-space-indent (signal of TTY-render-saved-as-source)
#   5. Procedure section has at most ONE numbered check (template specifies "single")
#   6. Has required sections: TL;DR, Symptom progression OR What happened, Procedure
#
# Usage:
#   bash ~/.claude/scripts/atone-rca-lint.sh <path-to-rca.md>
# Exit codes:
#   0 - lint clean
#   1 - lint failed (stderr describes which check)
#   2 - usage error (no file path, file doesn't exist)
#
# Bypass: ATONE_NO_RCA_LINT=1 in the env.

set -uo pipefail

# Source common helpers if available (just for colors / formatting)
# shellcheck disable=SC1091
[ -f "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh" ] && \
  source "$(dirname "${BASH_SOURCE[0]}")/atone-common.sh"

# Allow opt-out
if [ "${ATONE_NO_RCA_LINT:-0}" = "1" ]; then
  exit 0
fi

[ $# -lt 1 ] && { echo "atone-rca-lint: usage: $0 <rca-file>" >&2; exit 2; }
RCA="$1"
[ -f "$RCA" ] || { echo "atone-rca-lint: file not found: $RCA" >&2; exit 2; }

FAILED=0
fail() {
  printf '  %s✗%s %s\n' "${C_RED:-}" "${C_RESET:-}" "$1" >&2
  FAILED=1
}
ok() {
  printf '  %s✓%s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$1" >&2
}

# ─── 1. YAML frontmatter ─────────────────────────────────────────
# Expect first line to be `---`, then key:value lines, then `---`.
if head -1 "$RCA" | grep -qxE '^---[[:space:]]*$'; then
  # Find the closing ---
  if awk 'NR==1 && /^---/{next} /^---/{print "found"; exit} NR>30{exit}' "$RCA" | grep -q found; then
    ok "frontmatter present + closes within first 30 lines"
  else
    fail "frontmatter opening --- found but no closing --- within 30 lines"
  fi
else
  fail "missing YAML frontmatter (file must start with '---' on line 1; see /atone SKILL.md RCA template)"
fi

# ─── 2. H1 on a single line ──────────────────────────────────────
# Find first `# ` heading. Check that the next line is blank OR another heading,
# NOT a continuation (i.e., wrapped heading text).
H1_LINE=$(awk '/^# /{ print NR; exit }' "$RCA")
if [ -n "$H1_LINE" ]; then
  NEXT_LINE=$((H1_LINE + 1))
  NEXT_CONTENT=$(sed -n "${NEXT_LINE}p" "$RCA")
  # OK if next line is blank, starts with #, or starts with `>` (block quote)
  if [ -z "$(echo "$NEXT_CONTENT" | tr -d ' \t')" ] || \
     echo "$NEXT_CONTENT" | grep -qE '^[[:space:]]*(#|>)'; then
    ok "H1 is single-line"
  else
    fail "H1 at line $H1_LINE appears to wrap to line $NEXT_LINE — markdown renders second line as body text. Keep H1 on one line."
  fi
else
  fail "no H1 heading found (must have a '# <title>' line)"
fi

# ─── 3. No ellipsis in tables ────────────────────────────────────
# Strong signal of pre-rendered output (truncated cell labels like "What I assu…")
if grep -nE '\|.*…' "$RCA" >/dev/null; then
  fail "ellipsis (…) found inside a table — this is the signature of TTY-rendered output saved as source. Tables should be written as plain markdown: \`| col | col |\\n|---|---|\\n| val | val |\`"
  grep -nE '\|.*…' "$RCA" | head -3 | sed 's/^/      /' >&2
else
  ok "no ellipsis in tables (no pre-rendered output detected)"
fi

# ─── 4. No every-line-leading-indent (TTY-render signature) ──────
# If the majority of non-blank lines start with 2+ spaces, that's the gum-output-
# saved-as-source pattern. Allow code blocks (indented 4+) and intentional
# indented bullets, but a heavy indent ratio is a flag.
TOTAL=$(awk 'NF > 0 { n++ } END { print n+0 }' "$RCA")
INDENTED=$(awk '/^  [^ ]/ { n++ } END { print n+0 }' "$RCA")
if [ "$TOTAL" -gt 10 ] && [ "$INDENTED" -gt 0 ]; then
  RATIO=$((100 * INDENTED / TOTAL))
  if [ "$RATIO" -gt 50 ]; then
    fail "$RATIO% of content lines start with leading whitespace — signature of TTY-rendered output saved as source. Write plain markdown, don't pipe through renderers before saving."
  else
    ok "leading-indent ratio: $RATIO% (acceptable)"
  fi
else
  ok "leading-indent check: $INDENTED indented / $TOTAL total content lines"
fi

# ─── 5. Procedure section has ≤1 numbered check ──────────────────
# Find the `## Procedure` heading; count numbered list items between it and
# the next `## ` heading.
PROC_LINE=$(awk '/^## [Pp]rocedure/{print NR; exit}' "$RCA")
if [ -n "$PROC_LINE" ]; then
  # Find the next `## ` heading after PROC_LINE
  END_LINE=$(awk -v start="$PROC_LINE" 'NR > start && /^## /{print NR; exit}' "$RCA")
  [ -z "$END_LINE" ] && END_LINE=$(wc -l < "$RCA")
  # Count numbered list items (`^N. ` where N is a digit)
  NUMBERED=$(sed -n "$((PROC_LINE + 1)),${END_LINE}p" "$RCA" | grep -cE '^[0-9]+\.[[:space:]]' || true)
  if [ "$NUMBERED" -le 1 ]; then
    ok "Procedure has $NUMBERED numbered check(s) (template specifies single check)"
  else
    fail "Procedure section has $NUMBERED numbered steps — template specifies 'the single at-action-time check that would have prevented this'. Collapse to one runnable check, OR use a blockquote (>) for the single procedure."
  fi
else
  fail "no '## Procedure' section found — template requires it"
fi

# ─── 6. Required sections present ────────────────────────────────
REQUIRED=("TL;DR" "Procedure")
for sec in "${REQUIRED[@]}"; do
  if grep -qE "^## ${sec}\$" "$RCA" || grep -qE "^## ${sec}([[:space:]]|$)" "$RCA"; then
    ok "section present: ## $sec"
  else
    fail "missing required section: ## $sec"
  fi
done

# ─── Verdict ─────────────────────────────────────────────────────
if [ "$FAILED" -eq 1 ]; then
  printf '\n%satone-rca-lint: REJECTED.%s Fix the issues above and retry.\n' \
    "${C_RED:-}" "${C_RESET:-}" >&2
  printf 'Bypass for one event: ATONE_NO_RCA_LINT=1 bash %s/atone.sh add ...\n' \
    "$(dirname "${BASH_SOURCE[0]}")" >&2
  exit 1
fi

printf '\n%satone-rca-lint: OK.%s\n' "${C_GREEN:-}" "${C_RESET:-}" >&2
exit 0

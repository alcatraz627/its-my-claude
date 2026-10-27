#!/usr/bin/env bash
# rules-index.sh: regenerate rules/00-index.md, the compact always-on menu of
# behavioral rules. DERIVED from each rule's `brief:` frontmatter; never hand-edit
# the generated table (fix a rule's `brief:` and re-run instead).
#
# Why an index exists: rules/*.md autoload in full every session (native platform
# behavior, ~26-33k tokens). This one-line-per-rule menu is the "overview" layer for
# progressive disclosure: an agent scans it to decide which full rule to read, and it
# is the guaranteed fallback when no smarter selector is available.
#
# The Load column: `always` = the rule autoloads every session; `scoped` = the rule
# has a `paths:` block, so it is NOT always-on (it loads only when Claude touches a
# matching file, or must be Read from this menu when it applies).
#
# Run after adding / renaming / removing a rule (or wire it to a hook).
set -uo pipefail

RULES="$HOME/.claude/rules"
OUT="$RULES/00-index.md"
today=$(date '+%Y-%m-%d')
stamp=$(date '+%Y-%m-%d %H:%M')

{
  cat <<EOF
---
brief: Compact always-on menu of every behavioral rule (name + load-mode + one-line gist). DERIVED from each rule's brief via scripts/rules-index.sh; the overview layer for progressive disclosure.
triggers:
  - topic:rules-index
  - phrase:"which rule applies"
related:
  - PLACEMENT.md
  - rules/README.md
tier: 0
category: rules
updated: $today
stale_after_days: 365
---

# Rules index

One line per rule in \`rules/\`. Scan it, then Read \`rules/<name>.md\` when a rule applies.
\`always\` = loaded every session; \`scoped\` = not loaded, Read it when it applies.
DERIVED from each rule's \`brief:\`; regenerate with \`bash ~/.claude/scripts/rules-index.sh\`.

Regenerated $stamp.

| Rule | Load | Gist |
|------|------|------|
EOF

  for f in "$RULES"/*.md; do
    b=$(basename "$f" .md)
    case "$b" in README | 00-index) continue ;; esac
    # `gist:` wins; else the brief's first sentence, capped near 20 words. The
    # full brief loads with the rule itself, so repeating it here was paying for
    # every rule twice in every session (owner D1a, 2026-09-18).
    br=$(sed -n 's/^gist: *//p' "$f" | head -1)
    # Capped at 13 words, ending at the first sentence or clause break after at
    # least 6 words, no trailing ellipsis: the row only has to say when the rule
    # applies; the rule file itself has the rest.
    [ -z "$br" ] && br=$(sed -n 's/^brief: *//p' "$f" | head -1 | awk '{ n=split($0,w," "); s=""; for(i=1;i<=n&&i<=13;i++){ s=s (i>1?" ":"") w[i]; if(i>=6 && w[i] ~ /[.;:]$/) break } sub(/[ ,;:.]+$/,"",s); while (s ~ / (a|an|the|of|on|in|to|as|or|and|its|by|if|is|that|for|with|an|it|not|pin|MUST|keep|their|your|you|are|at|from|every|any) *$/) { sub(/ [^ ]+ *$/,"",s) } print s }')
    # An em/en-dash never reaches the index: prose-lint budgets them at zero and
    # copying them out of a brief leaked them into the always-loaded menu.
    br=$(printf '%s' "$br" | perl -CSD -pe 's/\s[\x{2014}\x{2013}]\s/, /g; s/[\x{2014}\x{2013}]/-/g' | sed 's/|/\\|/g')
    [ -z "$br" ] && br="(no brief; add frontmatter)"
    load=always
    grep -q '^paths:' "$f" && load=scoped
    printf '| `%s` | %s | %s |\n' "$b" "$load" "$br"
  done
} >"$OUT"

echo "rules index regenerated: $OUT ($(grep -c '^| `' "$OUT") rules)"

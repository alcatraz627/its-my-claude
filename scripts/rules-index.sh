#!/usr/bin/env bash
# rules-index.sh — regenerate rules/00-index.md, the compact always-on menu of
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

One line per behavioral rule in \`rules/\`. This is the menu: scan it, then read the
full \`rules/<name>.md\` when a rule applies to what you are about to do. DERIVED from
each rule's \`brief:\` frontmatter; regenerate with \`bash ~/.claude/scripts/rules-index.sh\`.

The **Load** column: \`always\` = autoloaded every session; \`scoped\` = NOT always-on (it
has a \`paths:\` block, so it loads only when Claude touches a matching file, or you must
\`Read\` it from this menu when it applies).

Regenerated $stamp.

| Rule | Load | Gist |
|------|------|------|
EOF

  for f in "$RULES"/*.md; do
    b=$(basename "$f" .md)
    case "$b" in README | 00-index) continue ;; esac
    br=$(sed -n 's/^brief: *//p' "$f" | head -1 | sed 's/|/\\|/g')
    [ -z "$br" ] && br="(no brief; add frontmatter)"
    load=always
    grep -q '^paths:' "$f" && load=scoped
    printf '| `%s` | %s | %s |\n' "$b" "$load" "$br"
  done
} >"$OUT"

echo "rules index regenerated: $OUT ($(grep -c '^| `' "$OUT") rules)"

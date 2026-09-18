---
brief: Before adding a component, control, or pattern to a file, read how its siblings solve the same shape and follow them. A choice that is fine in isolation is a defect when every neighbouring file already answered the question differently, and neither a compiler nor a test can see it.
triggers:
  - topic:conventions
  - topic:siblings
  - phrase:"add a component"
  - phrase:"new page"
  - phrase:"same pattern"
related:
  - rules/right-sized-code.md
  - rules/grep-scope-before-claiming-absence.md
  - rules/audit-file-character-before-applying-global-rule.md
tier: 2
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# Read the siblings before you add to a file

Before adding a component, control, list, derivation, hook or table: open the two or three files that already answer the same shape, and follow them, or say in one sentence why this case differs. Deviating is allowed; deviating silently is the defect, because it compiles, the tests pass, and only the owner notices after it ships.

A sibling is the nearest answer to the same question, not the nearest path: other list pages for a list, the file's other derivations for a derivation, the hooks on the same event for a hook, every other table in the product for a table. Grep the concept, not the filename.

Not a ban on new patterns and not the same as `rules/grep-scope-before-claiming-absence.md` (that fires on absence claims; this fires when adding something that exists).

Diagnostic: writing a component, derivation or list without having opened one neighbouring file that does the same job.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/added-scope-without-checking-siblings.md`

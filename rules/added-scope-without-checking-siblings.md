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
updated: 2026-09-01
stale_after_days: 180
---

# Read the siblings before you add to a file

Before adding a component, control, list, or pattern, open the two or three
files nearest it that already solve the same shape, and follow what they do.

This is not a style preference. A choice that is defensible in isolation becomes
a defect the moment every neighbouring file answered the same question
differently, because the reader now has to hold two conventions instead of one,
and nothing mechanical can see the divergence. It compiles. The tests pass. Only
a person notices, usually the owner, usually after it ships.

Graduated from atone slug `added-scope-without-checking-siblings`, 4 events, S3.

## What a sibling is

The nearest files that answer the same question, not the nearest files by path.

- Adding a list page? The other list pages.
- Adding a derived boolean? How the file's other derivations are written.
- Adding a hook? The hooks on the same event with the same matcher.
- Adding a table? Every other table in the product.

## The check

1. Name the shape you are about to add: a list, a derivation, a toggle, a gate.
2. Find two or three existing answers to that shape. Grep the concept, not the
   filename, because the sibling rarely shares your file's name.
3. Follow them, or say in one sentence why this case differs.

Step 3 is the whole rule. Deviating is allowed and sometimes right; deviating
**silently** is what costs, because the next reader cannot tell a decision from
an oversight.

## Two events, both shipped, both invisible to every gate

**An inline IIFE for one boolean.** A row-level precondition on the Spider
button was written as `(() => { ... })()` hosting one derivation plus a comment
block. Every sibling derivation in that file was a named const. The IIFE was
valid, typed, and tested.

**A table that did not paginate.** The Taxonomy and Attributes viewers rendered
their full row sets, 2,452 rows in one case, with a plain kit `Table`. Every
other list surface in the product paginates through the DataTable model. Nothing
failed. It was simply the only pair of pages in the product that behaved
differently, which is exactly the cost.

## What this does NOT mean

- Not a ban on new patterns. A genuinely better answer is welcome; it just gets
  said out loud, and ideally applied to the siblings too rather than leaving the
  product with two.
- Not a mandate to read the whole tree. Two or three real siblings is the bar.
- Not the same as [[grep-scope-before-claiming-absence]], which fires when you
  are about to claim a thing does not exist. This one fires when you are about to
  add a thing that does.

## Diagnostic signal

You are writing a component, a derivation, or a list and you have not opened a
single neighbouring file that already does the same job.

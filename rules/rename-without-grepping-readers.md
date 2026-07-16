---
brief: A rename is not done until you have grepped the OLD name's readers across the full tree — including the string-keyed ones (tags, marker paths, config keys) no compiler can see. Documenting a rename in a review is not reviewing it.
triggers:
  - topic:rename
  - phrase:"renamed"
  - phrase:"rename the"
  - phrase:"breaking rename"
  - phrase:"stale caller"
related:
  - rules/grep-scope-before-claiming-absence.md
  - rules/structural-claim-without-reading-code.md
  - rules/testing.md
tier: 1
category: rules
updated: 2026-07-16
stale_after_days: 180
---

# Grep the readers before you call a rename done

When you change the name of anything that something else refers to **by that name**,
the rename is not finished when the thing compiles. It is finished when every reader
of the OLD name has been found and updated, or proven absent. Search the full tree
for the old name first; treat a green build as no evidence at all.

Graduated from atone slug `review-missed-stale-caller-after-rename` — **S3 twice**,
six weeks apart, on two unrelated surfaces.

## Why a green build proves nothing here

Both incidents broke through a reader the build could not see:

- **2026-05-31** — a release review *documented* a breaking rename and never grepped
  callers. An **inline import** bound the old name at call time, so nothing failed
  statically; the stale caller surfaced in prod.
- **2026-07-13** — migration 0030 renamed a **tag**. The dedup reader keyed on that
  tag string and silently stopped matching. No symbol, no import, nothing to fail.

The common shape: the reference is resolved at **runtime, by string**, so type
checks, imports, and the test suite are all structurally blind to it.

## It is not just code symbols

Grep for every kind of name a reader can key on:

- exported functions/classes/constants — including **lazy or inline imports**
- **tag / label / status strings** matched by a consumer (the migration-0030 class)
- marker + lock file names, `/tmp` path conventions built by concatenation
- config / JSON / JSONL keys, env var names, hook names, skill names
- anything a doc, migration, or shell script names as a literal

So the search must cover **non-code files too** — configs, migrations, docs, data
ledgers, shell scripts — not just the language's source glob.

## The check

1. Grep the **OLD** name across the full project tree (per
   [[grep-scope-before-claiming-absence]] — the whole tree, not the renamed file's
   directory), with ignored + hidden files included.
2. For each hit: update it, or state why it is genuinely unrelated.
3. Only then is the rename done. If you cannot enumerate the readers, you do not
   know the rename is safe.

## Reviewing a rename

**Documenting a rename is not reviewing it.** The 2026-05-31 review named the
breaking rename in its own notes and still shipped the break, because naming it and
grepping for its readers are different acts. A review that mentions a rename without
a reader sweep has not reviewed the rename.

## What this rule does NOT mean

- Not every identifier edit needs a tree sweep — a purely local variable, or a
  symbol whose only reader is the file you are editing, is fine. The trigger is a
  name that crosses a file/process/data boundary.
- Not a substitute for the compiler where the compiler *does* work. It exists for
  the readers the compiler cannot see.

## Diagnostic signal

You renamed something, and your evidence that nothing broke is "it builds" or "the
tests are green." Neither one reads a string key. Grep the old name.

## Related

- [[grep-scope-before-claiming-absence]] — the sibling: grep the full tree before
  asserting a thing is not there
- `rules/testing.md` § `[mutation-test-the-guard]` — the drift-guard class: a check
  that pins its own copy of a name proves only that it agrees with itself
- `/skeptical-review` heuristic 1 (upstream/downstream usage) — the review-time
  mechanism for this
- Atone lineage: `bash ~/.claude/scripts/atone.sh search review-missed-stale-caller`

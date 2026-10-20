---
brief: A rename, a corrected claim or a changed owner ruling is not done until every reader of the old version is found. That includes string-keyed readers, prompts, tests that pin the old behaviour, other repos, and off-tree surfaces (PR body, comments, Slack). Documenting a rename in a review is not reviewing it.
triggers:
  - topic:rename
  - phrase:"renamed"
  - phrase:"rename the"
  - phrase:"breaking rename"
  - phrase:"stale caller"
  - phrase:"fixed everywhere"
  - phrase:"none left"
  - phrase:"ruling changed"
related:
  - rules/grep-scope-before-claiming-absence.md
  - rules/structural-claim-without-reading-code.md
  - rules/read-the-comments-on-a-pr-you-raised.md
  - rules/testing.md
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; binds during renames and corrected claims; read from the index menu.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 1
category: rules
updated: 2026-10-20
stale_after_days: 180
---

# Grep the readers before you call a rename done

When you change the name of anything that something else refers to **by that name**,
the rename is not finished when the thing compiles. It is finished when every reader
of the OLD name has been found and updated, or proven absent. Search the full tree
for the old name first, and treat a green build as no evidence at all.

Graduated from atone slug `review-missed-stale-caller-after-rename` (**S3 twice**,
six weeks apart, on two unrelated surfaces).

## Why a green build proves nothing here

Both incidents broke through a reader the build could not see:

- **2026-05-31.** A release review *documented* a breaking rename and never grepped
  callers. An **inline import** bound the old name at call time, so nothing failed
  statically, and the stale caller surfaced in prod.
- **2026-07-13.** Migration 0030 renamed a **tag**. The dedup reader keyed on that
  tag string and silently stopped matching. There was no symbol and no import, so nothing could fail.

The common shape is a reference resolved at **runtime, by string**, so type
checks, imports and the test suite are all structurally blind to it.

## It is not just code symbols

Grep for every kind of name a reader can key on:

- exported functions, classes and constants, including **lazy or inline imports**
- **tag, label and status strings** matched by a consumer (the migration-0030 class)
- marker and lock file names, and `/tmp` path conventions built by concatenation
- config, JSON and JSONL keys, env var names, hook names and skill names
- anything a doc, migration or shell script names as a literal

So the search must cover **non-code files too** (configs, migrations, docs, data
ledgers, shell scripts), and the language's source glob is not enough.

## The surfaces are not all in the tree

Everything above assumes the readers live in files you can grep. Some do not, and
those are the ones that survive a clean sweep.

The same discipline governs a **corrected claim**, and a renamed symbol is only one case. When
you find that something you wrote is wrong, its other copies are readers of the old
version in exactly the way a stale caller is.

Surfaces `git grep` cannot reach:

- the **PR title and description**, which is the first thing a reviewer opens
- **PR and issue comments**, including ones you wrote earlier in the same thread
- **commit messages already pushed**, which cannot be edited without a rewrite, so
  the correction goes in the next commit's message instead
- Slack messages, docs published to a site, and anything living in another repo
- anything posted under a human's account, where a stale claim reads as theirs

So the check has two halves. Grep the tree, then **enumerate the surfaces** by
asking where else this claim was stated, and go look at each one. A tree that
greps clean is evidence about the tree and nothing else.

**Provenance, 2026-08-19.** On walmart-mvp PR #59 the review bot found that a
guidebook's central mechanism was wrong. It was corrected in three cited places, a
fourth was found by grepping the claim rather than the citations, and the tree then
grepped clean three times. The same wrong mechanism was still sitting in the PR
description, word for word, and in two GitHub comments. Nobody had looked, because
the sweep had been scoped to the artifact being edited.

**A changed ruling is the same case.** The owner reverses a ruling. Every place that states the old one is now a reader of the old version. That means prompt text, tool descriptions, help copy, playbooks, docs a bot can load, the same rule in another repo, and tests. Grep the old ruling's words and its effect. Retire each copy in the change that applies the new ruling. A test that pins the old behaviour is the worst copy: it fails the fix. (Provenance: slack-automation, 2026-10, nine ledger rows; atone mist-20261019-103024-59.)

## The check

1. Grep the **OLD** name across the full project tree (per
   [[grep-scope-before-claiming-absence]]: the whole tree, and not the renamed file's
   directory), with ignored and hidden files included.
2. For each hit, update it, or state why it is genuinely unrelated.
3. Enumerate the off-tree surfaces above and check each one by hand.
4. Only then is the rename done. If you cannot enumerate the readers, you do not
   know the rename is safe.

## Reviewing a rename

**Documenting a rename is not reviewing it.** The 2026-05-31 review named the
breaking rename in its own notes and still shipped the break, because naming it and
grepping for its readers are different acts. A review that mentions a rename without
a reader sweep has not reviewed the rename.

## What this rule does NOT mean

- Not every identifier edit needs a tree sweep. A purely local variable, or a
  symbol whose only reader is the file you are editing, is fine. The trigger is a
  name that crosses a file, process or data boundary.
- It does not replace the compiler where the compiler *does* work. It exists for
  the readers the compiler cannot see.

## Diagnostic signal

You renamed something, and your evidence that nothing broke is "it builds" or "the
tests are green." Neither one reads a string key. Grep the old name.

## Related

- [[grep-scope-before-claiming-absence]]: the sibling rule, which says to grep the full tree before
  asserting a thing is not there
- `rules/testing-patterns.md` § `[mutation-test-the-guard]`: the drift-guard class, where a check
  that pins its own copy of a name proves only that it agrees with itself
- `/skeptical-review` heuristic 1 (upstream/downstream usage): the review-time
  mechanism for this
- Atone lineage: `bash ~/.claude/scripts/atone.sh search review-missed-stale-caller`

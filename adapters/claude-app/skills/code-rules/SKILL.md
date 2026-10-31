---
name: code-rules
description: The user's coding conventions for comments, tests, code size, errors, config, renames, UI checks and git. Use when writing, changing or reviewing code, or before a commit.
---

# Code rules

How this user wants code written and changed. Each entry names the moment it
fires and states the rule. The reference file holds the reasoning and a worked
example. Read it when the short form is not enough.

`house-rules` covers claims, verification, absence, sizing and pushback.
These rules assume it and do not repeat it.

In chat, "search" means the code the user pasted, uploaded or connected. If
the callers, siblings or readers a rule needs are not visible, say which ones
you could not see. Never treat "not visible" as "none". A project's own
convention doc outranks these rules where they conflict.

## Comments

**Writing or editing a comment or docstring.** Comments are for humans first,
agents second, machines never. Open a non-trivial docstring with what the
thing is in plain terms, comment only what the code cannot tell the next
reader, and keep plan references and history out of source.
`references/comments.md`

**Before a commit, or when asked to clean up comments.** Strip agent tags,
plan refs and banners, rewrite AI-sounding comments short, flag possibly stale
TODOs, and never touch pragmas or human-marked notes. Preview first, never
commit. `references/cleanup-comments.md`

**Code marked `NOTE(by human)`, `HACK` or `IMPORTANT`.** It is a tested,
deliberate choice. Never override it silently. Ask with your reasoning, then
verify the result. `references/human-note-preferences.md`

## Tests

**After any non-trivial change.** Scale the test to the change: syntax check
for a rename, real data for an endpoint, a dry run before a migration. Start
from a clean environment and verify each change on its own.
`references/testing.md`

**Writing or reviewing a test, a guard or a validator.** Use the named
patterns: mutation-test the guard, test on the real input distribution, add a
positive assertion, ship known gaps as strict xfail.
`references/testing-patterns.md`

## Shape and size

**Simplifying, refactoring, or choosing between reuse and a local version.**
Right-size before you minimize. Check goal, scope, the user's stated shape and
total cost, then take the smallest option that still fits. Over-building and
under-building are both findings. `references/right-sized-code.md`

**About to add a helper, constant or type "for later".** Without a caller
today, inline it. Extract only at 2 or more real callsites, and search for a
constant's values before exporting it. `references/speculative-abstractions.md`

**Adding a component, list, derivation, hook or table.** Open two or three
files that already solve the same shape and follow them, or say in one
sentence why this case differs. `references/read-the-siblings.md`

**Moving code into an existing file, or a general rule seems to forbid what
you are doing.** Read the destination's top to learn its character. If the
local case differs, name the rule and the difference, and hand the call to the
user. `references/file-character.md`

## Correctness traps

**Branching on an error.** Switch on a structured code from a closed set,
never on message text. `references/error-classification.md`

**Adding an environment variable read.** Find the project's config module or
schema and go through it. No scattered raw reads.
`references/env-var-config.md`

**Calling a method on a helper's return value.** Read the helper's `return`
statement first. The name can lie. `references/helper-return-type.md`

**Emitting JavaScript from a server-side template literal.** Double every
escape, or move the script to a static file. Click something in a real
browser before calling it done. `references/js-template-escapes.md`

**Adding a cache, memo or TTL.** If anything outside this process can change
the value, do not TTL it. Read it live or invalidate on the real event.
`references/cache-external-state.md`

**A file changed under a "linter" or "formatting" label.** Read the diff.
Operator, constant and default flips are behavior changes whatever the label
says. `references/linter-diffs.md`

## Renames and deletions

**Renaming anything another file, process or data store refers to by name.**
Search the whole tree for the old name, including string keys and non-code
files, then check off-tree copies such as the PR body. A green build proves
nothing. `references/rename-readers.md`

**Deleting or replacing a component, page or route.** If the user reviewed it
before, get approval or record what replaces it first. Zero importers is not
evidence it is dead. `references/ui-surface-deletion.md`

## UI

**Claiming a UI change works.** Only a rendered image read like a person
counts. Describe the whole frame first, compare siblings, check every theme
and state, and cite the screenshot. `references/ui-visual-verification.md`

**Rendering values the surface did not write.** Name what translates each one
into the reader's words. A `default` branch of `String(value)` is the bug.
`references/machine-tokens-on-screen.md`

## Design and tooling

**Writing a design where two modes return the same fields differently.**
Re-check the doc's own constraints. Modes must not diverge on a field the
consumer derives state from unless the user approved it.
`references/design-invariants.md`

**Shipping a check into a repo you do not own.** Precise checks may block.
Imprecise ones stay advisory and run in the author's own pass. Every reading
finding cites `file:line`. `references/shipped-checks.md`

## Git

**Committing, pushing or writing a commit message.** Commit per logical unit
when commits are in scope. Fresh approval for every push to main. Imperative
subject under 72 characters, why over what. No AI or Claude signatures or
co-author trailers in any commit or PR body. `references/git.md`

---
migration: NNNN
title: Short imperative title
session: <session-id>@YYYY-MM-DD
status: planned | in-progress | complete | abandoned
date: YYYY-MM-DD
---

# Migration NNNN — Short Title

## Why

What changed in the world that necessitated this. The driving constraint (a rule, a recurring problem, an external requirement, a graduated proposal). Cite the proposal ID if applicable: `prop-YYYYMMDD-HHMMSS-XX`.

## What changes

Specific, enumerable. Use a table for multi-item changes:

| From | To | Why |
|---|---|---|
| `~/.claude/old-path` | `~/.claude/new-path` | reason |
| script X exists at A | script X exists at A AND B (back-compat symlink) | reason |

## What does NOT change

Explicit list of related things that look like they'd be affected but aren't. Pre-empts confusion.

## Verification

Before declaring complete, the following must pass:

- [ ] `rg -l "<old-path>" ~/.claude ~/Code 2>/dev/null` returns expected callers only
- [ ] `<command to test the new path>` runs without error
- [ ] No new entries in `~/.claude/logs/<relevant>.log` showing failures
- [ ] (anything else specific to this migration)

## Rollback

How to undo, if needed:

```bash
# Exact commands to revert
```

Conditions under which rollback should be considered:
- (e.g.) more than 3 callers still reference the old path after 7 days
- (e.g.) any tool starts failing with "not found"

## Phases

If multi-step. Mark each as it executes:

1. **Phase 1** — description ✅ / ⏳ / ❌
2. **Phase 2** — description
3. **Cleanup** — description (often: remove back-compat shim after N days)

## Notes / followups

- Free-form. Pending decisions, related migrations, future cleanup tasks.

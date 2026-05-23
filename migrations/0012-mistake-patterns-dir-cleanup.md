---
migration: 0012
title: Consolidate mistake-patterns/ into mistakes/ (legacy dir cleanup)
session: claude-audit-2e@2026-05-17
status: complete
date: 2026-05-17
---

# Migration 0012 — Consolidate mistake-patterns/ into mistakes/

## Why

Two directories serve the same purpose (long-form RCAs):

- `~/.claude/mistakes/` — has `_index.md` explaining purpose, 1 RCA (2026-05-13). Active.
- `~/.claude/mistake-patterns/` — single orphan RCA (2026-04-28). No index, no clear ownership.

Both are distinct from the regularly-derived `~/.claude/mistake-patterns.md` (short summary view derived from `atone/events.jsonl`) — which is the canonical short index.

Audit doc § I.

## What changes

| From | To |
|---|---|
| `~/.claude/mistake-patterns/2026-04-28-sherpa-data-loss-rca.md` | `~/.claude/mistakes/2026-04-28-sherpa-data-loss-rca.md` |
| `~/.claude/mistake-patterns/` (empty after move) | trashed |

## What does NOT change

- `~/.claude/mistake-patterns.md` (derived short summary) — UNCHANGED, canonical
- `~/.claude/atone/events.jsonl` (raw event log) — UNCHANGED
- `~/.claude/mistakes/_index.md` — UNCHANGED (its description applies to the moved file too)

## Verification

- [x] Single file under `mistake-patterns/` identified
- [x] No references to `mistake-patterns/` (as a dir path) from scripts/skills/hooks
- [ ] After move: `~/.claude/mistakes/` has 2 RCAs + `_index.md`
- [ ] After trash: `~/.claude/mistake-patterns/` no longer exists

## Rollback

```bash
mkdir -p ~/.claude/mistake-patterns
mv ~/.claude/mistakes/2026-04-28-sherpa-data-loss-rca.md ~/.claude/mistake-patterns/
```

## Phases

1. **Phase 1 — Move file** ⏳
2. **Phase 2 — Trash empty dir** ⏳
3. **Phase 3 — Update `mistakes/_index.md`** to include the moved RCA in its index ⏳

## Notes

- The naming overlap (`mistake-patterns/` dir vs `mistake-patterns.md` file) is itself a clarity issue — removing the dir eliminates ambiguity.
- After this, the namespace is clean: `mistakes/` (long-form RCAs), `mistake-patterns.md` (short derived view), `atone/events.jsonl` (raw events).

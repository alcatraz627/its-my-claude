---
migration: 0015
title: Introduce std::claude::magi namespace + ~/.claude/assets/magi/ data dir
session: claude-audit-2e@2026-05-17
status: complete
date: 2026-05-17
---

# Migration 0015 — std::claude::magi Namespace

## Why

New MAGI / committee / voting system shipped as Phase 3 MVP. New namespace cluster + archive directory under assets. Per gcc-hygiene rule: any new namespace cluster requires a migration entry.

Spec: `~/.claude/assets/docs/20260518-magi-design.md`. Research foundation: `~/.claude/assets/docs/20260518-magi-research.md`.

## What changes

| Addition | Path |
|---|---|
| New namespace cluster | `std::claude::magi` (in `NAMESPACE.md`) |
| New skill | `~/.claude/skills/magi/SKILL.md` (`/magi`) |
| New scripts dir | `~/.claude/scripts/magi/` (init-archive, aggregate-votes, cost-estimate) |
| New data dir | `~/.claude/assets/magi/<YYYYMMDD>-<HHMM>-<slug>/` |
| New persona drafts dir | `~/.claude/personas/_proposed/` (for inline-drafted magi personas) |

## What does NOT change

- No existing paths renamed or removed
- No settings.json hook changes
- Existing personas at `~/.claude/personas/` are untouched

## Verification

- [x] Scripts created + executable (init-archive, aggregate-votes, cost-estimate)
- [x] Scripts smoke-tested (synthetic voter score files → matrix + bias-matrix)
- [x] SKILL.md registered (visible in skill catalogue)
- [x] Design + research docs in place
- [ ] First real `/magi` invocation completes end-to-end
- [ ] FOLDERS.md updated with `assets/magi/` row
- [ ] NAMESPACE.md tree + cluster definition added
- [ ] LOOKUP.md row added

## Rollback

```bash
# Disable the skill:
mv ~/.claude/skills/magi ~/.claude/skills/_disabled-magi
# Remove the scripts:
trash ~/.claude/scripts/magi
# Archive directory keeps prior outputs:
# (no action needed; assets/magi/ entries are durable)
```

## Phases

1. **Phase 1** — Research doc ✅
2. **Phase 2** — Design doc ✅
3. **Phase 3** — MVP build (scripts + skill + register) ✅
4. **Phase 4** — First-task validation ⏳

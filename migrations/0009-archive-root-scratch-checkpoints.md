---
migration: 0009
title: Archive root-level scratch checkpoints to assets/checkpoints/YYYYMM/
session: claude-audit-2e@2026-05-17
status: complete
date: 2026-05-17
---

# Migration 0009 — Archive Root Scratch Checkpoints

## Why

`~/.claude/` root had 38 `_YYYYMMDD-<slug>.claude.md` scratch checkpoint files, oldest from 2026-03-31. The convention (`conventions/scratch-files.md`) says these should monthly-archive to `assets/checkpoints/YYYYMM/` but the archival was never automated.

Audit doc: `~/.claude/assets/docs/20260517-gcc-audit-v1.md` § B.

## What changes

- All `~/.claude/_YYYYMMDD-*.claude.md` files older than 30 days → `~/.claude/assets/checkpoints/YYYYMM/<original-name>` (preserves filename, just relocates).
- Implemented via `~/.claude/scripts/startup/tasks/40-archive-scratch-checkpoints.sh` (re-runnable on next login + any time manually).

## What does NOT change

- `_checkpoint.claude.md` symlink at root (active session pointer) — NOT touched.
- `_last-checkpoint.json` (legacy, removed in pending 0008→TBD) — NOT touched.
- `_precompact-checkpoint.claude.md` (latest pre-compact snapshot) — NOT touched.
- File names + contents are unchanged; only location moves.

## Verification

- [x] Task script written: `scripts/startup/tasks/40-archive-scratch-checkpoints.sh`
- [ ] Dry-run shows expected files
- [ ] Live run archives them
- [ ] `ls ~/.claude/_2026*-*.claude.md` shows only recent (<30 day) files
- [ ] `assets/checkpoints/YYYYMM/` populated for the relevant month(s)
- [ ] Task wired into `std::claude::startup` (auto-runs on next login)

## Rollback

```bash
# Restore a single file:
mv ~/.claude/assets/checkpoints/YYYYMM/<filename> ~/.claude/

# Bulk restore everything from a month:
mv ~/.claude/assets/checkpoints/202604/*.md ~/.claude/
```

## Phases

1. **Phase 1** — Write task script ✅
2. **Phase 2** — Dry-run + live run today ⏳
3. **Phase 3** — Wired into startup orchestrator (already; it auto-runs `tasks/*.sh` lexically) ✅

## Notes / followups

- Symlink target `_checkpoint.claude.md` is filtered by the file-glob pattern `_2026*-*.claude.md` (won't match) — safe.
- The task is now part of `std::claude::startup`; will fire on next reboot/login automatically.

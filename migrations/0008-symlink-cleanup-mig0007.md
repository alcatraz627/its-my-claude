---
migration: 0008
title: Symlink-cleanup for migration 0007 leftovers
session: claude-audit-2e@2026-05-17
status: in-progress
date: 2026-05-17
---

# Migration 0008 — Symlink-Cleanup for Migration 0007 Leftovers

## Why

Migration 0007 (scripts cleanup, 2026-04-24) moved 15 scripts from `~/.claude/scripts/<name>.sh` into thematic subdirs (`session-mgmt/`, `wal/`, `statusline/`) but left byte-identical copies at the top level as back-compat. Its design said "remove after ~2 weeks." Three weeks past.

Active scan (`rg -l "scripts/<name>.sh"` across settings.json + skills + hinters + scripts) confirms:
- ALL 15 duplicates are byte-identical (`diff` confirms)
- ALL real callers reference the SUB (canonical) path
- ZERO callers reference the TOP (back-compat) path

Surface for the symlink approach: protect against a forgotten external caller (in `~/Code/` user scripts, or in a memory entry citing the old path) without losing the cleanup win.

Audit doc: `~/.claude/assets/docs/20260517-gcc-audit-v1.md` § A.

## What changes

| From (top-level file) | To (symlink target) |
|---|---|
| `~/.claude/scripts/turn-counter.sh` | symlink → `session-mgmt/turn-counter.sh` |
| `~/.claude/scripts/turn-start.sh` | symlink → `session-mgmt/turn-start.sh` |
| `~/.claude/scripts/turn-end-cleanup.sh` | symlink → `session-mgmt/turn-end-cleanup.sh` |
| `~/.claude/scripts/subagent-tracker.sh` | symlink → `session-mgmt/subagent-tracker.sh` |
| `~/.claude/scripts/session-summary.sh` | symlink → `session-mgmt/session-summary.sh` |
| `~/.claude/scripts/wal.sh` | symlink → `wal/wal.sh` |
| `~/.claude/scripts/wal-convert.sh` | symlink → `wal/wal-convert.sh` |
| `~/.claude/scripts/statusline.sh` | symlink → `statusline/statusline.sh` |
| `~/.claude/scripts/statusline-backup.sh` | symlink → `statusline/statusline-backup.sh` |
| `~/.claude/scripts/sl-playground.sh` | symlink → `statusline/sl-playground.sh` |
| `~/.claude/scripts/sl-open.sh` | symlink → `statusline/sl-open.sh` |
| `~/.claude/scripts/sl-explain.sh` | symlink → `statusline/sl-explain.sh` |
| `~/.claude/scripts/sl-config.sh` | symlink → `statusline/sl-config.sh` |
| `~/.claude/scripts/sl-cli.sh` | symlink → `statusline/sl-cli.sh` |
| `~/.claude/scripts/sl-audit.sh` | symlink → `statusline/sl-audit.sh` |

## What does NOT change

- Subdir copies (`session-mgmt/X.sh`, `wal/X.sh`, `statusline/X.sh`) — they're the canonical originals, unchanged.
- Settings.json hook commands — already reference subdir paths.
- All other scripts at `~/.claude/scripts/*.sh` (~85 untouched files).

## Verification

- [x] All 15 duplicates byte-identical (`diff -q` returned no differences)
- [x] All real callers reference subdir paths (`rg` scan)
- [ ] After symlink: top-level paths resolve (`test -L X && test -e X` for each)
- [ ] After symlink: invoke 2-3 scripts via top-level path → confirm they run

## Rollback

```bash
# If a symlink misbehaves, restore as regular file:
for s in <name>; do
  cp -f ~/.claude/scripts/<subdir>/$s ~/.claude/scripts/$s
done
```

If a symlink is missed by an external script, the symlink approach makes it find-and-load correctly anyway (filesystem-transparent). Rollback is only needed if a script reads its own `$0` to find sibling files via relative path — none of these 15 do.

## Phases

1. **Phase 1 — Convert all 15 to symlinks** (this session) ⏳
2. **Phase 2 — 3-month review (2026-08-17)** — if no external caller has materialized, trash all 15 symlinks. ⏳

## Notes / followups

- Per Q1 from user: 3-month review is the cutoff. Created a calendar reminder script or just check via `find ~/.claude/scripts -maxdepth 1 -type l -mtime +90`.
- This is the second cleanup of 0007; if any similar shims show up after this, treat them as bugs and remove immediately.

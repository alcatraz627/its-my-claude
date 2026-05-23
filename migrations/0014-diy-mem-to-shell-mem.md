---
migration: 0014
title: Rename diy-mem/ → shell-mem/ + add dispatcher
session: claude-audit-2e@2026-05-17
status: in-progress
date: 2026-05-17
---

# Migration 0014 — Rename diy-mem → shell-mem + Add Dispatcher

## Why

The shell-command tracking subsystem has inconsistent naming:
- Folder: `~/.claude/scripts/diy-mem/`
- MCP server: `shell-mem` (in `~/Code/Claude/diy-claude-mem/`)
- Skill: `/shell-mem`

Audit found ZERO external callers besides the listed hook entries — safe to rename. Also: 15 sibling scripts with same prefix benefit from a dispatcher (per gcc-hygiene principle 2).

Audit doc § G. Per user direction Q4.

## What changes

| From | To |
|---|---|
| `~/.claude/scripts/diy-mem/` | `~/.claude/scripts/shell-mem/` (folder rename) |
| `~/.claude/scripts/diy-mem` → no longer exists | `~/.claude/scripts/diy-mem` → symlink to `shell-mem/` (back-compat) |
| `diy-mem/init-session.sh` (etc., 15 scripts) | `shell-mem/init-session.sh` (same content) |
| New: `~/.claude/scripts/shell-mem.sh` | Top-level dispatcher: `shell-mem.sh <subcommand> [args]` |
| `settings.json` hook refs: `diy-mem/X.sh` | `shell-mem.sh X` (4 hook references) |
| Orchestrator task lists | Updated to use new paths |
| `NAMESPACE.md`, `LOOKUP.md`, `CLAUDE.md` mentions | Updated |

## What does NOT change

- The shell-logs/ data directory + file format — UNCHANGED
- The shell-mem MCP server in `~/Code/Claude/diy-claude-mem/` — UNCHANGED
- The `/shell-mem` skill — UNCHANGED (description tweak only)
- Per-script behavior — each subcommand delegates to the existing script (no logic change)
- Subconscious daemon — UNCHANGED

## Verification

- [x] Build dispatcher
- [x] Rename folder
- [x] Add back-compat symlink
- [x] Update settings.json (4 refs)
- [x] Update hook-orchestrator task files (2 refs)
- [x] Update CLAUDE.md, NAMESPACE.md, LOOKUP.md
- [ ] Smoke test: invoke dispatcher → delegates correctly
- [ ] Smoke test: hooks fire on next session — verify shell-logs/<today>.md gets entries

## Rollback

```bash
# Reverse the rename
rm ~/.claude/scripts/diy-mem  # remove symlink
mv ~/.claude/scripts/shell-mem ~/.claude/scripts/diy-mem
# Restore settings.json from backup
cp ~/.claude/settings.json.pre-mig0014.bak ~/.claude/settings.json
# Trash the dispatcher
trash ~/.claude/scripts/shell-mem.sh
```

## Phases

1. **Phase 1 — Build dispatcher** ⏳
2. **Phase 2 — Rename folder + back-compat symlink** ⏳
3. **Phase 3 — Update settings.json + orchestrator task files** ⏳
4. **Phase 4 — Update CLAUDE.md / NAMESPACE.md / LOOKUP.md** ⏳
5. **Phase 5 — Smoke test** ⏳
6. **Phase 6 (~3 months out) — remove back-compat symlink if no broken callers surface** ⏳

## Notes / followups

- 15 sibling scripts (init-session, track-bash, mark-done-bash, pre-compact-shell, session-end-shell, inject-shell-state, shell-log-active, shell-log-append, shell-log-cleanup, shell-log-file, shell-log-mark-done, shell-log-search, shell-log-tail, track-bash, config) remain as separate files for now. The dispatcher exposes them as subcommands. Future consolidation into `shell-mem.sh` internals is a follow-up (would warrant its own migration).
- The MCP server (in `~/Code/Claude/diy-claude-mem/`) is NOT renamed — that's its own repo. Its folder name is historical; not worth a coordinated rename across both repos.

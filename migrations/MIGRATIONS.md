# std::claude::migrations — Index

<!-- sessions: ns-plan-7f@2026-04-17, upgrade-phase12-7c@2026-04-17 -->

> Structural migrations to `~/.claude/` — renames, moves, restructures that could
> break references in memory files, scratchpad, skills, or CLAUDE.md pointers.
>
> **When to create a migration doc**: any path move, label rename, directory
> restructure, or major subsystem addition that changes an external reference.
> Small in-place edits don't need one.
>
> **Retrofits are OK.** If a structural change landed before the migration log
> existed, back-fill a doc so the index is the canonical source of truth.
>
> **When to read a migration doc**: you encounter a path or label that no longer
> resolves. Scan this index, then open the doc.

---

## Status legend

| Icon | Meaning |
|---|---|
| ✅ | Complete — all phases executed, no cleanup pending |
| 🔄 | In progress — some phases executed, more to come |
| ⏳ | Planned — doc exists, no phases executed yet |
| 💡 | Idea — captured here before committing to a doc |
| ❌ | Abandoned — doc retained as historical record |

---

## Numbering

Zero-padded 4-digit (`0001`, `0002`, `0042`). **Gaps are allowed.** **Never renumber once a doc is written.** Abandoned migrations keep their number; new ones always take the next unused integer.

**Exception for unwritten docs:** if a migration is only referenced (not yet written) and a higher priority migration claims its slot, renumbering the unwritten one is fine. Example: 0002 was originally "memory global-first"; when phase12 retrofit needed a number, memory moved to 0004 before 0002 had a doc.

---

## Index

| # | Title | Status | Opened | Last updated | Doc |
|---|---|---|---|---|---|
| 0001 | Introduce std::claude namespace system | ✅ | 2026-04-14 | 2026-04-17 | [0001-namespace-introduction.md](0001-namespace-introduction.md) |
| 0002 | Phase 1+2 upgrade (retrofit) | ✅ | 2026-04-17 | 2026-04-17 | [0002-phase12-upgrade-retrofit.md](0002-phase12-upgrade-retrofit.md) |
| 0003 | Add ::backups and ::improvement namespaces | ✅ | 2026-04-17 | 2026-04-17 | [0003-backups-improvement-namespaces.md](0003-backups-improvement-namespaces.md) |
| 0004 | Global memory tier | ✅ | 2026-04-17 | 2026-04-17 | [0004-memory-global-tier.md](0004-memory-global-tier.md) |
| 0005 | Add ::vision, ::network, ::widgets, ::todos namespaces | ✅ | 2026-04-17 | 2026-04-17 | [0005-vision-network-widgets-todos.md](0005-vision-network-widgets-todos.md) |
| 0006 | CLAUDE.md restructure (category × tier, ::rules/::features/::conventions) | ✅ | 2026-04-24 | 2026-04-24 | [0006-claude-md-restructure.md](0006-claude-md-restructure.md) |
| 0007 | Scripts folder cleanup + grouped subdirs | ✅ | 2026-04-24 | 2026-04-24 | [0007-scripts-cleanup.md](0007-scripts-cleanup.md) |
| 0008 | Symlink-cleanup for migration 0007 leftovers (15 top-level dupes → symlinks) | 🔄 | 2026-05-17 | 2026-05-17 | [0008-symlink-cleanup-mig0007.md](0008-symlink-cleanup-mig0007.md) |
| 0009 | Archive root scratch checkpoints (24 files → assets/checkpoints/YYYYMM/) | ✅ | 2026-05-17 | 2026-05-17 | [0009-archive-root-scratch-checkpoints.md](0009-archive-root-scratch-checkpoints.md) |
| 0010 | Unified /tmp/claude-* cleanup (was tab-only) | ✅ | 2026-05-17 | 2026-05-17 | [0010-unified-tmp-cleanup.md](0010-unified-tmp-cleanup.md) |
| 0011 | Defensive cleanup of empty session-env/ subdirs (632 removed) | ✅ | 2026-05-17 | 2026-05-17 | [0011-cleanup-empty-session-env.md](0011-cleanup-empty-session-env.md) |
| 0012 | Consolidate mistake-patterns/ into mistakes/ | ✅ | 2026-05-17 | 2026-05-17 | [0012-mistake-patterns-dir-cleanup.md](0012-mistake-patterns-dir-cleanup.md) |
| 0013 | Hook orchestrator (parallel) for SessionStart + Stop (21→2 settings blocks) | ✅ | 2026-05-17 | 2026-05-17 | [0013-hook-orchestrator-sessionstart-stop.md](0013-hook-orchestrator-sessionstart-stop.md) |
| 0014 | Rename diy-mem → shell-mem + dispatcher (back-compat symlink) | ✅ | 2026-05-17 | 2026-05-17 | [0014-diy-mem-to-shell-mem.md](0014-diy-mem-to-shell-mem.md) |
| 0015 | Introduce std::claude::magi namespace + /magi skill | ✅ | 2026-05-17 | 2026-05-17 | [0015-magi-namespace.md](0015-magi-namespace.md) |

---

## Planned / in the backlog

| # | Title | Notes |
|---|---|---|
| _(none currently)_ | | |

---

## How to recover from a stale reference

If a path in CLAUDE.md / a memory file / a scratchpad plan / a SKILL.md no longer resolves:

1. **Scan the index above** for migrations touching the stale path or its parent directory.
2. **Open the doc** and read its "Path moves" and "Files affected" tables.
3. If the migration status is ✅ or 🔄-past-the-relevant-phase, **update the reference in place** to the new path.
4. If the migration is ⏳ Planned, **leave the old reference** and add a note to the session WAL so it surfaces when the phase runs.
5. If no migration covers it, **grep for the old path globally**, delete dead references, and file a `::improvement::proposals` entry via `propose.sh`.

---

## Adding a new migration

1. Pick the next unused number (check both the Index and Planned tables).
2. Create `NNNN-slug.md` with sections: Summary, Why, Scope, Label changes, Path moves, Files affected, Phases, Recovery, Cross-references.
3. Add a row to the **Index** table above with status ⏳ (planned) or ✅ (retrofit).
4. When a phase lands, bump status and update the "Last updated" column.
5. Never delete rows. Abandoned migrations flip to ❌ and stay.

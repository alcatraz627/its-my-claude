# Migration 0004 — Global Memory Tier

<!-- sessions: catcu-std-c0@2026-04-17 -->

**Status:** ✅ Complete — all 3 phases executed 2026-04-17. 14 memories seeded.
**Opened:** 2026-04-17
**Last updated:** 2026-04-17

---

## Summary

Add a cross-project global memory tier at `~/.claude/memory/global/` alongside the existing
harness-controlled per-project memory. Does NOT move or rename existing per-project memory
directories.

---

## Why

1. **Cross-project memories are invisible.** A feedback memory saved in project A (e.g.,
   "always test small samples") is never loaded in project B. Truly universal learnings
   have no canonical home.
2. **The harness owns per-project paths.** `~/.claude/projects/<slug>/memory/` is injected
   by the Claude Code CLI — not configurable via CLAUDE.md or settings. Moving these dirs
   would break every project's auto-memory immediately.
3. **The implicit "global" is fragile.** Currently, memories stored under the `~/.claude/`
   project slug (`-Users-*--claude/memory/`) act as pseudo-global — but they're only loaded
   when CWD is `~/.claude/` itself.

---

## Original plan (abandoned)

> Move `~/.claude/projects/<slug>/memory/` → `~/.claude/memory/projects/<slug>/`;
> add `~/.claude/memory/global/`; update CLAUDE.md auto-memory hardcoded path.

**Why abandoned:** The harness hardcodes the memory path in its system prompt injection.
It is not user-configurable. Moving directories would:
- Break all 15 existing project memory dirs (67 files total as of 2026-04-17)
- Affect every running and future session until the harness itself is updated
- Require symlinks or harness patches — both fragile

The revised scope (below) achieves the original goal — cross-project memory — without
touching the harness path.

---

## Revised scope

**In scope:**
- Create `~/.claude/memory/global/` with MEMORY.md index + README
- Add CLAUDE.md instruction: "Also check `~/.claude/memory/global/MEMORY.md`"
- Seed with universally-applicable memories promoted from per-project dirs
- Update NAMESPACE.md `::memory` section to document the two-tier system
- Update LOOKUP.md with new memory tier

**Out of scope:**
- Moving per-project memory dirs (harness constraint)
- Modifying the harness's system prompt injection
- Deprecating per-project memory (it remains the primary tier)

---

## Label changes

None. The `std::claude::memory` label already exists; this migration adds a physical
location for its "global" sub-surface.

---

## Path moves

None. This migration is purely additive.

---

## New paths

| Path | Purpose |
|---|---|
| `~/.claude/memory/` | Parent directory for memory tiers |
| `~/.claude/memory/global/` | Cross-project memory files |
| `~/.claude/memory/global/MEMORY.md` | Index of global memory entries |
| `~/.claude/memory/global/README.md` | Explains the two-tier system |

---

## Files affected

| File | Change |
|---|---|
| `~/.claude/memory/global/README.md` | **created** — tier docs |
| `~/.claude/memory/global/MEMORY.md` | **created** — global memory index |
| `~/.claude/CLAUDE.md` | **edit** — add instruction to check global memory |
| `~/.claude/NAMESPACE.md` | **edit** — update `::memory` section |
| `~/.claude/LOOKUP.md` | **edit** — add memory tier row |
| `~/.claude/migrations/MIGRATIONS.md` | **edit** — flip status |
| Various `projects/*/memory/*.md` | **copy** (not move) — seed globals |

---

## Two-tier memory architecture

```
┌──────────────────────────────────────────────────┐
│  Per-project memory (harness-controlled)         │
│  ~/.claude/projects/<slug>/memory/               │
│  • Loaded automatically by the CLI harness       │
│  • One dir per project CWD                       │
│  • Contains project-specific memories            │
│  • MEMORY.md index per project                   │
├──────────────────────────────────────────────────┤
│  Global memory (CLAUDE.md-instructed)            │
│  ~/.claude/memory/global/                        │
│  • Loaded via explicit CLAUDE.md instruction     │
│  • Shared across all projects                    │
│  • Contains universal user prefs, patterns       │
│  • MEMORY.md index (same format)                 │
└──────────────────────────────────────────────────┘

Promotion: copy a per-project memory to global/ when it proves universal.
Originals stay in place — per-project memory is never degraded.
```

---

## Phases

| Phase | Scope | Status | Notes |
|---|---|---|---|
| 1 | Create `memory/global/` + README + MEMORY.md + CLAUDE.md instruction | ⏳ | Safe additive writes |
| 2 | Seed global tier with promoted memories from per-project dirs | ⏳ | Review 67 files, copy universals |
| 3 | Update NAMESPACE.md + LOOKUP.md + flip migration status | ⏳ | Doc updates |

All phases are low-risk: nothing moves, nothing breaks, nothing is deleted.

---

## Recovery from stale references

If you hit a reference to `~/.claude/memory/global/` and it doesn't exist, this migration
hasn't been executed yet. Fall back to per-project memory only.

If a memory file appears in both `memory/global/` and `projects/<slug>/memory/`, the
per-project version takes precedence (it may have project-specific edits).

---

## Cross-references

- Namespace tree: `~/.claude/NAMESPACE.md` § `std::claude::memory`
- Migration index: `~/.claude/migrations/MIGRATIONS.md`
- Original plan: Migration 0001 Phase 2 reference (now redirected here)
- Auto-memory system: Claude Code harness system prompt injection

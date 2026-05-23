# Migration 0003 — Add `::backups` and `::improvement` namespaces

<!-- sessions: ns-plan-7f@2026-04-17 -->

**Status:** ✅ Phase 0b executed 2026-04-17 — namespaces documented in NAMESPACE.md; no files moved.
**Opened:** 2026-04-17
**Last updated:** 2026-04-17

---

## Summary

Introduce two new sibling namespaces under `std::claude::`:

- `::backups` — revert & recovery artifacts (3 path surfaces, marked `[facet]`)
- `::improvement` — self-correction & learning (6+ path surfaces, marked `[facet]`), with 5 sub-labels: `::ideas`, `::mistakes`, `::proposals`, `::insights`, `::dreams`

Both are **pure relabelling** — zero file moves, zero hook changes, zero risk to existing references.

---

## Why

1. The Phase 1+2 upgrade (Migration 0002) landed significant self-correction infrastructure — `mistake-patterns.md`, `proposals.jsonl`, `subconscious/dreams/`, runtime-notes quarterly archives — that had no shared label. Without one, the artifacts were scattered in NAMESPACE's "Under consideration" section or unnamed in LOOKUP.md.
2. Backups surfaced as a distinct concern across three locations (`assets/backups/`, root `backups/`, in-place `bak_*`) with a retention policy (`prune-backups.sh`) and a convention (RESTORE.md). This meets the "wait until at least two artifacts want the label" test comfortably.
3. Sharp distinction needed: `::code::ideas` (code-pattern seeds for building features) vs `::improvement::ideas` (Claude-system improvements). Previously conflated in Migration 0001's Phase 1 plan; now split cleanly.

---

## Scope

**In scope for this migration:**
- Add `::backups` section to NAMESPACE.md with facet marking
- Add `::improvement` section with 5 sub-labels
- Update the design-principles and tree sections of NAMESPACE.md
- Revise Migration 0001 Phase 1 to drop the `improvement-ideas.md` → `code/ideas/ROADMAP.md` move
- Update MIGRATIONS.md index with rows for 0002, 0003, 0004

**Out of scope (no file moves):**
- `improvement-ideas.md` stays at `~/.claude/improvement-ideas.md` — relabelled as `::improvement::ideas`
- `mistake-patterns.md` stays at root — relabelled as `::improvement::mistakes`
- `proposals.jsonl` stays at root — relabelled as `::improvement::proposals`
- `subconscious/` stays — relabelled as `::improvement::dreams`
- `assets/backups/`, root `backups/`, in-place `bak_*` all stay — covered by `::backups` facet

---

## Label changes

No existing labels renamed. Only additions:

| New label | Covers |
|---|---|
| `std::claude::backups` | 3 path surfaces: `assets/backups/`, `~/.claude/backups/` (CLI-managed auto), root `bak_*` rotation |
| `std::claude::improvement` | Facet across 6+ paths |
| `::improvement::ideas` | `~/.claude/improvement-ideas.md` |
| `::improvement::mistakes` | `~/.claude/mistake-patterns.md` |
| `::improvement::proposals` | `~/.claude/proposals.jsonl` + `scripts/propose.sh` |
| `::improvement::insights` | `~/.claude/skills/runtime-notes.md` + `runtime-notes-archive-*.md` |
| `::improvement::dreams` | `~/.claude/subconscious/dreams/`, `metacog/`, `introspection/`, `intentions/`, `valence/`, `logs/`, `hooks/` |

---

## Path moves

**None.** This migration is pure relabelling.

---

## Files affected

### Phase 0b — docs only (executed 2026-04-17)

| File | Change |
|---|---|
| `~/.claude/NAMESPACE.md` | **rewritten** — added two clusters, tree updated, 8th design principle added ("prefer relabelling over moving"), migration history table updated |
| `~/.claude/migrations/MIGRATIONS.md` | **edit** — added rows for 0002, 0003, 0004 |
| `~/.claude/migrations/0002-phase12-upgrade-retrofit.md` | **created** — retrospective migration doc for Phase 1+2 upgrade |
| `~/.claude/migrations/0003-backups-improvement-namespaces.md` | **created** — this doc |
| `~/.claude/migrations/0001-namespace-introduction.md` | **edit** — Phase 1 revised to drop `improvement-ideas.md` move |

Zero file moves, zero hook changes, zero renames of existing artifacts.

---

## Interaction with Migration 0001

Migration 0001's Phase 1 originally planned:
> Move `~/.claude/improvement-ideas.md` → `~/.claude/code/ideas/ROADMAP.md`

**Revised:** dropped. `improvement-ideas.md` is Claude-system improvement backlog, not code-pattern seeds — it belongs in `::improvement::ideas`, not `::code::ideas`. Relabelling is sufficient; no move needed.

The rest of 0001's Phase 1 (rename `std::claude` → `::shared` across docs, create `~/.claude/code/` skeleton) is unchanged and remains ⏳ Planned.

---

## Recovery from stale references

If you see a reference to `~/.claude/code/ideas/ROADMAP.md` in any memory file, scratchpad, or skill doc written between 2026-04-14 and 2026-04-17:

- That path was never created. The original Migration 0001 plan proposed it, but Migration 0003 revised the plan before execution.
- The canonical location is `~/.claude/improvement-ideas.md` (unchanged from its pre-2026-04-14 location).
- Update the reference in place.

If you encounter a self-correction artifact that doesn't seem to fit anywhere (e.g., a new "audit" output file):

- Check `::improvement` sub-labels — it probably fits `::insights`, `::dreams`, or warrants a new sub-label.
- Open a new migration before introducing a new sub-label.

---

## Phases

| Phase | Scope | Status |
|---|---|---|
| 0b | Documentation writes (this migration's core work) | ✅ Executed 2026-04-17 |
| 1 | _(no Phase 1 needed — relabelling only)_ | — |

---

## Cross-references

- Conceptual tree (updated): `~/.claude/NAMESPACE.md`
- Migration 0001 (revised): `~/.claude/migrations/0001-namespace-introduction.md`
- Migration 0002 (retrofit): `~/.claude/migrations/0002-phase12-upgrade-retrofit.md`
- Index: `~/.claude/migrations/MIGRATIONS.md`

---

## Notes

- The `::improvement` namespace is deliberately a facet. Collapsing its six sub-surfaces into one directory would break the `subconscious/` daemon's existing hooks and would require moving CLI-visible files (`improvement-ideas.md`, `mistake-patterns.md`) that are referenced by name in CLAUDE.md. Labels let us unify the concept without touching any consumers.
- The `::improvement::dreams` sub-label covers the whole `subconscious/` tree, not just `dreams/`. If the daemon grows distinct surfaces (e.g., separate `metacog/` insights tooling), split into more sub-labels via a new migration.

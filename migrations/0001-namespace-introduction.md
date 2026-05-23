# Migration 0001 — Introduce std::claude namespace system

<!-- sessions: ns-plan-7f@2026-04-14 -->

**Status:** ✅ Complete — Phase 0 executed 2026-04-14; Phase 1 executed 2026-04-17. Phase 2 split out to Migration 0004 (deferred); Phase 3 is a standing 💡 idea.
**Opened:** 2026-04-14
**Last updated:** 2026-04-17

---

## Summary

Extend the single-label `std::claude` (previously naming only the utility library at `~/.claude/skills/shared/`) into a full namespace tree of sibling clusters covering every Claude feature and add-on under `~/.claude/`.

---

## Why

1. **Label collision.** The old `std::claude` label covered one library. New clusters (`::code`, `::scripts`, `::tui`, `::memory`, etc.) need somewhere to hang.
2. **Organizational clarity.** Features are scattered across `~/.claude/`: skills, scripts, MCP config, assets, memory, scratchpad. No shared vocabulary meant agents had to re-derive structure every session.
3. **Surface separation.** Reference material (roadmaps, templates) was mixed with operational scripts. Splitting `::code` vs `::scripts` makes the distinction explicit.
4. **Future-proofing.** A named taxonomy lets us add things (`::plugins`, `::tui`, new facets) without reshuffling.

---

## Scope

**In scope for this migration:**
- Rename the library label `std::claude` → `std::claude::shared`.
- Create `~/.claude/NAMESPACE.md` as the conceptual tree.
- Create `~/.claude/migrations/` infrastructure (index + this doc).
- Insert 1-line namespace pointer in CLAUDE.md.
- Phase 1 rename pass across refs (shared README, CHANGELOG, VERSION, skills, memory files).
- Phase 1 creation of `~/.claude/code/{ideas,templates}/` and move of `improvement-ideas.md`.

**Out of scope (split into Migration 0002):**
- Moving memory from `~/.claude/projects/<slug>/memory/` to `~/.claude/memory/`.

---

## Label changes

| Old label | New label | Notes |
|---|---|---|
| `std::claude` | `std::claude::shared` | Sole library that held the original label. Phase 1 updates refs; Phase 0 leaves them. |

No other labels changed — everything else is *additive*.

---

## New labels introduced

All siblings under `std::claude::`:

- `::shared` (renamed, see above)
- `::code` with sub-labels `::code::ideas` and `::code::templates`
- `::scripts`
- `::skills`
- `::plugins`
- `::mcp` (facet)
- `::tui` (facet)
- `::assets`
- `::memory`
- `::scratchpad`
- `::migrations` (this cluster)

See `NAMESPACE.md` for full definitions of each.

---

## Path moves

| From | To | Phase | Notes |
|---|---|---|---|
| _(none — revised 2026-04-17 via Migration 0003)_ | | | Original plan moved `improvement-ideas.md` → `code/ideas/ROADMAP.md`; dropped because that file is `::improvement::ideas`, not `::code::ideas`. Relabelling suffices. |

**Revised 2026-04-17**: the `improvement-ideas.md` move was dropped. See Migration 0003 for rationale. Memory move remains deferred — now tracked as Migration 0004 (renumbered from 0002 to make room for the phase12 retrofit).

---

## Files affected

### Phase 0 — additive only (executed 2026-04-14)

| File | Change |
|---|---|
| `~/.claude/NAMESPACE.md` | **created** — the conceptual tree |
| `~/.claude/migrations/MIGRATIONS.md` | **created** — index of migrations |
| `~/.claude/migrations/0001-namespace-introduction.md` | **created** — this doc |
| `~/.claude/CLAUDE.md` | **edit** — insert 1 line pointing to NAMESPACE.md + migration log |

No renames. No moves. Zero risk of breaking references.

### Phase 1 — label rename + code/ cluster (planned, revised 2026-04-17)

| File | Change |
|---|---|
| `~/.claude/skills/shared/README.md` | Update title `# std::claude v0.1.0` → `# std::claude::shared v0.2.0` |
| `~/.claude/skills/shared/CHANGELOG.md` | Add 0.2.0 entry noting the rename |
| `~/.claude/skills/shared/VERSION` | Bump `0.1.0` → `0.2.0` |
| `~/.claude/CLAUDE.md` | Update "std::claude — Shared Utility Library" section heading → `std::claude::shared` |
| `~/.claude/skills/GUIDELINES.md` | Any `std::claude` refs → `std::claude::shared` |
| `~/.claude/projects/-Users-alcatraz627-Code-Claude/memory/reference_std_claude.md` | Rename file → `reference_std_claude_shared.md`; update MEMORY.md index |
| `~/.claude/skills/banner/SKILL.md` | Any `std::claude` refs → `std::claude::shared` |
| `~/.claude/code/` | **create** empty `ideas/` and `templates/` subdirs + brief `code/README.md` explaining the cluster's purpose |
| `~/.claude/LOOKUP.md` | Add `code/` row under appropriate section |

~~`~/.claude/improvement-ideas.md` → `~/.claude/code/ideas/ROADMAP.md`~~ — dropped. See Migration 0003.

### Phase 2 — memory migration (Migration 0004, deferred)

Out of scope for this doc. Tracked separately. Note: originally numbered 0002; renumbered to 0004 after 0002 (phase12 retrofit) and 0003 (backups+improvement namespaces) took the next two slots.

---

## Phases

| Phase | Scope | Status | Notes |
|---|---|---|---|
| 0 | Pure additive writes (NAMESPACE, migrations, CLAUDE pointer) | ✅ | Executed 2026-04-14 |
| 1 | Label rename (bare `std::claude` → `::shared`) + `~/.claude/code/` skeleton | ✅ | Executed 2026-04-17. VERSION 0.1.1 → 0.2.0. 13 refs updated across CLAUDE.md, GUIDELINES.md, banner/SKILL.md, shared/README.md + CHANGELOG, project memory. `~/.claude/code/{ideas,templates}/` + README.md created. `improvement-ideas.md` move dropped (see Migration 0003). |
| 2 | Memory global-first | 🚚 | Split out to Migration 0004 — no longer part of 0001 |
| 3 | Optional PreToolUse hook to intercept stale paths | 💡 | Nice-to-have, not scheduled |

---

## Recovery from stale references

If you (an agent in a future session) hit a reference to `std::claude` without a sub-namespace, or a file at `~/.claude/improvement-ideas.md`:

- **`std::claude` alone** → treat as `std::claude::shared`. The rename was aesthetic; the library did not move. Update the reference to the new label.
- **`~/.claude/improvement-ideas.md`** → if Phase 1 has executed, it now lives at `~/.claude/code/ideas/ROADMAP.md`. Check for existence first (`ls ~/.claude/code/ideas/ROADMAP.md`); if present, update the reference.
- **Memory file at `~/.claude/projects/<slug>/memory/`** → still valid until Migration 0002 lands. See that doc when it exists.

If a reference is in a memory file and updating it seems presumptuous, leave a `**Note (migration 0001):**` line and ask the user.

---

## Cross-references

- Conceptual tree: `~/.claude/NAMESPACE.md`
- Migration index: `~/.claude/migrations/MIGRATIONS.md`
- Prior formalization work: `~/.claude/scratchpad/global/20260406-std-claude-formalization-plan.md` (historical — treats `std::claude` as a single label)
- Shared library: `~/.claude/skills/shared/README.md`

---

## Notes

- The migration is deliberately split into three phases so Phase 0 is zero-risk and can be committed independently. Phase 1 touches many files and should be executed in one pass to minimize half-renamed intermediate states.
- `::migrations` is itself introduced by this migration. It bootstraps itself — the first doc in the log is the doc that creates the log.

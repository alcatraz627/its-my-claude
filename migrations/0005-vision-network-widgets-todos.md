# Migration 0005 — Add `::vision`, `::network`, `::widgets`, `::todos` namespaces

<!-- sessions: ns-plan-7f@2026-04-17 -->

**Status:** ✅ Phase 0c executed 2026-04-17 — namespaces documented in NAMESPACE.md; no files moved.
**Opened:** 2026-04-17
**Last updated:** 2026-04-17

---

## Summary

Introduce four new sibling namespaces under `std::claude::`:

- `::vision` **[facet]** — screen perception + desktop automation (4 path surfaces)
- `::network` — internet + local network helpers (1 current surface under `::scripts`, planned growth)
- `::widgets` **[facet]** — macOS widgets + mini-apps (1 current surface, planned `~/.claude/widgets/`)
- `::todos` **[facet]** — weekly/monthly task lists (3 path surfaces: root + scripts + archives)

Pure additive relabelling — zero file moves, zero hook changes, zero risk to existing references.

---

## Why

1. **Vision capability landed in the phase12 window.** `desktop.sh` (2026-04-17 02:29) and `annotate-screenshot.py` (2026-04-17 02:26) were added alongside the `assets/images/` screenshot convention and `shared/desktop-automation.md` reference. Without a shared label they appeared as loose `::scripts` entries. The vision-loop pattern (screenshot → annotate → read → act → verify) is a coherent subsystem that warrants its own label.
2. **Network surface exists and is intended to grow.** `scripts/gen-nginx-conf.sh` is a network-adjacent helper today. The user has signaled intent to add HTTP fetch wrappers and local discovery helpers. Labelling now avoids retroactive grouping.
3. **Widget subsystem is emerging.** `subconscious/dashboard.html` (the "dream dropdown") is the first concrete artifact. A system-monitor widget is planned. Without `::widgets`, the dashboard's identity as a *user-facing UI surface* gets lost inside `::improvement::dreams`.
4. **Todos already cleared the two-artifact threshold.** `weekly-todos.md` (file) + `scripts/weekly-todo.sh` (CLI) + `assets/docs/YYYYMMDD-todo-*.md` (archives) — three surfaces, existing workflow, merits a dedicated label separate from `::improvement::ideas` and `::code::ideas`.

---

## Scope

**In scope for this migration:**
- Add `::vision` section to NAMESPACE.md with 4-row facet table
- Add `::network` section to NAMESPACE.md as a `::scripts` sub-cluster with thin-surface flag
- Add `::widgets` section to NAMESPACE.md with facet marking
- Add `::todos` section to NAMESPACE.md with facet marking and distinction table vs other `::ideas`-style labels
- Update the tree section (insert four new rows)
- Update the facet count (4 → 7)
- Update the migration history table at the bottom of NAMESPACE.md
- Update MIGRATIONS.md index with a row for 0005

**Out of scope (no file moves):**
- `scripts/desktop.sh`, `scripts/annotate-screenshot.py`, `scripts/gen-nginx-conf.sh`, `scripts/weekly-todo.sh` all stay in `~/.claude/scripts/`
- `subconscious/dashboard.html` stays under `::improvement::dreams` by physical path
- `assets/images/`, `assets/docs/YYYYMMDD-todo-*.md` stay under `::assets` by physical path
- `weekly-todos.md` stays at root
- `skills/shared/desktop-automation.md` stays under `::shared`
- The planned `~/.claude/widgets/` directory is NOT created as part of this migration — it awaits its first real widget

---

## Label changes

No existing labels renamed. Only additions:

| New label | Covers |
|---|---|
| `std::claude::vision` | Facet over 4 paths: `scripts/desktop.sh`, `scripts/annotate-screenshot.py`, `assets/images/`, `shared/desktop-automation.md` |
| `std::claude::network` | `scripts/gen-nginx-conf.sh` (current) + future network helpers |
| `std::claude::widgets` | Facet — `subconscious/dashboard.html` (current) + future `~/.claude/widgets/` |
| `std::claude::todos` | Facet over 3 paths: `weekly-todos.md`, `scripts/weekly-todo.sh`, `assets/docs/YYYYMMDD-todo-*.md` |

---

## Path moves

**None.** This migration is pure relabelling.

---

## Files affected

### Phase 0c — docs only (executed 2026-04-17)

| File | Change |
|---|---|
| `~/.claude/NAMESPACE.md` | **edit** — added 4 clusters, updated tree (7 facets now), updated migration history |
| `~/.claude/migrations/MIGRATIONS.md` | **edit** — added row for 0005 |
| `~/.claude/migrations/0005-vision-network-widgets-todos.md` | **created** — this doc |

Zero file moves, zero hook changes, zero renames of existing artifacts.

---

## Facet status (per new namespace)

| Namespace | Facet? | Reason |
|---|---|---|
| `::vision` | Yes | Artifacts live in 3 existing namespaces (`::scripts`, `::assets`, `::shared`). Each file fits its path's primary purpose; the label binds them conceptually. |
| `::network` | No | Single surface (`::scripts`) today. Promoted ahead of the "two-artifact threshold" per user intent. Revisit if it stalls at one artifact. |
| `::widgets` | Yes (provisional) | `dashboard.html` currently lives under `::improvement::dreams`. When `~/.claude/widgets/` is created and populated, reconsider collapsing to a non-facet. |
| `::todos` | Yes | Three paths across root + `::scripts` + `::assets`. Moving any would break the CLI workflow. |

---

## Interaction with prior migrations

- **Migration 0001** — these are additive, not revisions. Phase 1 of 0001 (rename `std::claude` → `::shared`, create `~/.claude/code/` skeleton) is unaffected.
- **Migration 0002 (phase12 retrofit)** — `desktop.sh` and `annotate-screenshot.py` landed in the phase12 window; this migration labels them. Migration 0002 noted `scripts/desktop.sh` under `::scripts`; that is still correct by physical path, and now additionally labelled `::vision` by facet.
- **Migration 0003 (backups + improvement)** — `dashboard.html` is under `::improvement::dreams` by physical path; now additionally labelled `::widgets` by facet. Both labels apply without conflict per facet semantics.
- **Migration 0004 (memory global-first, planned)** — independent; no interaction.

---

## Recovery from stale references

If you see a reference to `~/.claude/widgets/` that doesn't resolve:

- The directory is planned but not yet created. A real widget must land before the path exists.
- The current widget (`subconscious/dashboard.html`) is *conceptually* `::widgets` but lives under `::improvement::dreams` physically. Update the reference to the actual path.

If you see a vision-related script expected under `~/.claude/vision/`:

- No such directory exists. Vision scripts live in `~/.claude/scripts/` (`desktop.sh`, `annotate-screenshot.py`).
- The `::vision` label is a facet — files do not move; only the conceptual grouping is new.

If you see a reference to `~/.claude/network/`:

- Same story — facet-style labelling, files live in `~/.claude/scripts/`. Check `scripts/gen-nginx-conf.sh` and any future `scripts/*net*`/`scripts/*http*`.

If you see a reference to `~/.claude/todos/`:

- No such directory. Canonical list is `~/.claude/weekly-todos.md`; CLI is `~/.claude/scripts/weekly-todo.sh`.

---

## Phases

| Phase | Scope | Status |
|---|---|---|
| 0c | Documentation writes (this migration's core work) | ✅ Executed 2026-04-17 |
| 1 | _(no Phase 1 needed — relabelling only)_ | — |

**Future phases that could be opened as separate migrations:**
- Create `~/.claude/widgets/` with a scaffold when the first dedicated widget (e.g., system monitor) lands. That would be a separate migration because it involves moving `dashboard.html` into the dir.
- Collapse `::network` back to plain `::scripts` if the cluster fails to grow — also a separate migration (a label retirement).

---

## Cross-references

- Conceptual tree (updated): `~/.claude/NAMESPACE.md`
- Migration 0001 (namespace intro): `~/.claude/migrations/0001-namespace-introduction.md`
- Migration 0002 (phase12 retrofit — where vision scripts first landed): `~/.claude/migrations/0002-phase12-upgrade-retrofit.md`
- Migration 0003 (backups + improvement): `~/.claude/migrations/0003-backups-improvement-namespaces.md`
- Index: `~/.claude/migrations/MIGRATIONS.md`
- Desktop automation reference: `~/.claude/skills/shared/desktop-automation.md`
- Weekly todos CLI: `~/.claude/scripts/weekly-todo.sh`

---

## Notes

- The `::widgets` facet is provisional. Most facets stay facets permanently because their distribution is inherent (like `::backups` or `::improvement`). `::widgets` is different — it may collapse to a single-directory non-facet (`~/.claude/widgets/`) once a second widget lands and the directory becomes worth creating.
- The `::network` promotion with only one artifact is a deliberate exception to the "wait for two" rule — the user explicitly flagged growth intent. Flag for cleanup review at ~2 months if it stalls.
- The distinction table inside the `::todos` section is worth preserving: four different `::ideas`/intent-tracking labels (`::todos`, `::improvement::ideas`, `::improvement::proposals`, `::code::ideas`) each serve a different audience and lifecycle.

# Migration 0002 — Phase 1+2 upgrade (retrofit)

<!-- sessions: upgrade-phase12-7c@2026-04-17, ns-plan-7f@2026-04-17 -->

**Status:** ✅ Applied — retrofit doc written 2026-04-17; underlying changes landed 2026-04-17 by session `upgrade-phase12-7c`.
**Type:** Retrospective / backfill — documents a structural change that occurred before the migration log existed.
**Opened:** 2026-04-17
**Last updated:** 2026-04-17

---

## Summary

Back-fill a migration doc for the Phase 1+2 global config upgrade that landed on 2026-04-17 via session `upgrade-phase12-7c` (session ID: `867071c7-fbda-4044-aef3-fe69f068ef16`). The upgrade introduced global observability, new hooks, new skills, WAL JSONL canonicalization, and a named-backup convention — all of which need to be locatable in the namespace tree.

---

## Why (retrospective)

1. The migration log (`::migrations`) was introduced by 0001 *after* this upgrade landed, so Phase 1+2 was never tracked as a structural change.
2. Future agents grepping `MIGRATIONS.md` for "when did `events.jsonl` appear?" or "why do we have `~/.claude/subconscious/`?" need to find it.
3. The namespace tree (`NAMESPACE.md`) needs accurate surface membership for every introduced artifact.

---

## Scope

**Retrofit only — no new files created by this migration.** Everything below already exists on disk.

---

## Artifacts introduced by the underlying upgrade

### New state surfaces

| Path | Namespace | Purpose |
|---|---|---|
| `~/.claude/events.jsonl` | `::scripts` (writer) + `::improvement::insights` (consumer) | Global, append-only, one line per hook firing. Fields: `ts`, `event`, `session_id`, `cwd`, `project`, `prompt_preview`, `duration_ms?`, `error?`, `cost_delta_usd?` |
| `~/.claude/assets/backups/20260417-phase12-upgrade/` | `::backups` | Pristine settings.json snapshot + 130-line `RESTORE.md` with symptom → cause → revert commands |
| `~/.claude/assets/backups/events-archive/` | `::backups` | Gzipped rotated `events.jsonl` files (rotated at 50MB by `rotate-events.sh`) |
| `~/.claude/assets/backups/wal-archive/` | `::backups` | Rotated `wal.jsonl` files (global + project-local), rotation at 5MB |
| `~/.claude/subconscious/` + sub-dirs (`dreams/`, `metacog/`, `introspection/`, `intentions/`, `valence/`, `logs/`, `hooks/`) | `::improvement::dreams` | Async self-reflection daemon system |
| `~/.claude/skills/runtime-notes-archive-2026-Q1.md`, `-Q2.md` | `::improvement::insights` | Quarterly archives from `/archive-notes` skill |
| `~/.claude/assets/reports/20260417-0144-phase12-complete/index.html` | `::assets` | Self-contained HTML upgrade report |
| `~/.claude/assets/reports/20260417-phase12-complete.md` | `::assets` | Source markdown for the report (restyleable via `/create-report`) |

### New executables (all under `::scripts`)

| Script | Purpose |
|---|---|
| `scripts/emit-event.sh` | Appends JSONL line per hook firing; flock-guarded, async, fails soft |
| `scripts/find-events-log.sh` | Resolver so skills don't hardcode `events.jsonl` path |
| `scripts/block-nested-claude.sh` | PreToolUse hook — blocks `/.claude/.claude/` paths |
| `scripts/rotate-events.sh` | Stop hook — archives events.jsonl at 50MB (override via `EVENTS_ROTATE_THRESHOLD`) |
| `scripts/rotate-wal.sh` | Stop hook — archives wal.jsonl at 5MB (override via `WAL_ROTATE_THRESHOLD`) |
| `scripts/prune-backups.sh` | CLI/weekly — trashes `assets/backups/` items >180 days old |
| `scripts/validate-memory.sh` | CLI/CI — scans memory files for stale path refs |
| `scripts/test-hooks.sh` | CLI/CI — 16 tests against hook scripts, `HOME`-override isolation |
| `scripts/wal.sh` | CLI helper — appends JSONL lines to WAL via `jq -cn` |
| `scripts/wal-convert.sh` | One-shot — `wal.md` → `wal.jsonl` via python3 state machine |
| `scripts/propose.sh` | CLI — cross-session improvement backlog (`add`/`list`/`show`/`done`/`reject`) |

### New skills (all under `::skills`)

| Skill | Purpose |
|---|---|
| `skills/doctor/SKILL.md` | `/doctor` — env health check (worktrees, pm2, disk, WAL staleness, git dirty, event log, hook integrity, MCP validity) |
| `skills/past-sessions/SKILL.md` | `/past-sessions` — browse/search/summarize JSONL transcripts under `~/.claude/projects/` |

### New self-correction artifacts (`::improvement`)

| Path | Sub-label | Purpose |
|---|---|---|
| `~/.claude/mistake-patterns.md` | `::improvement::mistakes` | Pattern catalog, max 20, with "Triggered" dates; updated after user corrections |
| `~/.claude/proposals.jsonl` | `::improvement::proposals` | Append-only improvement backlog; status lifecycle (open/done/rejected) |

### Format migrations

| What | Old | New | Fallback |
|---|---|---|---|
| WAL format | `.claude/wal.md` | `.claude/wal.jsonl` | Markdown still honored by `/catchup` Phase 0.5 |

### Hook flips (async)

- `subconscious/post-tool-use` → async
- `subconscious/stop` → async
- `subconscious/user-prompt-submit` → async
- Sync hooks that emit `additionalContext` remained sync

---

## Namespace implications

This migration does not create a namespace; it assigns the above artifacts to existing namespaces (`::scripts`, `::skills`, `::assets`, `::backups`, `::improvement::*`). The `::backups` and `::improvement` namespaces themselves are introduced by Migration 0003.

---

## Recovery from stale references

If you encounter:

- **`~/.claude/wal.md`** (a reference expecting the markdown WAL): it still works as a fallback for `/catchup`. For new writes, use `wal.jsonl` + `wal.sh` helper.
- **A hook not firing that used to**: check whether it flipped async. Async hooks don't block but emit via `emit-event.sh`. Grep `events.jsonl` for the event.
- **`improvement-ideas.md` referenced as `code/ideas/ROADMAP.md`**: the original Phase 1 plan of Migration 0001 included that move. It was dropped in favor of relabelling (`::improvement::ideas` — file stays at root). See Migration 0001 "Revisions" section.
- **A path under `~/.claude/subconscious/`** that looks orphaned: it's part of `::improvement::dreams`. See NAMESPACE.md.

---

## Revert

Full procedure: `~/.claude/assets/backups/20260417-phase12-upgrade/RESTORE.md`.

Key reverts available:
- Hook registrations (settings.json diff)
- Async hook flips
- WAL JSONL migration (the wal-convert is one-way; markdown remains as archive)

---

## Cross-references

- Full upgrade report: `~/.claude/assets/reports/20260417-0144-phase12-complete/index.html`
- Source markdown: `~/.claude/assets/reports/20260417-phase12-complete.md`
- RESTORE guide: `~/.claude/assets/backups/20260417-phase12-upgrade/RESTORE.md`
- Memory reference: `~/.claude/projects/-Users-alcatraz627--claude/memory/reference_phase12_upgrade.md`
- Event log: `~/.claude/events.jsonl`
- LOOKUP rows: "Upgrade Reports & Backups" section in `~/.claude/LOOKUP.md`

---

## Notes

- This doc is deliberately descriptive rather than prescriptive — the changes already shipped. Its job is to make them findable via the migration index.
- Future structural changes should open a migration *before* executing, not after. This retrofit exists only because the `::migrations` cluster didn't exist when Phase 1+2 landed.

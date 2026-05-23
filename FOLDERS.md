# FOLDERS.md — Top-level folder index for `~/.claude/`

> Generated index of every top-level directory under `~/.claude/`. Companion to `LOOKUP.md` (address book), `NAMESPACE.md` (logical clusters), `PLACEMENT.md` (placement rules), `GLOSSARY.md` (terms).
>
> **Regenerate:** `bash ~/.claude/scripts/folders-index.sh > ~/.claude/FOLDERS.md` (regenerates header + last-updated table; preserves the long-form policy section below the marker).
>
> **Last regenerated:** 2026-05-15 (initial — by /claude-audit session)

---

## How to use this doc

1. **Adding a new file to `~/.claude/`?** Find the right folder below. If nothing fits, see `PLACEMENT.md` — likely a new sub-file under `rules/`/`features/`/`conventions/` rather than a new top-level folder.
2. **Cleaning up?** Anthropic-managed folders are off-limits — leave them alone. User folders have intent notes; respect them.
3. **Folder unfamiliar?** Check the **Intent** column. If empty, it's likely orphaned debris (file an entry in `improvement-ideas.md` rather than touching).

---

## Anthropic-managed (Claude Code runtime — DO NOT TOUCH)

These folders are created and maintained by Claude Code itself. Touching them risks corrupting session state, file-history snapshots, or telemetry.

| Folder | What's inside | Note |
|---|---|---|
| `agents/` | Agent definitions/state | Single file, rarely touched |
| `file-history/` | Per-session file snapshots (UUID-keyed) | Drives undo/external-edit detection. Large (~123 MB at 6 mo) but normal |
| `ide/` | Claude Code IDE integration state | |
| `plugins/` | Installed plugin marketplace data | ~1 GB — biggest single dir, normal |
| `projects/` | Per-session conversation transcripts (UUID-keyed jsonl) | ~790 MB — pruned by `std::claude::startup` (gzip at 6 mo, delete at 12 mo) |
| `session-env/` | Per-session env captures (UUID subdirs) | 880 subdirs, mostly empty — Anthropic cleanup expected |
| `sessions/` | Session metadata | |
| `statsig/` | Feature-flag SDK cache | |
| `tasks/` | TaskCreate/TaskList persistence (UUID-keyed) | |
| `teams/` | Agent-team state | |
| `telemetry/` | Anonymized usage metrics | |
| `todos/` | Task list persistence (per session) | |

**Plus root files:** `config.json`, `settings.local.json` (Anthropic-managed); session state files like `wal.jsonl`/`wal.md` are co-owned (Claude writes, user reads/edits).

---

## User-created — POLICY-BEARING (where new config lives)

These are placement targets governed by `PLACEMENT.md`. Each has its own `README.md` (or `CLAUDE.md`) for policy detail.

| Folder | Purpose | Add here when | Don't add when |
|---|---|---|---|
| `rules/` | Behavioral rules — what Claude MUST do | Process rule, mandate, hard guardrail | It's how a thing works (→ `features/`), or how output looks (→ `conventions/`) |
| `features/` | Tool/subsystem/integration docs | Documenting a script, MCP, hook system, integration | It's a rule about behavior (→ `rules/`) |
| `conventions/` | Output/authoring standards | HTML format, CLI help shape, file-naming | It's a behavioral rule (→ `rules/`) |
| `scripts/` | Executable shell/Python/JS scripts | Reusable script that >1 skill or human invokes | One-off (→ `/tmp`), or prototype only (→ `scratchpad/`) |
| `skills/` | `/skill-name` definitions | Skill graduates from prototype, broadly useful | Project-specific (→ project's `.claude/skills/`) |
| `hinters/` | UserPromptSubmit hook hints | Per-prompt nudge based on prompt text | Per-tool hook (→ `settings.json` + `scripts/`) |
| `migrations/` | Numbered migration records | Major structural change to `~/.claude/` | Reversible config tweak |

---

## User-created — DATA / RUNTIME

Owned by user-built systems. Names reference owning subsystem; safe to inspect.

| Folder | Owner system | Purpose |
|---|---|---|
| `affirm/` | `/affirm` skill | Event log of confirmed-good behaviors (mirror of atone, planned/partial) |
| `assets/` | Several (reports, screenshots, docs, checkpoints) | **Archival** outputs intended to survive sessions. See `conventions/asset-management.md` |
| `atone/` | `/atone` skill | Mistake event log (`events.jsonl` is kernel-locked); see `rules/corrections.md` |
| `atone-snapshots/` | atone | Periodic snapshots of events.jsonl for recovery |
| `backups/` | misc | Manual or scripted backups of single files (e.g., settings.json.pre-atone.bak) |
| `cache/` | misc | Short-lived cached lookups |
| `checkpoints/` | `/core-dump` + `/catchup` | Session-keyed checkpoint pointers + chronological `index.jsonl` for picker. See `std::claude::checkpoints` in NAMESPACE.md |
| `assets/magi/<YYYYMMDD-HHMM-slug>/` | `/magi` skill | Per-task MAGI archive: voter prompts, proposals, votes, supervisor nomination, final artifact, meta.json. See `std::claude::magi` in NAMESPACE.md and design doc 20260518-magi-design.md |
| `claudew/` | `claudew` CLI wrapper | Plugin source for the claude-wrapper CLI |
| `code/` | unclear | 2 files; check before touching |
| `llm-mini-state/` | `mini` skill / Ollama | Cache + Ollama log for the local fast model |
| `logs/` | misc | Hook/script logs (tab-title-emit.log, mistake-patterns-graduation.log) |
| `memory/` | auto-memory | Per-project + global memory entries (the auto-loaded MEMORY.md system) |
| `mistake-patterns/` | atone derivation | Working dir for the consolidation cron |
| `mistakes/` | (legacy?) | Pre-atone mistake notes; verify before touching |
| `output/` | sub-agent outputs | Per `rules/sub-agent-outputs.md`, agents write material output here |
| `paste-cache/` | clipboard paste hook | Cached pastes from user prompts |
| `personas/` | (planned) | Persona prompts to style Claude per task — **not yet built out** |
| `plans/` | misc | Multi-session plan files (`/core-dump` scratchpads, etc.) |
| `scratchpad/` | scratchpad MCP + global | **Prototype** scratch space — see `reference_scratchpad_system.md` memory entry |
| `shell-logs/` | shell-mem MCP | Bash command history (DIY mem system) |
| `shell-snapshots/` | shell-mem MCP | Periodic snapshots of shell history |
| `subconscious/` | (custom system) | 101 MB; under review — leave alone |
| `tools/` | misc | 14 MB single subdir; check before touching |
| `topics/` | `/cogitate` skill | Topic-themed long-form notes |
| `widgets/` | statusline widget system | Widget definitions for the statusline (`features/tab-title.md` adjacent) |

---

## Three-way placement: ephemeral vs archival vs prototype

A common decision when writing files inside `~/.claude/`:

| Where | Lifetime | Use for |
|---|---|---|
| `/tmp/` | Reboot | Truly throwaway. State, locks, scratch state for the current session. |
| `~/.claude/scratchpad/` | Months | Prototype scripts and notes that *might* be referenced again but aren't proven |
| `~/.claude/assets/` | Indefinite | Reports, screenshots, docs, checkpoints intended to survive long-term |

**Decision rule:** If you don't think you'll need it again, `/tmp`. If you *might* reference it but don't trust it yet, `scratchpad/`. If it's a finished artifact (a report, a doc, a record), `assets/`. Full policy: `conventions/asset-management.md`.

---

<!-- AUTO-GENERATED BELOW — regenerated by scripts/folders-index.sh; do not hand-edit -->

## Census (auto-generated 2026-05-15 18:08)

| Folder | Size | Files | Subdirs | Last touched |
|---|---|---|---|---|
| `affirm/` | 144K | 3 | 1 | 2026-05-15 |
| `agents/` | 8.0K | 1 | 0 | 2026-01-29 |
| `assets/` | 432M | 3 | 15 | 2026-05-15 |
| `atone-snapshots/` | 528K | 1 | 5 | 2026-05-15 |
| `atone/` | 840K | 8 | 5 | 2026-05-15 |
| `backups/` | 700K | 5 | 0 | 2026-05-15 |
| `cache/` | 304K | 2 | 0 | 2026-05-15 |
| `claudew/` | 396K | 12 | 4 | 2026-05-15 |
| `code/` | 44K | 2 | 2 | 2026-05-01 |
| `conventions/` | 68K | 8 | 0 | 2026-04-28 |
| `features/` | 92K | 18 | 0 | 2026-05-15 |
| `file-history/` | 123M | 0 | 67 | 2026-05-15 |
| `hinters/` | 20K | 4 | 0 | 2026-05-15 |
| `ide/` | 4.0K | 1 | 0 | 2026-05-10 |
| `llm-mini-state/` | 108K | 2 | 0 | 2026-05-04 |
| `logs/` | 20K | 7 | 0 | 2026-05-15 |
| `memory/` | 76K | 0 | 1 | 2026-05-07 |
| `migrations/` | 64K | 8 | 0 | 2026-04-24 |
| `mistake-patterns/` | 16K | 1 | 0 | 2026-04-28 |
| `mistakes/` | 16K | 2 | 0 | 2026-05-13 |
| `output/` | 2.3M | 0 | 12 | 2026-04-11 |
| `paste-cache/` | 1.3M | 110 | 0 | 2026-05-15 |
| `personas/` | 32K | 5 | 0 | 2026-04-09 |
| `plans/` | 40K | 1 | 1 | 2026-04-22 |
| `plugins/` | 1.0G | 4 | 3 | 2026-05-15 |
| `projects/` | 790M | 0 | 48 | 2026-05-15 |
| `rules/` | 60K | 12 | 0 | 2026-05-15 |
| `scratchpad/` | 24M | 6 | 3 | 2026-05-01 |
| `scripts/` | 840K | 46 | 10 | 2026-05-15 |
| `session-env/` | 0B | 0 | 880 | empty |
| `sessions/` | 36K | 9 | 0 | 2026-05-15 |
| `shell-logs/` | 4.7M | 44 | 0 | 2026-05-15 |
| `shell-snapshots/` | 2.4M | 9 | 0 | 2026-05-15 |
| `skills/` | 67M | 7 | 52 | 2026-05-15 |
| `statsig/` | 36K | 4 | 0 | 2026-02-05 |
| `subconscious/` | 101M | 6 | 8 | 2026-05-15 |
| `tasks/` | 1.8M | 0 | 26 | 2026-05-15 |
| `teams/` | 4.0K | 0 | 1 | 2026-04-20 |
| `telemetry/` | 1.8M | 6 | 0 | 2026-03-03 |
| `todos/` | 756K | 189 | 0 | 2026-04-27 |
| `tools/` | 14M | 0 | 1 | 2026-04-06 |
| `topics/` | 16K | 4 | 0 | 2026-05-15 |
| `widgets/` | 8.8M | 2 | 2 | 2026-05-15 |

# FOLDERS.md — Top-level folder index for `~/.claude/`

> Generated index of every top-level directory under `~/.claude/`. Companion to `LOOKUP.md` (address book), `NAMESPACE.md` (logical clusters), `PLACEMENT.md` (placement rules), `GLOSSARY.md` (terms).
>
> **Regenerate:** `bash ~/.claude/scripts/folders-index.sh` (rewrites in place; preserves the policy section above the marker; add `--stdout` to preview). Never redirect with `> FOLDERS.md` — the shell truncates the file before the script reads it, destroying the policy section.
>
> **Last regenerated:** 2026-07-04 (session tag-skill; census + rules count refreshed)

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
| `tasks/` | TaskCreate/TaskList persistence (UUID-keyed) | |
| `teams/` | Agent-team state | |
| `telemetry/` | Anonymized usage metrics | |
| `daemon/` | Background-session daemon state: `roster.json` (supervisor pid, worker sessions, pty/rendezvous sockets), `dispatch/`, `attach-journal`, `control.key` | Owns the `bg` sessions `ListAgents` shows; sockets live under `/tmp/cc-daemon-<uid>/` |
| `jobs/` | Per-job `state.json` + `tmp/` keyed by an 8-char hash, plus `pins.json` | Harness job persistence; appeared 2026-09 |

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
| `mistakes/` | (legacy?) | Pre-atone mistake notes; verify before touching |
| `output/` | (legacy) | Early sub-agent output dir, newest entry 2026-05-24. CLAUDE.md now redirects `.claude/output/X` to `assets/reports/X`; nothing writes here |
| `paste-cache/` | clipboard paste hook | Cached pastes from user prompts |
| `personas/` | `/persona` skill | Working-mode persona prompts (40 files) plus `usage/` adoption log. Activation: `features/persona-activation.md` |
| `plans/` | misc | Multi-session plan files (`/core-dump` scratchpads, etc.) |
| `scratchpad/` | scratchpad MCP + global | **Prototype** scratch space — see `reference_scratchpad_system.md` memory entry |
| `shell-logs/` | shell-mem MCP | Bash command history (DIY mem system) |
| `shell-snapshots/` | shell-mem MCP | Periodic snapshots of shell history |
| `subconscious/` | (custom system) | 101 MB; under review — leave alone |
| `tools/` | misc | 14 MB single subdir; check before touching |
| `topics/` | `/cogitate` skill | Topic-themed long-form notes |
| `widgets/` | statusline widget system | Widget definitions for the statusline (`features/tab-title.md` adjacent) |
| `*-domain/` (memory-, sessions-, proposals-, hooks-feedback-) | i-dream engine | Per-domain event streams feeding the dream cycle. Each holds `events.jsonl` + `derived/` (session-start hinter `_tldr.txt` + `triggers.json`) + `dream/` (weekly LLM pass) + a `.i-dream-domain.toml` manifest; extracted idempotently by `extract-events.sh` (`_seen.json` cursor). `proposals-domain/events.jsonl` symlinks to `proposals.jsonl` (fed by `scripts/hooks/gcc-signal-capture.sh`, a SessionEnd hook). NOTE: `memory-domain/` (dream capture) is unrelated to `memory/` (auto-memory) despite the name |
| `i-dream/` | i-dream engine (source: `~/Code/Claude/i-dream`) | Runtime data for the dream engine: `daily/` digests, `derived/` cross-domain union (`*.union.*`), `domains/` manifests, `injections.jsonl` (session-start context). Sibling of `subconscious/` |
| `ledger/` | `scripts/ledger/` | Value-system + alerting layer: `goals.toml`, `detectors.toml`, `efficacy.toml`, `plug-events.jsonl`, `alerts.jsonl` |
| `pinned/` | `/pin-for-dream` | Insights pinned for the next dream cycle; `consolidate.sh` decays them after ~2 cycles |
| `scheduled/` | `gcc-schedule` / routines | Cron/launchd routine registry (`registry.json` + `history.jsonl`) that runs the domain consolidations + dream passes |
| `session-notes/` | `/workspace` + `/core-dump` + `/catchup` | Per-session workspace docs (`<session-id>.md`: Todos / Notes / Doc Links / Decisions); `_active.md` points to the current session |
| `adapters/` | `features/codex-adapter.md` | Adapter code for driving a non-Claude model seat (today: `codex/`) from this config |
| `archive/` | `scripts/archive-transcripts.sh` | Archived session transcripts plus `archive.log`; the cold tier for `projects/` JSONL that `/revive` no longer needs hot |
| `cron-duties/` | `scripts/cron/cron-duty.sh` | One JSON per recurring session-scoped duty (heartbeats, warden check-ins): stable slug, arming process, liveness verdict, so a resume does not re-arm a duty whose process is still alive |
| `deployq/` | `scripts/deployq/deployq.sh` + `worker.sh` | Deploy queue: `pending/` → `running/` → `done/`, with `reports/`. The worker is a cron duty |
| `feedback/` | (empty) | Reserved, nothing writes here yet; candidate for removal at the next map |
| `git-hooks/` | `core.hooksPath` (mig 0039, 0040) | Global git hooks for every repo on the machine; `commit-msg` strips harness trailers, `guard-commit-signature.sh` is the hard block |
| `goals/` | `scripts/goal/goal.sh` | One JSON per session goal (`<session-uuid>.json`; `.cleared` suffix once disarmed). Read by the goal hinters and the Stop harness |
| `groups/` | `scripts/group/group.sh` | Per-group entity records (members, one goal, declared stores, authority line) per the 2026-08-26 IPC ruling; empty until a group is created |
| `kanban/` | `scripts/kanban/` server | Runtime data for the agent kanban: `registry.json`, `items.json`, `drafts.json`, `boards/`, `plans.jsonl`, rotated `.prev-*.bak` copies, plus review screenshots. Product code lives in `scripts/kanban/`; guide `features/kanban.md` |
| `review/` | `review/freshness.sh` | The lane-freshness detector: `registry.jsonl` maps each scheduled producer to its artifact and cadence; `freshness.sh` reads only mtimes and goes RED when a lane stops producing |
| `secrets/` | (owner) | Env files for audits and CI (`*.env`). Never read or print; gitignored |
| `session-state/` | `scripts/session-state/session-state.sh` | Per-session key/value state (`<sid>.json`, both full-uuid and 8-char forms); reaped at startup by `startup/tasks/60-reap-session-state.sh` |
| `skills-parked/` | mig 0048 | Skills taken off the roster but kept whole (34 as of 2026-09-05), with `INDEX.md` and `tags.tsv`. A parked skill is not invocable; citers must be swept when parking |
| `tasks-pins/` | `scripts/task-table/task-table.sh --pin` (mig 0057) | Per-session pin naming which task store `/tasks` renders, moved out of `tasks/` so the harness's store directory holds only stores |
| `auto-continue/` | `scripts/auto-continue.sh` + `hooks/auto-continue-stop.sh` | State for the auto-continue Stop hook; empty between runs |
| `dev-servers/` | `scripts/dev-servers/ports.sh` + `svc.sh` (mig 0029, 0043) | The port ledger (`port-registry.md`, `port-events.jsonl`) and the pm2 idle-lifecycle state (`svc-state.json`, `svc-events.jsonl`), plus `logs/`. Policy: `features/dev-servers.md` |
| `fiber-actions/` | fiber-snatcher (`features/fiber-snatcher.md`) | Per-run action bundles for React dev-app dispatches, hash-keyed |
| `guidance/` | guidance channel | `notes.md`: standing owner directives ("note this for the future"), surfaced relevance-gated by `hinters/06-guidance.sh` |
| `hooks/` | `std::claude::ledger` | Hook telemetry streams: `warn-events.jsonl` (advisory fires) and `feedback.jsonl` (hook feedback records). Hook SCRIPTS live in `scripts/hooks/`, not here |
| `run/` | `features/tmp-jail.md` | Runtime state for session-scoped confinement (`tmpjail/`); managed by `scripts/tmp-jail` and its guard/cleanup hooks |
| `style/` | `std::claude::style` (mig 0033, 0035) | The prose-quality control plane: `thesaurus.jsonl`, `derived/` verdict ledgers, `friction-ledger.jsonl`, glossary hint tables, `sweep/`. Readers: `scripts/style/` |
| `warden/` | `warden/warden-beat.sh` + `ward-revive.sh` | The watcher lane's runtime: `PROMPT.md`, `WATCH.md`, `ledger.jsonl`, `revive.jsonl`, `spend.jsonl`, `beat.log`, `state/`. Guide `features/warden.md` |

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

## Census (auto-generated 2026-09-05 13:44)

| Folder | Size | Files | Subdirs | Last touched |
|---|---|---|---|---|
| `adapters/` | 20K | 0 | 1 | 2026-08-15 |
| `affirm/` | 656K | 4 | 3 | 2026-08-25 |
| `agents/` | 16K | 3 | 0 | 2026-08-11 |
| `archive/` | 4.8G | 1 | 1 | 2026-09-05 |
| `assets/` | 944M | 4 | 19 | 2026-09-05 |
| `atone-snapshots/` | 7.9M | 1 | 16 | 2026-05-26 |
| `atone/` | 186M | 14 | 7 | 2026-09-05 |
| `auto-continue/` | 0B | 0 | 0 | empty |
| `backups/` | 1.1M | 5 | 0 | 2026-09-05 |
| `cache/` | 700K | 3 | 2 | 2026-09-05 |
| `checkpoints/` | 17M | 428 | 1 | 2026-09-05 |
| `claudew/` | 164K | 12 | 3 | 2026-09-03 |
| `code/` | 44K | 2 | 2 | 2026-05-01 |
| `conventions/` | 296K | 27 | 1 | 2026-09-01 |
| `cron-duties/` | 48K | 12 | 0 | 2026-09-05 |
| `daemon/` | 12K | 2 | 2 | 2026-09-05 |
| `deployq/` | 24K | 0 | 4 | 2026-08-27 |
| `dev-servers/` | 72K | 5 | 1 | 2026-09-05 |
| `features/` | 232K | 33 | 0 | 2026-09-02 |
| `feedback/` | 0B | 0 | 0 | empty |
| `fiber-actions/` | 24K | 0 | 2 | 2026-07-04 |
| `file-history/` | 244M | 0 | 346 | 2026-09-05 |
| `git-hooks/` | 44K | 11 | 0 | 2026-07-28 |
| `goals/` | 208K | 52 | 0 | 2026-09-05 |
| `groups/` | 0B | 0 | 0 | empty |
| `guidance/` | 4.0K | 1 | 0 | 2026-07-10 |
| `hinters/` | 112K | 24 | 0 | 2026-09-05 |
| `hooks-feedback-domain/` | 176K | 2 | 2 | 2026-09-03 |
| `hooks/` | 5.8M | 3 | 0 | 2026-09-05 |
| `i-dream/` | 15M | 9 | 8 | 2026-09-05 |
| `ide/` | 4.0K | 1 | 0 | 2026-08-31 |
| `jobs/` | 148K | 2 | 2 | 2026-09-05 |
| `kanban/` | 5.7M | 70 | 2 | 2026-09-05 |
| `ledger/` | 2.8M | 10 | 0 | 2026-09-05 |
| `llm-mini-state/` | 108K | 2 | 0 | 2026-05-04 |
| `logs/` | 21M | 24 | 1 | 2026-09-05 |
| `memory-domain/` | 200K | 5 | 2 | 2026-09-05 |
| `memory/` | 108K | 0 | 1 | 2026-07-09 |
| `migrations/` | 340K | 58 | 0 | 2026-09-04 |
| `mistakes/` | 32K | 3 | 0 | 2026-05-13 |
| `output/` | 2.3M | 0 | 13 | 2026-05-24 |
| `paste-cache/` | 1.1M | 178 | 0 | 2026-09-05 |
| `personas/` | 392K | 25 | 2 | 2026-09-05 |
| `pinned/` | 440K | 4 | 3 | 2026-09-05 |
| `plans/` | 72K | 2 | 1 | 2026-08-31 |
| `plugins/` | 1.1G | 5 | 3 | 2026-09-05 |
| `projects/` | 5.4G | 1 | 118 | 2026-09-05 |
| `proposals-domain/` | 72K | 1 | 2 | 2026-09-05 |
| `review/` | 8.0K | 2 | 0 | 2026-08-21 |
| `rules/` | 408K | 64 | 0 | 2026-09-04 |
| `run/` | 0B | 0 | 1 | empty |
| `scheduled/` | 312K | 10 | 28 | 2026-09-05 |
| `scratchpad/` | 24M | 6 | 4 | 2026-09-04 |
| `scripts/` | 81M | 97 | 50 | 2026-09-05 |
| `secrets/` | 4.0K | 1 | 0 | 2026-08-28 |
| `session-env/` | 6.4M | 0 | 1633 | 2026-09-05 |
| `session-notes/` | 172K | 41 | 0 | 2026-09-03 |
| `session-state/` | 52K | 13 | 0 | 2026-09-05 |
| `sessions-domain/` | 2.0M | 5 | 2 | 2026-08-06 |
| `sessions/` | 56K | 14 | 0 | 2026-09-05 |
| `shell-logs/` | 29M | 157 | 0 | 2026-09-05 |
| `shell-snapshots/` | 2.6M | 19 | 0 | 2026-09-05 |
| `skills-parked/` | 5.7M | 3 | 32 | 2026-08-27 |
| `skills/` | 80M | 8 | 74 | 2026-09-05 |
| `style/` | 58M | 251 | 2 | 2026-09-05 |
| `subconscious/` | 545M | 7 | 9 | 2026-09-05 |
| `tasks-pins/` | 16K | 4 | 0 | 2026-09-05 |
| `tasks/` | 49M | 5781 | 327 | 2026-09-05 |
| `teams/` | 272K | 0 | 22 | 2026-09-05 |
| `telemetry/` | 3.4M | 16 | 0 | 2026-08-12 |
| `tools/` | 14M | 0 | 1 | 2026-08-24 |
| `topics/` | 752K | 88 | 0 | 2026-09-05 |
| `warden/` | 1.2M | 15 | 3 | 2026-09-02 |
| `widgets/` | 776M | 5 | 2 | 2026-09-05 |

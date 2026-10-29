# FOLDERS.md: Top-level folder index for `~/.claude/`

> Generated index of every top-level directory under `~/.claude/`. Companion to `LOOKUP.md` (address book), `NAMESPACE.md` (the fourteen words for the parts of the gcc), `PLACEMENT.md` (placement rules), `GLOSSARY.md` (terms).
>
> **Regenerate:** `bash ~/.claude/scripts/folders-index.sh` (rewrites in place; preserves the policy section above the marker; add `--stdout` to preview). Never redirect with `> FOLDERS.md`: the shell truncates the file before the script reads it, destroying the policy section.
>
> **Last regenerated:** 2026-07-04 (session tag-skill; census + rules count refreshed)

---

## How to use this doc

1. **Adding a new file to `~/.claude/`?** Find the right folder below. If nothing fits, see `PLACEMENT.md`: likely a new sub-file under `rules/`/`features/`/`conventions/` rather than a new top-level folder.
2. **Cleaning up?** Anthropic-managed folders are off-limits: leave them alone. User folders have intent notes; respect them.
3. **Folder unfamiliar?** Check the **Intent** column. If empty, it's likely orphaned debris (file an entry in `improvement-ideas.md` rather than touching).

---

## Anthropic-managed (Claude Code runtime: DO NOT TOUCH)

These folders are created and maintained by Claude Code itself. Touching them risks corrupting session state, file-history snapshots, or telemetry.

| Folder | What's inside | Note |
|---|---|---|
| `agents/` | Agent definitions/state | Single file, rarely touched |
| `file-history/` | Per-session file snapshots (UUID-keyed) | Drives undo/external-edit detection. Large (~123 MB at 6 mo) but normal |
| `ide/` | Claude Code IDE integration state | |
| `plugins/` | Installed plugin marketplace data | ~1 GB: biggest single dir, normal |
| `projects/` | Per-session conversation transcripts (UUID-keyed jsonl) | ~790 MB: pruned by `scripts/startup/` (gzip at 6 mo, delete at 12 mo) |
| `session-env/` | Per-session env captures (UUID subdirs) | 880 subdirs, mostly empty: Anthropic cleanup expected |
| `sessions/` | Session metadata | |
| `tasks/` | TaskCreate/TaskList persistence (UUID-keyed) | |
| `teams/` | Agent-team state | |
| `telemetry/` | Anonymized usage metrics | |
| `daemon/` | Background-session daemon state: `roster.json` (supervisor pid, worker sessions, pty/rendezvous sockets), `dispatch/`, `attach-journal`, `control.key` | Owns the `bg` sessions `ListAgents` shows; sockets live under `/tmp/cc-daemon-<uid>/` |
| `jobs/` | Per-job `state.json` + `tmp/` keyed by an 8-char hash, plus `pins.json` | Harness job persistence; appeared 2026-09 |
| `chrome/` | `chrome-native-host`, a generated launcher for `claude --chrome-native-host` | Written by Claude Code's Chrome integration; do not edit |

**Plus root files:** `config.json`, `settings.local.json` (Anthropic-managed); session state files like `wal.jsonl`/`wal.md` are co-owned (Claude writes, user reads/edits).

---

## User-created: POLICY-BEARING (where new config lives)

These are placement targets governed by `PLACEMENT.md`. Each has its own `README.md` (or `CLAUDE.md`) for policy detail.

| Folder | Purpose | Add here when | Don't add when |
|---|---|---|---|
| `rules/` | Behavioral rules: what Claude MUST do | Process rule, mandate, hard guardrail | It's how a thing works (→ `features/`), or how output looks (→ `conventions/`) |
| `features/` | Tool/subsystem/integration docs | Documenting a script, MCP, hook system, integration | It's a rule about behavior (→ `rules/`) |
| `conventions/` | Output/authoring standards | HTML format, CLI help shape, file-naming | It's a behavioral rule (→ `rules/`) |
| `scripts/` | Executable shell/Python/JS scripts | Reusable script that >1 skill or human invokes | One-off (→ `/tmp`), or prototype only (→ `scratchpad/`) |
| `skills/` | `/skill-name` definitions | Skill graduates from prototype, broadly useful | Project-specific (→ project's `.claude/skills/`) |
| `hinters/` | UserPromptSubmit hook hints | Per-prompt nudge based on prompt text | Per-tool hook (→ `settings.json` + `scripts/`) |
| `migrations/` | Numbered migration records | Major structural change to `~/.claude/` | Reversible config tweak |

---

## User-created: DATA / RUNTIME

Owned by user-built systems. Names reference owning subsystem; safe to inspect.

| Folder | Owner system | Purpose |
|---|---|---|
| `affirm/` | `/affirm` skill | Event log of confirmed-good behaviors (mirror of atone, planned/partial) |
| `assets/` | Several (reports, screenshots, docs, checkpoints) | **Archival** outputs intended to survive sessions. See `conventions/asset-management.md` |
| `atone/` | `/atone` skill | Mistake event log (`events.jsonl` is kernel-locked); see `rules/corrections.md` |
| `atone-snapshots/` | atone | Periodic snapshots of events.jsonl for recovery |
| `backups/` | misc | Manual or scripted backups of single files (e.g., settings.json.pre-atone.bak) |
| `cache/` | misc | Short-lived cached lookups |
| `checkpoints/` | `/core-dump` + `/catchup` | Session-keyed checkpoint pointers + chronological `index.jsonl` for picker. Part of **checkpoints** in NAMESPACE.md |
| `assets/magi/<YYYYMMDD-HHMM-slug>/` | `/magi` skill | Per-task MAGI archive: voter prompts, proposals, votes, supervisor nomination, final artifact, meta.json. Part of **seats** in NAMESPACE.md; design doc 20260518-magi-design.md |
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
| `scratchpad/` | scratchpad MCP + global | **Prototype** scratch space: see `reference_scratchpad_system.md` memory entry |
| `shell-logs/` | shell-mem MCP | Bash command history (DIY mem system) |
| `shell-snapshots/` | shell-mem MCP | Periodic snapshots of shell history |
| `subconscious/` | (custom system) | 101 MB; under review: leave alone |
| `tools/` | misc | 14 MB single subdir; check before touching |
| `topics/` | `/cogitate` skill | Topic-themed long-form notes |
| `widgets/` | statusline widget system | Widget definitions for the statusline (`features/tab-title.md` adjacent) |
| `*-domain/` (memory-, sessions-, proposals-, hooks-feedback-) | i-dream engine | Per-domain event streams feeding the dream cycle. Each holds `events.jsonl` + `derived/` (session-start hinter `_tldr.txt` + `triggers.json`) + `dream/` (weekly LLM pass) + a `.i-dream-domain.toml` manifest; extracted idempotently by `extract-events.sh` (`_seen.json` cursor). `proposals-domain/events.jsonl` symlinks to `proposals.jsonl` (fed by `scripts/hooks/gcc-signal-capture.sh`, a SessionEnd hook). NOTE: `memory-domain/` (dream capture) is unrelated to `memory/` (auto-memory) despite the name |
| `i-dream/` | i-dream engine (source: `~/Code/Claude/i-dream`) | Runtime data for the dream engine: `daily/` digests, `derived/` cross-domain union (`*.union.*`), `domains/` manifests, `injections.jsonl` (session-start context). Sibling of `subconscious/` |
| `ledger/` | `scripts/ledger/` | Value-system + alerting layer: `goals.toml`, `detectors.toml`, `efficacy.toml`, `plug-events.jsonl`, `alerts.jsonl` |
| `pinned/` | `/pin-for-dream` | Insights pinned for the next dream cycle; `consolidate.sh` decays them after ~2 cycles |
| `scheduled/` | `gcc-schedule` / routines | Cron/launchd routine registry (`registry.json` + `history.jsonl`) that runs the domain consolidations + dream passes |
| `session-notes/` | `/workspace` + `/core-dump` + `/catchup` | Per-session workspace docs (`<session-id>.md`: Todos / Notes / Doc Links / Decisions); `_active.md` points to the current session |
| `adapters/` | `features/codex-adapter.md` | Adapter code for driving a non-Claude model seat (`codex/`) from this config, and `claude-app/`, the skills-only plugin for claude.ai chat that `.claude-plugin/marketplace.json` at the root lists |
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
| `hooks/` | `scripts/hooks/warn-log.sh` (the **ledger** word) | Hook telemetry streams: `warn-events.jsonl` (advisory fires) and `feedback.jsonl` (hook feedback records). Hook SCRIPTS live in `scripts/hooks/`, not here |
| `run/` | `features/tmp-jail.md` | Runtime state for session-scoped confinement (`tmpjail/`); managed by `scripts/tmp-jail` and its guard/cleanup hooks |
| `style/` | `scripts/style/` (mig 0033, 0035; the **gates** word) | The prose-quality control plane: `thesaurus.jsonl`, `derived/` verdict ledgers, `friction-ledger.jsonl`, glossary hint tables, `sweep/`. Readers: `scripts/style/` |
| `warden/` | `warden/warden-beat.sh` + `ward-revive.sh` | The watcher lane's runtime: `PROMPT.md`, `WATCH.md`, `ledger.jsonl`, `revive.jsonl`, `spend.jsonl`, `beat.log`, `state/`. Guide `features/warden.md` |
| `checkpoints-domain/` | i-dream domain feed, `checkpoints-domain/extract-events.py` | Session checkpoint summaries as an event stream: `events.jsonl`, `_seen.json`, `derived/`, `dream/` |
| `compact-gate/` | `scripts/session-mgmt/compact-gate.sh` | The compact gate's decision log (`events.jsonl`) |
| `dev-mods/` | unclear | Four session-named folders, one holding a `gcc-mock/`; no script or doc names this path. Check before touching |
| `handoffs/` | `scripts/schedule/handoff.sh` (`features/weekly-tags.md`) | Notes queued for the Tuesday gcc session: one file per tag in `tags/`, plus `history.jsonl` and the `.json` cards Switchboard reads |
| `keepwarm/` | `scripts/keepwarm/keepwarm.py` | One state file per session for keep-warm; the status line reads it too |
| `ledger-archive/` | `scripts/ledger/ledger-prune.py` (`scripts/ledger/ledger-retention.json`) | Gzipped monthly archives of old ledger lines, one folder per ledger, plus `_prune-log.jsonl`. Kept, never deleted |
| `mods/` | `features/gcc-mods.md` | Source of the gcc-mods mod (`gcc-mods/`: hooks, types, README) |
| `node_modules/` | unclear | Only a `.vite/` cache; nothing names this path |
| `policy/` | `scripts/pol/` (`features/agent-policy.md`) | Switchboard's live `policy.json`, five numbered backups and `registry.json`. Only the owner writes it |
| `rules-provenance/` | `rules/` | The full reasoning and lived cases behind each rule, one file per rule |
| `seats/` | `scripts/seats/seat` | Sub-agent dispatch ledger: `dispatch.jsonl`, `refusals.jsonl`, and one `s-<id>.json` plus prompt per seat |
| `seats-domain/` | `scripts/seats/seat` (i-dream manifest, consolidation off) | Event stream of seats (role, model, outcome, caller feedback) |
| `skill-usage-domain/` | i-dream domain feed, `skill-usage-domain/extract-events.py` | Skill invocations per session, from `skills/usage/invocations.jsonl` |
| `snippets/` | none (likely left from the gcc-mods snippets store, removed 2026-10-15) | Three nearly empty JSONL files; candidate for removal |
| `transcripts/` | unclear | One opencode-style `ses_*.jsonl` from 2026-09-25; `archive-transcripts.sh` writes to `archive/transcripts/`, not here |
| `usage5h/` | `scripts/usage/usage5h.py` (`features/usage-speedbumps.md`) | The 5-hour usage tracker: per-session lock files and `events.jsonl` |
| `zrecover/` | `scripts/zrecover/zrecover.py` (`features/zrecover.md`) | Session recovery state: `bundles/`, `screens/`, `wraps/`, `sessions.json`, `daemon.json`, `grants.json`, logs |

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

<!-- AUTO-GENERATED BELOW: regenerated by scripts/folders-index.sh; do not hand-edit -->

## Census (auto-generated 2026-10-28 03:28)

| Folder | Size | Files | Subdirs | Last touched |
|---|---|---|---|---|
| `adapters/` | 712K | 0 | 1 | 2026-10-27 |
| `affirm/` | 780K | 4 | 3 | 2026-10-06 |
| `agents/` | 16K | 3 | 0 | 2026-08-11 |
| `archive/` | 14G | 1 | 1 | 2026-10-27 |
| `assets/` | 1.9G | 4 | 20 | 2026-10-28 |
| `atone-snapshots/` | 191M | 1 | 18 | 2026-10-28 |
| `atone/` | 358M | 15 | 7 | 2026-10-27 |
| `auto-continue/` | 0B | 0 | 0 | empty |
| `backups/` | 33M | 9 | 5 | 2026-10-28 |
| `cache/` | 1.2M | 3 | 3 | 2026-10-28 |
| `checkpoints-domain/` | 652K | 4 | 2 | 2026-10-27 |
| `checkpoints/` | 42M | 3807 | 5 | 2026-10-28 |
| `chrome/` | 4.0K | 1 | 0 | 2026-10-27 |
| `claudew/` | 164K | 12 | 3 | 2026-10-06 |
| `code/` | 44K | 2 | 2 | 2026-05-01 |
| `compact-gate/` | 240K | 1 | 0 | 2026-10-27 |
| `conventions/` | 340K | 31 | 1 | 2026-10-27 |
| `cron-duties/` | 64K | 16 | 0 | 2026-09-25 |
| `daemon/` | 8.0K | 2 | 2 | 2026-09-09 |
| `deployq/` | 24K | 0 | 4 | 2026-08-27 |
| `dev-mods/` | 1.9M | 0 | 4 | 2026-10-06 |
| `dev-servers/` | 136K | 6 | 1 | 2026-10-28 |
| `features/` | 348K | 45 | 0 | 2026-10-27 |
| `feedback/` | 8.0K | 0 | 1 | 2026-10-01 |
| `fiber-actions/` | 24K | 0 | 2 | 2026-07-04 |
| `file-history/` | 1.0G | 0 | 644 | 2026-10-28 |
| `git-hooks/` | 44K | 11 | 0 | 2026-10-27 |
| `goals/` | 1.4M | 185 | 3 | 2026-10-27 |
| `groups/` | 0B | 0 | 0 | empty |
| `guidance/` | 4.0K | 1 | 0 | 2026-07-10 |
| `handoffs/` | 16K | 3 | 1 | 2026-10-27 |
| `hinters/` | 132K | 28 | 0 | 2026-10-27 |
| `hooks-feedback-domain/` | 252K | 3 | 2 | 2026-10-27 |
| `hooks/` | 8.4M | 4 | 0 | 2026-10-28 |
| `i-dream/` | 38M | 10 | 9 | 2026-10-28 |
| `ide/` | 4.0K | 1 | 0 | 2026-08-31 |
| `jobs/` | 88K | 1 | 2 | 2026-09-09 |
| `kanban/` | 6.2M | 71 | 2 | 2026-10-27 |
| `keepwarm/` | 7.5M | 1844 | 0 | 2026-10-28 |
| `ledger-archive/` | 528K | 1 | 6 | 2026-10-15 |
| `ledger/` | 2.1M | 10 | 0 | 2026-10-28 |
| `llm-mini-state/` | 108K | 2 | 0 | 2026-05-04 |
| `logs/` | 39M | 43 | 1 | 2026-10-28 |
| `memory-domain/` | 212K | 5 | 2 | 2026-10-28 |
| `memory/` | 120K | 0 | 1 | 2026-10-27 |
| `migrations/` | 360K | 61 | 0 | 2026-10-27 |
| `mistakes/` | 32K | 3 | 0 | 2026-05-13 |
| `mods/` | 1.2M | 1 | 1 | 2026-10-28 |
| `node_modules/` | 24K | 0 | 1 | 2026-10-11 |
| `output/` | 2.3M | 0 | 13 | 2026-05-24 |
| `paste-cache/` | 1.3M | 232 | 0 | 2026-10-27 |
| `personas/` | 456K | 26 | 2 | 2026-10-27 |
| `pinned/` | 616K | 4 | 3 | 2026-10-27 |
| `plans/` | 72K | 2 | 1 | 2026-08-31 |
| `plugins/` | 472M | 6 | 5 | 2026-10-28 |
| `policy/` | 32K | 7 | 0 | 2026-10-24 |
| `projects/` | 15G | 1 | 189 | 2026-10-28 |
| `proposals-domain/` | 80K | 1 | 2 | 2026-10-26 |
| `review-lane/` | 4.0K | 1 | 0 | 2026-10-26 |
| `review/` | 8.0K | 2 | 0 | 2026-08-21 |
| `rules-provenance/` | 188K | 30 | 0 | 2026-10-27 |
| `rules/` | 356K | 67 | 0 | 2026-10-27 |
| `run/` | 0B | 0 | 1 | empty |
| `scheduled/` | 652K | 19 | 26 | 2026-10-28 |
| `scratchpad/` | 24M | 15 | 4 | 2026-10-26 |
| `scripts/` | 97M | 102 | 72 | 2026-10-28 |
| `seats-domain/` | 36K | 3 | 0 | 2026-10-27 |
| `seats/` | 400K | 53 | 0 | 2026-10-28 |
| `secrets/` | 4.0K | 1 | 0 | 2026-08-28 |
| `session-env/` | 11M | 0 | 2721 | 2026-10-28 |
| `session-notes/` | 220K | 53 | 0 | 2026-10-28 |
| `session-state/` | 84K | 21 | 0 | 2026-10-27 |
| `sessions-domain/` | 4.4M | 5 | 3 | 2026-10-28 |
| `sessions/` | 40K | 10 | 0 | 2026-10-28 |
| `shell-logs/` | 70M | 209 | 0 | 2026-10-28 |
| `shell-snapshots/` | 4.0M | 29 | 0 | 2026-10-28 |
| `skill-usage-domain/` | 144K | 4 | 2 | 2026-10-27 |
| `skills-parked/` | 5.7M | 3 | 32 | 2026-10-27 |
| `skills/` | 84M | 10 | 85 | 2026-10-28 |
| `snippets/` | 4.0K | 3 | 0 | 2026-10-06 |
| `state/` | 5.6M | 1 | 2 | 2026-10-28 |
| `style/` | 88M | 550 | 2 | 2026-10-28 |
| `subconscious/` | 382M | 8 | 10 | 2026-10-28 |
| `tasks-pins/` | 1.1M | 269 | 0 | 2026-10-27 |
| `tasks/` | 72M | 10043 | 559 | 2026-10-28 |
| `teams/` | 372K | 0 | 53 | 2026-10-28 |
| `telemetry/` | 7.2M | 20 | 0 | 2026-10-27 |
| `tools/` | 14M | 0 | 1 | 2026-08-24 |
| `topics/` | 1.3M | 128 | 0 | 2026-10-27 |
| `transcripts/` | 20K | 1 | 0 | 2026-09-25 |
| `usage5h/` | 48K | 556 | 0 | 2026-10-28 |
| `warden/` | 1.2M | 15 | 3 | 2026-09-02 |
| `widgets/` | 36M | 5 | 2 | 2026-10-28 |
| `zrecover/` | 3.1M | 5 | 4 | 2026-10-28 |

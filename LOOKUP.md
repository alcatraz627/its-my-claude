# Global Config Lookup Index

<!-- sessions: impr-conf-98@2026-04-06 -->

> **Address book for all Claude global configuration.**
> Read this file when you need to find where a rule, convention, or reference lives.
> CLAUDE.md carries only essential always-on rules. Everything else lives in dedicated files below.
> When creating a new dedicated doc, add it here.

---

## How to use this index

1. **Session start** — CLAUDE.md is auto-loaded. It contains compact rules + pointers here.
2. **Need details?** — Scan the trigger column below. Read only the file(s) relevant to your task.
3. **Creating new config?** — Write a dedicated file, add a row to this index, reference it from CLAUDE.md if it's always-on.

---

## Configuration Files

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/CLAUDE.md` | Core always-on rules (testing, git, shell, session ID, WAL, context) | Every session (auto-loaded) |
| `~/.claude/LOOKUP.md` | This index — address book for all config files | Need to find where a rule lives, or adding new config |
| `~/.claude/PLACEMENT.md` | **Two-axis placement rule (category × tier) + trigger taxonomy + anti-patterns.** Determines where new rules/features/conventions go. [impr-cfg-7a@2026-04-24] | Adding any new config file; reviewing an existing file's placement; Phase B migration |
| `~/.claude/GLOSSARY.md` | Terminology reference for the GCC — abbreviations, namespace labels, concepts, file conventions | Encountering unfamiliar shorthand; adding new terms the user introduces |
| `~/.claude/FOLDERS.md` | **Per-folder index** — every top-level dir under `~/.claude/`, owner (Anthropic vs user), purpose, what-goes-here / what-doesn't. Auto-regen via `scripts/folders-index.sh`. | Adding a new top-level folder, cleaning up unknown dirs, deciding where data goes |
| `~/.claude/memory/global/MEMORY.md` | Cross-project global memory tier index (14 universal feedback/user memories) | Any session — loaded via CLAUDE.md instruction alongside per-project memory |
| `~/.claude/settings.json` | Permissions, hooks, plugins, env vars, UI settings | Modifying hooks, permissions, or plugin config |
| `~/.claude/settings.local.json` | Local permission overrides (npm, git, skills, etc.) | Adding tool permissions for local dev |

## Rules, Features, Conventions

> Split out from `CLAUDE.md` in session `impr-cfg-7a@2026-04-24` (634-line → 122-line router). Every file carries YAML frontmatter with `brief`, `triggers` (prefixed `tool:`/`topic:`/`phrase:`/`skill:`/`mcp:`), `related`, `tier`, `category`, `updated`, `stale_after_days`. See `~/.claude/PLACEMENT.md` for the two-axis rule. Validate with `bash ~/.claude/scripts/validate-triggers.sh`.

### `rules/` — behavioral/process rules

| File | Brief | Primary triggers |
|------|-------|------------------|
| `rules/communication.md` | Terse protocol, scope control, state verification | `topic:terse-responses`, `topic:scope-control` |
| `rules/testing.md` | Test every non-trivial change; clean-slate; verify each change | `topic:testing`, `topic:verification` |
| `rules/shell.md` | Project-root-first grep, `trash` not `rm`, non-interactive flags | `topic:shell`, `tool:trash` |
| `rules/git.md` | Frequent commits, public by default, gitignore, no main push | `topic:git-commits`, `topic:github-repos` |
| `rules/corrections.md` | After-correction ritual: state mistake → invoke /atone → fix | `topic:user-corrections`, `phrase:"revert this"` |
| `rules/cron-calendar-companion.md` | Every cron (launchd/crontab/CronCreate) gets a companion `Automations` calendar event for human visibility; retire both together (sibling of `scheduling-discipline.md`; both in `std::claude::schedule`) | `topic:cron`, `topic:launchd`, `tool:CronCreate` |
| `rules/scheduling-discipline.md` | Cross-tool scheduling practice (`std::claude::schedule`): which scheduler for which job, --description required, naming, retire-after-fire, no-secrets-in-command, audit cadence, pause-vs-rm | `topic:scheduling`, `topic:cron`, `topic:launchd`, `tool:gcc-schedule` |
| `features/atone.md` | atone+affirm system — mistake/compliment event logs, derived views, hinters | `tool:atone`, `tool:affirm`, `topic:mistake-tracking` |

### `features/` — tool/subsystem/integration docs

| File | Brief | Primary triggers |
|------|-------|------------------|
| `features/wal.md` | Write-ahead log format, kinds, checkpoint cadence | `tool:wal`, `skill:catchup` |
| `features/memory.md` | Per-project + global memory, cascade rules | `topic:memory`, `phrase:"remember that"` |
| `features/context-retention.md` | Session ID, core-dump/catchup, scratchpad, archive cadence | `skill:core-dump`, `skill:catchup`, `topic:session-id` |
| `features/proposals.md` | Improvement backlog + self-feedback → canon lifecycle | `tool:propose.sh`, `topic:improvements` |
| `features/mcp-catalog.md` | MCP server catalog + add-mcp + version pinning | `tool:add-mcp`, `topic:mcp-setup` |
| `features/llm-mini.md` | Fast mini-model: CLI, chat, MCP, hook surfaces | `tool:llm-mini`, `skill:mini` |
| `features/hinter-pipeline.md` | UserPromptSubmit hints + autocorrect | `tool:hint-injector`, `skill:autocorrect` |
| `features/shared-library.md` | std::claude::shared Python + shell utilities | `tool:gum-tui.sh`, `topic:shared-utilities` |
| `features/plugins.md` | Disabled plugins registry + plugin-vs-skill | `topic:plugins`, `topic:skill-selection` |
| `features/desktop-automation.md` | macOS GUI: screencapture/osascript/cliclick | `tool:desktop.sh`, `topic:macos-windows` |
| `features/hooks-tui-limits.md` | Hook TUI display limitation (alt-screen buffer) | `topic:hooks`, `topic:terminal-display` |
| `features/dev-servers.md` | pm2 + port 30xx/50xx + persistence | `tool:pm2`, `topic:dev-servers` |
| `features/claudew.md` | Plugin-based claude CLI wrapper | `tool:claudew`, `topic:rate-limit-recovery` |
| `features/shell-memory.md` | shell-mem shell history + BG processes (renamed from diy-mem in mig 0014) | `tool:shell-mem`, `topic:shell-history` |
| `features/fiber-snatcher.md` | React/Next.js dev-app debugging daemon | `tool:fiber-snatcher`, `topic:react-debugging` |

### `conventions/` — output/authoring standards

| File | Brief | Primary triggers |
|------|-------|------------------|
| `conventions/doc-naming.md` | YYYYMMDD- prefix, session tags, living-doc rules | `topic:doc-naming`, `phrase:"session tag"` |
| `conventions/asset-management.md` | assets/<type>/ + asset.sh + CWD double-nest | `tool:asset.sh`, `topic:assets` |
| `conventions/cli-help-design.md` | --help structure, colors, columns, no-pager | `topic:cli-help`, `phrase:"--help"` |
| `conventions/html-output.md` | HTML rules: dark/light toggle MANDATORY + future HTML rules | `topic:html-output`, `topic:reports` |
| `conventions/ascii-diagrams.md` | Proactive box-drawing diagrams; /diagram for complex | `skill:diagram`, `topic:diagrams` |
| `conventions/doc-writing.md` | Technical doc guidelines + anti-patterns (migrated from root) | `skill:write-docs`, `topic:docs-work` |
| `conventions/scratch-files.md` | `_*.claude.md` hygiene + monthly archive to assets/checkpoints | `topic:scratch-files`, `topic:checkpoints` |

---

## Skill System

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/skills/GUIDELINES.md` | Mandatory rules for all skills (safety, tools, verbosity, locks, formatting) | Running or writing any skill |
| `~/.claude/skills/runtime-notes.md` | Per-project session history and learnings | Starting a skill run, checking past insights |
| `~/.claude/skills/README.md` | Skill authoring conventions and directory layout | Creating or modifying a skill |

## Custom Skills (`~/.claude/skills/`)

| Skill | Invocation | Brief | Use when... |
|-------|-----------|-------|-------------|
| `designer-reviewer/SKILL.md` | `/designer-reviewer [screenshot-path]` | Reviews UI screenshots against terminal-dashboard aesthetic fingerprints (FP-1–FP-6). Scores 5 dimensions, generates findings + CSS fixes. Calibrated for pm2-manage, visualize-claude, and developer tool UIs | Reviewing any dark-mode dashboard or tool UI for visual consistency against the established design system |
| `doctor/SKILL.md` | `/doctor` | On-demand environment health check — worktrees, pm2 status, disk, WAL staleness, git dirty count, event log health, hook integrity, MCP config validity. Wraps `scripts/health-check.sh` | Running a quick env audit mid-session, or after seeing unexpected hook behavior |
| `autocorrect/SKILL.md` | `/autocorrect [subcommand]` | Manage typo correction dictionaries: list, add, teach, ignore, log, undo, test, stats. Data in `assets/autocorrect/`, log at `.autocorrect-log.jsonl` | Managing autocorrect dictionaries, reviewing correction history, teaching new mappings |
| `mini/SKILL.md` | `/mini <prompt>` | Fast mini-model query (<1s) using local Ollama or cloud Haiku. Templates: session-title, doc-lookup, cmd-compose, summarize. All surfaces share `llm-mini-core.sh`. CLI: `llm-mini`. Engine: `llm-mini engine [start\|stop\|status]` | Quick lookups, session titles, command composition, short summaries |
| `past-sessions/SKILL.md` | `/past-sessions` | Browse, search, summarize past Claude Code transcripts in `~/.claude/projects/`. TSV output via `scripts/list-sessions.sh` | Recalling past conversation content ("what did we do last X") without grepping transcripts manually |

## Shared References (`~/.claude/skills/shared/`)

| File | Brief | Read when... |
|------|-------|-------------|
| `shared/doc-naming.md` | Datestamp + session ID naming/tagging rules for all files | Creating any new file or document |
| `shared/safe-delete.md` | `trash` not `rm`; recovery procedures; hook details | Deleting files, or when `rm` is blocked by hook |
| `shared/asset-management.md` | Asset registry: register, find, expire, cleanup via `asset.sh` | Creating screenshots, reports, PDFs, or any non-source file |
| `shared/wal-format.md` | WAL session header, action log, and checkpoint format | Writing WAL entries or parsing WAL for `/catchup` |
| `shared/gum-guide.md` | Interactive TUI patterns with `gum` (choose, filter, spin) | Building skill UIs with terminal prompts |
| `assets/docs/gum-rendering-examples.md` | Visual output gallery: tables, boxes, architecture diagrams, flowcharts, dashboards, color reference — all TTY-safe | Writing `gum_table`/`gum style`/`gum join` output; styling terminal results; composing diagram layouts |
| `shared/desktop-automation.md` | macOS GUI automation v1: screencapture, osascript, cliclick patterns, usage examples, Phase 2 upgrade spec | Any desktop automation task — screenshots, clicks, window management, Space switching |
| `shared/bash-gotchas.md` | Bash pitfalls: `cat\|jq` pipe hangs, `\|\|`/`&&`/`\|` precedence, when to use Read vs Bash | Before writing any multi-step shell pipeline or file inspection command |
| `shared/lock-file.sh` | File lock acquire/release/check for parallel agent safety | Before any write to shared files (runtime-notes, SKILL.md) |
| `shared/check-path.sh` | Validates path is not in forbidden list | Before any write operation |
| `shared/log-run.sh` | Timestamped entry to `shared/run.log` | At skill start and end |
| `shared/prepend-runtime-note.sh` | Atomic prepend to runtime-notes with lock handling | At end of every skill run |

## Dev Server & Port Scripts (`~/.claude/scripts/`)

| File | Brief | Read when... |
|------|-------|-------------|
| `scripts/desktop.sh` | macOS desktop automation helper: screenshot, windows, click, type, key, space, focus subcommands | Running desktop automation tasks without constructing raw screencapture/osascript/cliclick commands |
| `scripts/dev-servers/pm2-register.sh` | Register/deregister pm2 apps, auto-assign 30xx/50xx ports, output ecosystem.config.cjs snippets. Commands: `register`, `deregister`, `change`, `list` | Setting up a new server or pair app, or reassigning ports |
| `scripts/dev-servers/gen-nginx-conf.sh` | Generate nginx `.test` server blocks from port registry. Handles Host header rewrite for Vite/Next.js. `--dry-run` to preview | Activating `<name>.test` domains for registered apps |
| `~/.claude/dev-servers-guide.md` | Full pm2 + nginx + port workflow guide including persistence (startup+save), registration script usage, and troubleshooting | Any dev server setup, port allocation, or pm2 persistence questions |

## Personal CLIs (`zcmd` registry)

Personal command-line tools live in the `zcmd` registry (`~/Code/Claude/its-my-config/shell/zcmd/`, symlinked into `~/.local/bin/`). Discover with `zcmd list` / `zcmd kit`; manage with `zcmd add|rm|edit` (it refuses names that shadow a system binary).

| Command | Brief | Use when... |
|---------|-------|-------------|
| `zconvert` | Convert tabular data between csv/tsv/xlsx/json, any direction; refuses structurally-broken output, preserves long IDs; `zconvert --capabilities`/`-h` for support | Changing a data file's format — prefer over a throwaway pandas/csv/openpyxl script |
| `zap` | Hunt + kill a specific process surgically (fzf picker, signal/scope menu, tree view, htop-style `^K`/`^X`) | Killing the right process by port/name/args without nuking everything |
| `memhog` | Rank processes by a memory type (macOS), zero deps | "what's eating my RAM" |

## Hook Scripts (`~/.claude/scripts/`)

| File | Hook type | Brief | Read when... |
|------|-----------|-------|-------------|
| `scripts/safe-delete.sh` | PreToolUse (Bash) | Blocks `rm`, suggests `trash` with yellow warning | Debugging blocked `rm` commands |
| `scripts/block-nested-claude.sh` | PreToolUse (Write\|Edit\|MultiEdit\|NotebookEdit\|Bash) | Blocks any tool call whose path contains `/.claude/.claude/` — prevents the relative-path double-nest bug when CWD is `~/.claude` | Debugging a blocked nested-path rejection; writing skills that default to `.claude/output/...` |
| `scripts/emit-event.sh` | Multiple hooks (SessionStart, Stop, UserPromptSubmit, PostToolUse, PreCompact, PostCompact) | Appends one JSONL line per hook firing to `~/.claude/events.jsonl`; flock-guarded, async, fails soft | Debugging event log gaps; querying `events.jsonl` for cross-project activity |
| `scripts/find-events-log.sh` | Utility | Resolves path to the global `events.jsonl` so skills don't hardcode | Writing a skill that reads the event log |
| `assets/asset.sh` | CLI tool | Register, find, expire, cleanup managed assets | Creating or finding non-source files |
| `assets/MANIFEST.md` | Registry | Tracks all managed assets with metadata | Browsing or auditing registered assets |
| `scripts/auto-format.sh` | PostToolUse (Edit\|Write) | Runs Prettier on modified files | Debugging auto-format behavior |
| `scripts/session-mgmt/pre-compact-checkpoint.sh` | PreCompact (auto) | Saves checkpoint before auto-compaction | Debugging lost context after compaction |
| `scripts/notification-context.sh` | Notification | Sends macOS notifications on idle/elicitation | Debugging notification delivery |
| `scripts/permission-notify.sh` | PermissionRequest | Notifies user of pending permission requests | Debugging permission flow |
| `scripts/statusline/statusline.sh` | statusLine | Renders the status bar content | Modifying status line display |
| `statusline.conf` | Config | Segment profiles (default/minimal/full/debug) | Toggling statusline segments on/off/auto |
| `scripts/process-stats-daemon.sh` | Background | Writes Claude CPU/MEM to tmp file every 3s | Debugging process stats display |
| `assets/static/statusline-features.md` | Reference | 30 statusline features with implementation status | Adding statusline widgets or evaluating external tools |
| `scripts/update-tab-title.sh` | Stop | Updates terminal tab title after session | Debugging tab title behavior |
| `scripts/session-mgmt/session-summary.sh` | Stop | Generates session summary on exit | Debugging session-end behavior |
| `scripts/cost-alert.sh` | Stop | Cost velocity alerts with ring buffer | Debugging cost tracking |
| `scripts/diff-preview.sh` | PostToolUse (Edit\|Write) | Shows inline diff preview after edits | Debugging diff display |
| `scripts/tool-counter.sh` | PostToolUse | Counts tool calls per session | Debugging tool usage stats |
| `scripts/session-mgmt/turn-counter.sh` | UserPromptSubmit | Counts user turns per session | Debugging turn tracking |
| `scripts/session-mgmt/turn-start.sh` | UserPromptSubmit | Writes atomic `~/.claude/.turn-state/<sid>.json` + WAL `turn_start` entry before Claude processes the prompt. Pairs with `turn-end-cleanup.sh` and `detect-stale-session.sh` to detect mid-turn crashes | Debugging stale turn-state files; adjusting turn-counter behavior |
| `scripts/session-mgmt/turn-end-cleanup.sh` | Stop | Clears `<sid>.json` and `heartbeat-<sid>` counter from `.turn-state/` on graceful exit so they aren't flagged as a crash | Debugging `detect-stale-session.sh` false positives (if Stop hook didn't fire) |
| `scripts/session-mgmt/detect-stale-session.sh` | SessionStart (NOT async) | Scans `~/.claude/.turn-state/` for orphan turn files (<48h) and `~/.claude/wal.jsonl` for dangling `session_start` without matching `session_end` (<24h); emits `additionalContext` prompting `/catchup` if either signal fires | Debugging why a session did/didn't see the catchup prompt on startup |
| `scripts/session-mgmt/heartbeat.sh` | PostToolUse (catchall) | Increments `heartbeat-<sid>` counter; every Nth call (default 10, `CLAUDE_HEARTBEAT_INTERVAL` overrides) writes a WAL `heartbeat` action. Gives /catchup a tight bound on last-known-good state in long sessions | Tuning heartbeat frequency; debugging missing heartbeats in WAL |
| `scripts/wal/bash-wal.sh` | PreToolUse + PostToolUse (matcher=Bash) | Writes `bash_intent` (Pre) and `bash_closed` (Post) WAL actions with cmd preview, `uid=<short>`, and `status=ok\|error\|interrupted`. Lets /catchup see which shell command was in flight if a session crashed mid-Bash | Reconstructing crashed session's last shell command; tuning cmd preview length |
| `scripts/claude-resilient.sh` | **DEPRECATED** — do not use | Exit-code-gated retry wrapper that works for neither case: interactive never exits non-zero on a transient 429 (so retry can't fire); headless `-p` retry is bare `claude --continue` which drops the prompt. Verified 2026-06-18 (`assets/reports/20260618-api-error-48h-analysis`). | Nothing — kept as a record. Interactive recovery → `scripts/hooks/api-recovery-nudge.sh`; fleet recovery → `scripts/fleet-triage.py`. Do NOT alias `claude` to it. |
| `scripts/session-mgmt/post-compact-recovery.sh` | PostCompact | Restores critical context after compaction | Debugging post-compact state |
| `scripts/shell-mem/` (was `diy-mem/`) + dispatcher `scripts/shell-mem.sh` | Multiple hooks | Shell memory system (init, track, inject, mark-done) — invoke via `shell-mem.sh <subcommand>` | Debugging shell history tracking |
| `scripts/rotation/rotate-events.sh` | Stop (async) | Archives `events.jsonl` when it exceeds 50MB (gzip → `assets/backups/events-archive/`); fails soft | Debugging event log rotation; adjusting threshold via `EVENTS_ROTATE_THRESHOLD` |
| `scripts/rotation/rotate-wal.sh` | Stop (async) | Archives `wal.jsonl` (both global `~/.claude/wal.jsonl` AND project-local `$CWD/.claude/wal.jsonl`) when it exceeds 5MB. Label in archive name distinguishes `global` vs project | Adjusting threshold via `WAL_ROTATE_THRESHOLD`; debugging missing WAL after rotation |
| `scripts/rotation/prune-backups.sh` | CLI / weekly | Trashes items in `~/.claude/assets/backups/` older than 180 days (override via `BACKUP_RETENTION_DAYS`). `--preview` / `--apply`; uses `trash` for recoverable deletion | Reclaiming disk; checking what's about to expire |
| `scripts/schedule/schedule.sh` | CLI tool (`std::claude::schedule`) | gcc-schedule v0.5: `add` (one-shot via `--at`, recurring via `--daily-at` / `--weekly <dow>`) / `list [--all]` / `inventory` / `doctor [--check-calendar]` / `show` / `run` / `logs` / `enable` (alias `resume`) / `disable` (alias `pause`) / `duplicate` / `register` / `rm`. Always prints a `PLANNED:` block before mutating; `--dry-run` exits after that block. `--cron` is intentionally rejected — focused flags only. Supports `--env KEY=VAL` (repeatable), `--working-dir <path>`. Per-name dir at `~/.claude/scheduled/<name>/`. Registry at `~/.claude/scheduled/registry.json`. Aliased to `gcc-schedule` in `~/.zshrc` | Scheduling any launchd job (Ghostty wake, daily digest, weekly review, deferred command); adopting an existing manually-built plist; auditing what's loaded via `inventory`; checking drift via `doctor` |
| `scripts/schedule/INSTRUCTIONS.md` | Doc (`std::claude::schedule`) | Claude-facing usage contract for gcc-schedule. Covers the three scheduling modes (one-shot, daily, weekly), the PLANNED-block self-check discipline, why `--cron` is absent, common patterns, what NOT to do, and when to halt + ask the human. Linked from `help` and from this row. | Before invoking `gcc-schedule add` for the first time in a session; deciding which scheduling mode fits an ambiguous request |
| `scripts/validate-memory.sh` | CLI / CI | Scans `~/.claude/projects/*/memory/*.md` for file-path references and flags ones that no longer exist. Placeholder patterns (`/path/to/`, `<foo>`, `YYYY`) are filtered out. Exit code 1 on stale refs | Auditing memory system for rot; wiring into CI or a /doctor deep-check |
| `scripts/test-hooks.sh` | CLI / CI | 16 tests covering block-nested-claude, safe-delete, emit-event (duration/error flags), rotate-events, rotate-wal, validate-memory. Uses `HOME`-override for isolation. `--filter <substr>` narrows scope. Exit 1 on any failure | Verifying hook behavior before registering new entries; regression-testing after edits to hook scripts |
| `scripts/wal/wal.sh` | CLI helper | Appends JSONL lines to `.claude/wal.jsonl` (or `~/.claude/wal.jsonl`). Wraps `jq -cn` for safe escaping. Kinds: session_start/action/decision/agent_start/agent_done/checkpoint/session_end | Writing WAL entries safely — never hand-compose JSONL |
| `scripts/wal/wal-convert.sh` | CLI one-shot | Converts legacy `wal.md` → `wal.jsonl` via python3 state machine. Tolerant of real-world format variance (id-date headers, `**Goal:**`, bullet actions). `--dry-run`, `--output <path>` | Migrating an old markdown WAL to the JSONL format |
| `scripts/hint-injector.sh` | UserPromptSubmit | Runs all hinters from `~/.claude/hinters/` in sort order, aggregates hints into single additionalContext injection | Debugging hint pipeline, adding new hinters |
| `hinters/00-autocorrect.sh` | Hinter (via hint-injector) | Layer 0/1 typo correction: custom-terms whitelist + known-typo map. Logs to `.autocorrect-log.jsonl`. ~34ms | Debugging autocorrect behavior, false positives |
| `assets/autocorrect/` | Data files | `custom-terms.txt` (118 terms), `typo-map.txt` (213 mappings), `blacklist.txt` (3 entries) | Managing autocorrect dictionaries; also via `/autocorrect` skill |
| `scripts/llm-mini/llm-mini-core.sh` | CLI + backend | Single-source mini-model dispatcher: Ollama local + Haiku cloud, prompt templates, cold-start engine, fallback cascade, usage logging | Building any surface that needs fast mini-model queries |
| `scripts/llm-mini/llm-mini.sh` | CLI wrapper | Thin `exec` wrapper around `llm-mini-core.sh`, symlinked to `~/.local/bin/llm-mini` | Using llm-mini from the shell: `llm-mini "question"` or `echo text \| llm-mini summarize` |
| `scripts/llm-mini/llm-mini-engine.sh` | Engine manager | Ollama lifecycle: start/stop/status/switch/stats/models + cold-start ensure + idle watchdog | Managing Ollama runtime, model switching, auto-start/stop |
| `scripts/llm-mini/llm-mini-mcp-server.js` | MCP server | Node.js stdio MCP server exposing `ask` + `list_templates` tools; registered in `.mcp.json` as `llm-mini` | Claude calling mini-model directly via MCP without shell hop |
| `scripts/llm-mini/llm-mini-hook.sh` | Hook callable | Sourceable `mini_quick()` for hooks; enforces 3s timeout, prefers local backend | Using mini inside hook scripts (session titles, summaries) |
| `llm-mini.conf` | Config | Persistent settings: backend, model, timeouts, auto-start, idle shutdown | Customizing llm-mini behavior |
| `assets/mini-prompts/` | Templates | 4 prompt templates: `session-title`, `doc-lookup`, `cmd-compose`, `summarize` — `{{input}}` placeholder | Adding or modifying mini-model prompt templates |

## Blueprint & Design Surfaces (`~/.claude/code/`)

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/code/README.md` | `std::claude::code` cluster: reference material for things to build (roadmaps, design sketches, templates) vs. `::scripts` (runtime) vs. `::improvement` (backlog) | Navigating design docs; deciding where a new proposal / roadmap / template belongs |
| `~/.claude/code/ideas/` | `std::claude::code::ideas` — design sketches and roadmaps you intend to build (vs. `::improvement::ideas` which is ungraduated backlog) | Starting a concrete design doc for a new feature |
| `~/.claude/code/templates/` | `std::claude::code::templates` — reusable file skeletons (SKILL.md, script, migration doc templates) | Scaffolding a new skill / script / migration from a template |
| `~/.claude/code/templates/spinner-demo.ts` | Drop-in pulsing terminal spinner — braille + pulse-dot styles, time-based animation, exports `startSpinner({style, label})`. Run `bun spinner-demo.ts` to preview. [notion-sync@2026-04-30] | Adding a CLI loading indicator that pulses like Claude Code or npm |
| `~/.claude/code/terminal-tooling-notion-sync.md` | Reusable CLI tooling patterns from notion-sync: gum wizards, env validation, progress bar+ETA, osascript notifications, defaults file, adaptive rate limit, retry passes, content-addressed cache, crash-safe partial save, run-logs JSONL. Each section has code snippets + commit references. [notion-sync@2026-05-01] | Building any Bash+bun/node CLI that needs polished interactive UX |

## Scratchpad & Working Memory

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/scratchpad/README.md` | Scratchpad system docs (local + global tiers, scripts) | Using scratchpad for plans or learnings |
| `~/.claude/scratchpad/global/` | Cross-project patterns and reusable references | Looking for patterns from other projects |
| `~/.claude/scratchpad/global/port-registry.md` | pm2 port assignments (frontend=30xx, backend=50xx) | Starting a dev server or registering ports |

## Persistent Memory

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/projects/.../memory/MEMORY.md` | Per-project memory index (auto-memory system) | Recalling user preferences, past decisions |
| `~/.claude/weekly-todos.md` | Weekly task list reviewed Mon/Wed/Sat | Planning work, checking pending items, weekly review |
| `~/.claude/scripts/weekly-todo.sh` | CLI for weekly todos: `add`, `done`, `rm`, `list`, `ensure`, `archive` | Managing weekly todos from shell or agent scripts |
| `~/.claude/.mcp.json` | **Active global MCP servers** — dot-prefixed, this is what Claude Code reads | Adding/removing global MCP servers. ⚠ Never create `mcp.json` (no dot) — it is silently ignored |
| `~/.claude/mcp-catalog.json` | Pre-configured MCP server definitions for `/add-mcp` | Adding MCP servers to a project — NOT the active server list |
| `shared/mcp-config.md` | Full MCP file reference, gotcha notes, server inventory | Any MCP config work — read this before touching MCP files |
| `~/.claude/disabled-plugins.json` | Registry of disabled plugins with reasons | Re-enabling plugins for specific projects |

## Agents & Personas

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/agents/quick-query-resolver.md` | Custom agent for fast, focused answers | Handling quick technical questions |
| `~/.claude/personas/` | Role presets (data-engineer, fullstack, researcher) | Switching Claude's expertise profile |

## Operational Files

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/improvement-ideas.md` | Cross-project insights from sessions | Looking for reusable patterns learned from past work |
| `~/.claude/sync-config.sh` | Syncs config across machines | Setting up a new machine or resolving config drift |

## Upgrade Reports & Backups

| Path | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/assets/reports/20260621-large-review-strategy/REPORT.md` | **Large Review Strategy** — reusable calibrated playbook for reviewing a big / distributed change (large PR, restructure, bulk sweep, many files): review by transformation-TYPE not file order, trust green CI, stakes-order, cheap agent pre-flag greps. Backed by a 6-discipline MAGI panel (code / peer-review / wiki / editorial / large-diff + jester) in `magi-panel/`. Auto-surfaced by hinter `20-large-review-strategy.sh`. | Designing how to review any large or distributed contribution; "how much effort does this review deserve"; "the diff is enormous, where do I look" |
| `~/.claude/assets/reports/20260417-0144-phase12-complete/index.html` | Phase 1+2 upgrade final report (minimal style). Covers async-flip audit, global event log, /doctor + /past-sessions skills, WAL JSONL migration, backup + revert paths | Reviewing what Phase 1+2 changed; deciding what to revert; grepping for "why did we touch X" |
| `~/.claude/assets/reports/20260417-phase12-complete.md` | Source markdown for the above report (reusable with `/create-report --style <other>` via `data.json`) | Restyling the upgrade report, citing sections in other docs |
| `~/.claude/assets/backups/20260417-phase12-upgrade/` | Pristine settings.json backup + 130-line RESTORE.md with symptom→cause table for Phase 1+2 reverts | Reverting a specific Phase 1+2 change, or diagnosing hook misbehavior introduced after 2026-04-17 |
| `~/.claude/events.jsonl` | Global, append-only event timeline (JSONL). One line per hook firing: `ts`, `event`, `session_id`, `cwd`, `project`, `prompt_preview`, plus `duration_ms`/`error` on PostToolUse and `cost_delta_usd` on Stop when available | Querying cross-project activity: "when did I last run /commit", busiest projects, events-per-hour, slow-tool outliers |
| `~/.claude/proposals.jsonl` | **Cross-session improvement backlog.** Append-only JSONL filed by any session that notices a reusable improvement. Surfaced via `propose.sh list` when the user asks "what else can be improved?" | Filing an improvement mid-task, or responding to meta-questions about `~/.claude/` upgrades |
| `~/.claude/scripts/propose.sh` | CLI for the backlog: `add` / `list` / `show` / `done` / `reject`. flock-guarded, jq-safe escaping | Filing or triaging proposals |

## Widgets (`~/.claude/widgets/`)

| File | Brief | Read when... |
|------|-------|-------------|
| `~/.claude/widgets/claude-instances/` | Native macOS menu bar widget (Swift/AppKit) for monitoring live Claude Code sessions, rate limits, history, events. NSMenu dropdown + NSPanel dashboard | Debugging the widget, adding new dropdown sections, understanding session data flow |
| `~/.claude/widgets/claude-instances/native/build.sh` | Compile, ad-hoc sign, relaunch, install LaunchAgent | Rebuilding the widget after source changes |
| `~/.claude/widgets/claude-instances/native/color-sampler.swift` | One-off color sampler: SwiftUI window with `NSVisualEffectView(.menu)` vibrancy material, toggleable color swatches per group, auto-saves picks to `/tmp/color-sampler-result.json`. Compile: `swiftc -O -framework SwiftUI color-sampler.swift -o /tmp/color-sampler`, launch: `open /tmp/color-sampler` | Selecting colors that look good on macOS translucent/vibrancy backgrounds (NSMenu, NSPopover). Reusable for any future color contrast work on macOS |
| `~/.claude/widgets/claude-instances/lib/scan.sh` | JSON scanner: live instances, history, events, rate limits, aggregates | Understanding widget data sources |

## External References

| File | Brief | Read when... |
|------|-------|-------------|
| `~/Code/Claude/visualize-claude/templates/_agent-infra/` | pm2 + dev server templates (PORT-POLICY, PM2-FRAMEWORK, LOCAL-DOMAINS, ecosystem templates) | Setting up new agent app infrastructure |
| `~/Code/Claude/pm2-manage/` | Browser dashboard for all pm2 processes (port 5042). REST API + SSE. Config: `pm2-manage-config.json` | Managing pm2 processes, extending the dashboard, understanding process state |
| `~/Code/Claude/pm2-manage/DESIGN-DAEMON-EXTENSION.md` | Feature design: extending pm2-manage to show daemons, cron jobs, and launchd agents | Building the daemon/cron dashboard feature |

---

## Maintaining this index

- **Adding a new file**: Add a row to the appropriate table above. Include a 1-sentence brief and a trigger condition.
- **Removing a file**: Delete the row. Check CLAUDE.md and GUIDELINES.md for stale references.
- **Moving a file**: Update the path here, in CLAUDE.md, and in GUIDELINES.md.
- **Rule**: Every dedicated config file must appear in this index. If it's not here, agents won't find it.

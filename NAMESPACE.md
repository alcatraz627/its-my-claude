# std::claude Namespace Tree

<!-- sessions: impr-cfg-7a@2026-04-24, ns-plan-7f@2026-04-14, upgrade-phase12-7c@2026-04-17 -->

> **Conceptual map** for all Claude features and add-ons under `~/.claude/`.
> `std::claude::*` is a **naming convention** — C++-flavored labels to organize how
> the user and Claude refer to features. It is NOT an import system, package manager,
> or runtime linkage. Labels are aliases; the real artifacts live at the paths below.

---

## NAMESPACE vs LOOKUP — know the difference

| File | Purpose | Read when... |
|---|---|---|
| `NAMESPACE.md` (this file) | **Conceptual clusters** — what each `std::claude::*` label covers, why it exists, and what belongs in it | You need to *understand* how Claude's config is organized, or decide where a new thing should live |
| `LOOKUP.md` | **Tactical address book** — file-level triggers: "read X when you need Y" | You need to *find* a specific rule, hook, or script at a known path |

Namespace answers *"what category does this belong to?"*. Lookup answers *"which file do I open right now?"*. They overlap but do not duplicate — changes here rarely touch LOOKUP, and vice versa.

---

## Design principles

1. **Labels not imports.** `std::claude::shared` is a *name we say aloud*. It does not affect Python imports, Bash sourcing, or any runtime path.
2. **Siblings under one prefix.** Every cluster sits at the same depth: `std::claude::<cluster>`. No cluster is privileged; `shared` is one sibling among many.
3. **Labels can be distributed across paths.** A cluster's artifacts need not live in one directory. When a label meaningfully spans multiple locations, mark it `[facet]`.
4. **Separate reference from action.** `::code` holds ideas/templates you *read*; `::scripts` holds things you *run*. Never mix.
5. **One surface per cluster.** Each cluster picks one of four surfaces — Reference, Executable, Behavior, or State — and sticks to it. Multi-surface clusters get split.
6. **Global-first state.** Memory, scratchpad, and assets default to global locations with project-specific sub-directories inside, not the other way around. Easy for any agent to find project-specific entries without knowing the project slug.
7. **Migrations are first-class.** Any rename, move, or restructure is logged under `::migrations`. Stale references are expected; the recovery path is documented, not hidden.
8. **Prefer relabelling over moving.** When an existing file fits a new namespace, give it the label first; only move the file if the physical location is actively confusing.

---

## The tree

```
std::claude
├── ::shared              Python + Bash utility library         → ~/.claude/skills/shared/
├── ::code                Reference material (read-only)        → ~/.claude/code/           (new — Phase 1)
│   ├── ::code::ideas         code-pattern seeds, snippets
│   └── ::code::templates     scaffolds, boilerplate
├── ::rules               Behavioral/process rules              → ~/.claude/rules/          (new — impr-cfg-7a)
├── ::features            Subsystem/tool/integration docs       → ~/.claude/features/       (new — impr-cfg-7a)
├── ::conventions         Output/authoring standards            → ~/.claude/conventions/    (new — impr-cfg-7a)
├── ::placement           Placement rule (category × tier)      → ~/.claude/PLACEMENT.md    (new — impr-cfg-7a)
├── ::scripts             Operational executables                → ~/.claude/scripts/
├── ::skills              Custom SKILL.md definitions            → ~/.claude/skills/
├── ::personas            Sub-agent personas (working-mode + dispatch) → ~/.claude/personas/
├── ::plugins             Marketplace plugins                    → settings.json enabledPlugins
├── ::mcp          [facet]    MCP server config + catalog        → .mcp.json, mcp-catalog.json, shared/mcp-config.md
├── ::tui          [facet]    Styled output + rich input         → gum-tui.sh + inputs MCP + AskUserQuestion
├── ::vision       [facet]    Screen perception + desktop automation → scripts/desktop.sh + annotate-screenshot.py + local-models `see` (VLM read) + assets/images/ + shared/desktop-automation.md
├── ::network             Internet + local network helpers       → ~/.claude/scripts/ (gen-nginx-conf.sh + future)
├── ::widgets      [facet]    macOS widgets + mini-apps          → ~/.claude/widgets/ + subconscious/dashboard.html
├── ::assets              Non-source file registry               → ~/.claude/assets/
├── ::memory              Persistent auto-memory                 → ~/.claude/memory/
├── ::scratchpad          Working-memory plans/learnings         → ~/.claude/scratchpad/
├── ::startup             Login-time maintenance orchestrator    → ~/.claude/scripts/startup/ + ~/Library/LaunchAgents/dev.claude-startup.plist
├── ::checkpoints         Session-keyed checkpoint index         → ~/.claude/checkpoints/ + scripts/checkpoint/ + /core-dump + /catchup
├── ::magi                Multi-agent supervisor + voting        → ~/.claude/skills/magi/ + scripts/magi/ + assets/magi/<task>/
├── ::todos        [facet]    Weekly / monthly task lists        → weekly-todos.md + scripts/weekly-todo.sh + assets/docs/YYYYMMDD-todo-*.md
├── ::backups      [facet]    Revert & recovery artifacts        → assets/backups/ + ~/.claude/backups/ + bak_*
├── ::improvement  [facet]    Self-correction & learning         → distributed; see sub-labels
│   ├── ::improvement::ideas        system improvement backlog
│   ├── ::improvement::mistakes     mistake-pattern catalog
│   ├── ::improvement::proposals    cross-session proposal JSONL
│   ├── ::improvement::insights     post-skill runtime notes
│   └── ::improvement::dreams       subconscious daemon outputs
└── ::migrations          Structural change log                  → ~/.claude/migrations/
```

Seven facets: `::mcp`, `::tui`, `::vision`, `::widgets`, `::todos`, `::backups`, `::improvement`. A facet's artifacts are deliberately distributed; do not create a single directory to "consolidate" them.

---

## Namespace definitions

### `std::claude::shared` — Utility library

**Surface:** Reference + Executable (dual — Python API + Bash scripts)
**Path:** `~/.claude/skills/shared/`
**Version:** 0.1.0 (Phase 1 bumps to 0.2.0 when label rename lands)

Python helpers (`Banner`, `Section`, `Item`, `tree`, `kv_line`, `THEMES`) and Bash utilities (`lock-file.sh`, `prepend-runtime-note.sh`, `check-path.sh`, `log-run.sh`, `gum-tui.sh`).

**In scope:** cross-skill helpers, `gum_*` TUI wrappers, lock protocols, banner/formatting primitives, shared reference docs (`bash-gotchas.md`, `doc-naming.md`, `safe-delete.md`).
**Out of scope:** skill-specific logic, operational scripts that are not re-used (belongs in `::scripts`).

**Historical:** originally labelled plain `std::claude` as a single-label library. Migration 0001 renames to `std::claude::shared`.

---

### `std::claude::code` — Reference material

**Surface:** Reference (read-only)
**Path:** `~/.claude/code/` (created in Phase 1)

Material Claude *reads for ideas*, never runs.

- `::code::ideas` — code-pattern seeds: "when writing an X, consider Y". Different from `::improvement::ideas` (which is about improving Claude's config, not improving code you write).
- `::code::templates` — scaffolds and boilerplate to copy-and-modify.

**In scope:** code-generation inspiration.
**Out of scope:** executable scripts (`::scripts`), Claude-system improvement ideas (`::improvement::ideas`).

---

### `std::claude::rules` — Behavioral/process rules

**Surface:** Reference (instructions Claude follows)
**Path:** `~/.claude/rules/` (created 2026-04-24, impr-cfg-7a)

What Claude MUST do. Loaded on demand via CLAUDE.md Tier 1/2 pointers — or inlined in CLAUDE.md when Tier 0. Every file carries YAML frontmatter with `brief`, `triggers`, `tier`, `category`, `updated`, `stale_after_days`.

**In scope:** testing, git, shell, corrections, communication (terse/scope/state verification).
**Out of scope:** subsystem docs (`::features`), output standards (`::conventions`), always-on mandates that fit <3 lines inline (stay in CLAUDE.md).

---

### `std::claude::features` — Subsystem/tool/integration docs

**Surface:** Reference (how a thing works)
**Path:** `~/.claude/features/` (created 2026-04-24, impr-cfg-7a)

Documentation for every non-trivial subsystem, tool, integration, or feature — loaded when its trigger fires. Files include claudew, llm-mini, WAL, memory tiers, MCP catalog, desktop automation, and others.

**In scope:** mechanism docs, subsystem interface contracts, integration how-tos.
**Out of scope:** behavioral rules (`::rules`), artifact standards (`::conventions`), runtime execution (`::scripts`).

---

### `std::claude::conventions` — Output/authoring standards

**Surface:** Reference (how artifacts look)
**Path:** `~/.claude/conventions/` (created 2026-04-24, impr-cfg-7a)

Standards governing the form of things Claude produces: HTML outputs, CLI help text, ASCII diagrams, doc-naming, scratch-file hygiene, technical writing. Loaded when generating the relevant artifact type.

**In scope:** output form, naming, annotation conventions.
**Out of scope:** what to put inside the artifact (subject-matter is in `::features` or project-level context).

---

### `std::claude::placement` — Placement rule

**Surface:** Reference (the meta-rule)
**Path:** `~/.claude/PLACEMENT.md` (created 2026-04-24, impr-cfg-7a)

The two-axis rule (category × tier) for deciding where new config goes. Includes frontmatter spec, trigger taxonomy (`tool:`, `topic:`, `phrase:`, `skill:`, `mcp:`), and an anti-pattern list. Read before adding any file to `::rules`, `::features`, `::conventions`.

**In scope:** placement decision logic, frontmatter spec, anti-patterns.
**Out of scope:** the content itself (lives in the target cluster).

---

### `std::claude::scripts` — Operational executables

**Surface:** Executable
**Path:** `~/.claude/scripts/`

Hook scripts, statusline, pm2-register, shell-mem (formerly diy-mem; see mig 0014), session-summary, `emit-event.sh`, `block-nested-claude.sh`, `rotate-*`, `prune-backups.sh`, `propose.sh`, `wal.sh`, `wal-convert.sh`, `validate-memory.sh`, `test-hooks.sh`, hook-orchestrator (mig 0013), etc. — everything invoked by hooks or as a user-facing CLI.

Note: scheduling artifacts (`schedule/schedule.sh`, `schedule/INSTRUCTIONS.md`) are physically under `~/.claude/scripts/` but conceptually belong to `std::claude::schedule` — see that section.

**In scope:** any file expected to be invoked.
**Out of scope:** reference docs describing how scripts work (live in `::code` or inline READMEs).

---

### `std::claude::schedule` — Local scheduling cluster **[facet]**

**Surface:** Cross-cutting (executable + docs + rules)
**Paths:**
- `~/.claude/scripts/schedule/` — tool + Claude-facing instructions
- `~/.claude/rules/` (scheduling-discipline.md, cron-calendar-companion.md)
- `~/.claude/scheduled/` — registry + per-name state
- `~/Library/LaunchAgents/com.alcatraz.*.plist` — launchd entries (outside `~/.claude/` by necessity)
- Calendar.app "Automations" calendar — companion events

The "fire shell commands on a schedule on this Mac" cluster. Conceptually unifies what's otherwise scattered across `::scripts` (the gcc-schedule tool), `::rules` (the two discipline rules), launchd's plist directory, and Calendar.app.

Member artifacts:

| Artifact | Path | Role |
|---|---|---|
| `gcc-schedule` (the tool) | `scripts/schedule/schedule.sh` | CLI: add/list/inventory/show/run/logs/enable/disable/duplicate/register/doctor/rm |
| Claude-facing usage contract | `scripts/schedule/INSTRUCTIONS.md` | Read by Claude before invoking the tool — modes, PLANNED-block discipline, when to halt |
| Cross-tool scheduling discipline | `rules/scheduling-discipline.md` | Naming, retire-after-fire, no-secrets-in-command, when-to-use-which-scheduler |
| Mechanical companion rule | `rules/cron-calendar-companion.md` | Every cron gets a Calendar event for observability |
| Runtime state | `~/.claude/scheduled/registry.json` + per-name `<dir>/{script.sh,meta.json}` | Source of truth gcc-schedule manages |
| Audit lens | `gcc-schedule inventory` + `gcc-schedule doctor` | Read-only views; doctor catches drift |

**Promoted from `::scripts` on 2026-06-01** (gcc-schedule v0.5) after the cluster reached 4 distinct artifacts (tool + INSTRUCTIONS + 2 sibling rules). Earlier rationale lived as a TODO comment in `::scripts`; removed now that this section exists.

**In scope:** anything whose primary purpose is "schedule a local command", or any rule/doc primarily about that practice.
**Out of scope:**
- Remote Claude-prompt scheduling (`/schedule` skill, harness `CronCreate`) — belongs to `::skills` (the skill is the surface)
- Long-running daemons that happen to be loaded as LaunchAgents but don't fire on a schedule (claude-ipc, atone-consolidate uses `StartInterval` not `StartCalendarInterval`) — adopted into gcc-schedule's registry for visibility, but conceptually background services
- Calendar event use beyond cron companions (general Calendar.app integration) — there is none in this account today; would warrant its own cluster if it grew

---

### `std::claude::skills` — Custom skill definitions

**Surface:** Behavior (each SKILL.md instructs Claude how to act)
**Path:** `~/.claude/skills/`

Custom skills with a SKILL.md at the root. The `shared/` sub-directory is inside this path but belongs to `::shared` — physical overlap, not conceptual.

Notable recent additions: `/doctor` (env health check), `/past-sessions` (transcript browser) — both landed via Phase 1+2 upgrade (migration 0002).

**In scope:** anything with a SKILL.md.
**Out of scope:** helpers used by multiple skills (those move to `::shared`).

---

### `std::claude::plugins` — Marketplace plugins

**Surface:** Behavior (external)
**Location:** registered in `settings.json` `enabledPlugins`; disabled tracked in `disabled-plugins.json`.

**In scope:** upstream, updatable plugins.
**Out of scope:** local customizations (become a `::skills` entry).

---

### `std::claude::personas` — Sub-agent personas

**Surface:** Reference (each persona file is a prompt template, not executable)
**Path:** `~/.claude/personas/`

A persona is a Markdown file describing a role + scope + (when relevant) output structure. Two kinds coexist:

- **Working-mode personas** (`type: working-mode`, the original kind): the main agent *adopts* the persona for a task. Loaded into the agent's own context. Have L1/L2/L3 depth levels. Existing examples: `researcher.md`, `data-engineer.md`, `fullstack-engineer.md`.
- **Dispatch personas** (`type: dispatch`, added 2026-05-15): invoked by another script/skill via the `Agent` tool as a sub-agent. The main agent does NOT adopt them. Output is structured (typically JSON) for the dispatcher to parse. First example: `juror.md` (consumed by `/atone`).

**In scope:** prompt templates the agent can adopt or dispatch. One persona per file.
**Out of scope:** runtime code (use `::scripts`); skill definitions (use `::skills`); generic instructions that don't define a role (use `::rules` or `::conventions`).

**Authoring guide:** `~/.claude/personas/README.md`.

---

### `std::claude::mcp` — MCP servers **[facet]**

**Surface:** Behavior (external tool surface)
**Paths:** `~/.claude/.mcp.json` (active), `~/.claude/mcp-catalog.json` (presets), `shared/mcp-config.md` (reference).

Facet because MCP config spans three files: the active list, the catalog, and the reference. The `add-mcp` skill bridges them.

**In scope:** server definitions, catalog entries, injection workflow.
**Out of scope:** MCP tool *usage* (normal tool calling).

---

### `std::claude::tui` — Terminal UI surface **[facet]**

**Surface:** Behavior (input + output rendering)
**Paths:** `shared/gum-tui.sh` (output), `~/.claude/.mcp.json` `inputs` server (input), `AskUserQuestion` built-in, `/dev/tty` pattern in `bash-gotchas.md`.

The **elicit extension** — how Claude speaks to the terminal and solicits user input.
- Output: `gum_header`, `gum_table`, `gum_success`, etc.
- Rich input: `inputs` MCP (`confirm`, `pick_one`, `pick_many`, `form`, `wizard`).
- Fallback: `AskUserQuestion` for open-ended questions.
- Low-level: `/dev/tty` prompts from Bash when neither fits.

**In scope:** styled output and structured input.
**Out of scope:** general shell scripting (`::scripts`), unstyled echoing (normal shell behavior).

---

### `std::claude::vision` — Screen perception + desktop automation **[facet]**

**Surface:** Behavior (perception + manipulation of the macOS UI)
**Paths (facet):**

| Path | Role |
|---|---|
| `~/.claude/scripts/desktop.sh` | Primary CLI wrapper: `screenshot`, `click`, `type`, `key`, `windows`, `space`, `focus`, `check` |
| `~/.claude/scripts/annotate-screenshot.py` | Coordinate-grid overlay — lets Claude read exact pixel targets from screenshots instead of guessing |
| `~/.claude/assets/images/` | Screenshot storage (timestamped names, never `/tmp`) |
| `~/.claude/skills/shared/desktop-automation.md` | Reference: Phase 2 trigger, permission requirements, vision-loop pattern |
| `see` (local-models; on PATH at `~/.local/bin/see`, source `~/Code/local-models/bin/see`) | Local VLM read — image/screenshot to structured text, all on-box ("the VLM parses, the agent reasons"). `see img.png [question] [--json]`. Complements annotate: `see` reads image *content*; annotate+grid reads *coordinates*. |

The vision-loop pattern: screenshot → annotate → `Read` the annotated PNG → identify coordinates → act → screenshot again to verify. `cliclick` (brew), `screencapture`, and `osascript` are the underlying tools. To read image *content* (not coordinates), `see <img>` runs a local VLM (image → text) — the read half of the loop without a screenshot-annotate round-trip, useful for "what does this chart/UI say".

**Color on vibrancy surfaces:** Custom `NSColor(red:green:blue:)` values get composited through macOS vibrancy and appear muddy. Use system colors with `.shadow(withLevel:)` to darken while preserving vibrancy-awareness. The color sampler tool (`::widgets`) can preview candidates against real NSMenu material. NSMenu dropdowns cannot be captured by `screencapture` — they dismiss on any focus change.

**In scope:** anything that lets Claude *see* or *manipulate* the macOS desktop — screen capture, coordinate identification, mouse/keyboard injection, window/space management, color perception on vibrancy surfaces.
**Out of scope:** browser automation (Playwright MCP), terminal UI (`::tui`), rendering content into the conversation (normal assistant output).

**Why a facet:** scripts live under `::scripts` by physical home; screenshots under `::assets`; the reference under `::shared`. Distributed by necessity — each artifact fits its path's primary purpose, and the `::vision` label binds them conceptually.

**Mandatory preconditions:** ghostty must have Accessibility + Screen Recording permissions. Focus-stealing operations (`click`, `type`, `key`, `space`, `focus`) require user confirmation via `mcp__inputs__confirm` unless the user pre-authorized the sequence.

---

### `std::claude::network` — Internet + local network helpers

**Surface:** Executable
**Path:** `~/.claude/scripts/` (sub-cluster — not its own directory yet)

Scripts that touch the network — outbound HTTP/HTTPS, local service discovery, port management, config generators for networked services, process/port binding.

Current artifacts:
- `scripts/dev-servers/gen-nginx-conf.sh` — generates nginx configs for local dev services (ports 30xx frontend / 50xx backend per CLAUDE.md)
- `scripts/dev-servers/pm2-register.sh` — registers pm2 apps bound to local ports (process ↔ port wiring)

Planned (not yet implemented): HTTP fetch wrappers, local network scanning helpers, mDNS/Bonjour discovery.

**In scope:** scripts whose *primary purpose* is network I/O, port wiring, or configuring networked services.
**Out of scope:** MCP-provided network tools (`file-tools http_request`, `http_download` — those are `::mcp`), browser navigation (Playwright plugins), git remote operations (no dedicated label — part of normal `::scripts`), general process management (`pm2-resurrect.sh` stays `::scripts` — it's lifecycle, not port wiring).

**Status note:** two artifacts today — clears the "two-artifact threshold" now that `pm2-register.sh` is included. No longer provisional.

---

### `std::claude::widgets` — macOS widgets + mini-apps **[facet]**

**Surface:** Behavior (UI surfaces Claude manages on macOS)
**Paths (facet):**

| Path | Role |
|---|---|
| `~/.claude/subconscious/dashboard.html` | Dream insights dashboard (standalone HTML, viewable in browser) — likely the "dream dropdown" entry point |
| `~/.claude/widgets/claude-instances/` | Native macOS menu bar widget for monitoring Claude Code sessions (Swift, NSMenu dropdown, NSPanel dashboard) |
| `~/.claude/widgets/claude-instances/native/color-sampler.swift` | One-off color sampler tool: SwiftUI window with NSMenu vibrancy material (`.menu`), toggleable color swatches, auto-saves picks to `/tmp/color-sampler-result.json`. Reusable for future color selection tasks |

Widgets are small, self-contained UI surfaces that run *outside* the Claude conversation — browser tabs, menu-bar apps, status dropdowns, launchers. They let Claude-authored information live in a macOS-native way.

**In scope:** HTML/Swift/AppleScript widgets Claude builds and maintains; launcher scripts for them; config for where they run.
**Out of scope:** terminal styling (`::tui`), conversation-embedded diagrams (`::assets/diagrams/`), statusline widgets (those are a facet of `::scripts`, not UI widgets).

**Why a facet (for now):** `dashboard.html` currently lives under `::improvement::dreams` by physical path; the future `~/.claude/widgets/` directory will have its own home. Marking `[facet]` avoids premature movement of the existing dashboard.

**Active artifacts:** `claude-instances` menu bar widget (Swift/AppKit, runs via LaunchAgent), color sampler tool. The `~/.claude/widgets/` directory is now in use — the facet may collapse once no artifacts live outside it.

---

### `std::claude::assets` — Non-source file registry

**Surface:** State (files with metadata)
**Path:** `~/.claude/assets/`

Screenshots, reports, PDFs, diagrams, data exports. Managed by `asset.sh` with a MANIFEST.md registry. Includes `assets/reports/` (e.g., phase12 upgrade report) and `assets/diagrams/` (canonical diagram home).

**In scope:** any non-source artifact that is not a log and not temporary.
**Out of scope:** temp files (use `$TMPDIR`), backups (see `::backups`), source code, WAL/runtime-notes (state artifacts, not assets).

---

### `std::claude::memory` — Persistent auto-memory

**Surface:** State
**Two-tier architecture (Migration 0004):**

| Tier | Path | Loaded by | Scope |
|---|---|---|---|
| **Per-project** | `~/.claude/projects/<slug>/memory/` | Harness (automatic) | One CWD only |
| **Global** | `~/.claude/memory/global/` | CLAUDE.md instruction | All sessions |

The harness controls per-project paths (not user-configurable). The global tier overlays
cross-project memories — universal user preferences, coding feedback, and tool patterns.
When both tiers have a memory on the same topic, per-project takes precedence.

**Promote workflow:** copy a per-project memory to `memory/global/` when it proves universal.
Originals stay in place — per-project memory is never degraded.

**In scope:** user, feedback, project, reference memory types per the auto-memory spec in CLAUDE.md.
**Out of scope:** conversation state (`::scratchpad` for plans; WAL for raw log), code-committed decisions (the codebase), self-correction artifacts (`::improvement`).

**Seeded:** 14 universal feedback/user memories promoted from 7 projects (2026-04-17).
See `~/.claude/memory/global/MEMORY.md` for the full index.

---

### `std::claude::scratchpad` — Working memory

**Surface:** State (ephemeral plans + learnings)
**Paths:** `~/.claude/scratchpad/` with `global/` for cross-project, project-local `.claude/scratchpad/` elsewhere.

**In scope:** plans before executing, learnings after executing, promotable cross-project notes.
**Out of scope:** things that survive unchanged (graduate to `::memory`, `::code::ideas`, `::improvement::ideas`, or a real doc).

---

### `std::claude::todos` — Weekly / monthly task lists **[facet]**

**Surface:** State
**Paths (facet):**

| Path | Role |
|---|---|
| `~/.claude/weekly-todos.md` | Canonical source of truth — weekly sections with **To Build / To Review / Ideas to Explore** categories |
| `~/.claude/scripts/weekly-todo.sh` | CLI — `list`, `add`, `done`, `rm`, `weeks`, `ensure <date>`, `archive` |
| `~/.claude/assets/docs/YYYYMMDD-todo-*.md` | Historical archive of past weeks (e.g., `20260331-todo-2026-03-26.md`) |

Different from `::improvement::ideas`, `::code::ideas`, and `::improvement::proposals`:

| Label | Scope | Timeframe | Action cycle |
|---|---|---|---|
| `::todos` | **User-facing** intentions ("ship X this week") | Weekly/monthly | Recurrent — reviewed and replanned each week |
| `::improvement::ideas` | Claude-system config changes | Open-ended | Graduates to `::improvement::proposals` when ready |
| `::improvement::proposals` | Filed improvement items with lifecycle | Indefinite | `open` → `done`/`rejected` |
| `::code::ideas` | Code patterns for feature work | Per-project | Consulted during implementation |

**In scope:** the user's explicit weekly/monthly task intentions — what to build, what to review, what to explore.
**Out of scope:** session-scoped tasks (TaskCreate), per-skill runtime notes (`::improvement::insights`), memory entries (`::memory`).

**Why a facet:** canonical list at root (`weekly-todos.md`), CLI under `::scripts`, archives under `::assets`. Moving any one of them breaks the CLI workflow; labelling binds them.

**Governance:**
- Week sections are addressed by Monday date (`YYYY-MM-DD`)
- Completed items move to archive via `weekly-todo archive` before the week rolls over
- Items with a `build`/`review`/`explore` category map to markdown subsections

---

### `std::claude::backups` — Revert & recovery artifacts **[facet]**

**Surface:** State (files + retention policy)
**Paths (three surfaces):**
- `~/.claude/assets/backups/` — **deliberate named backup sets**: `YYYYMMDD-<label>/` dirs, each with `RESTORE.md`. Also holds `events-archive/` and `wal-archive/` from rotation scripts. Retention: `prune-backups.sh` trashes items older than 180 days (override via `BACKUP_RETENTION_DAYS`).
- `~/.claude/backups/` — **automatic `.claude.json` rolling snapshots** managed by the Claude Code CLI. Filenames: `.claude.json.backup.<epoch-ms>`. Not under our control; read-only to us.
- `~/.claude/bak_*_<filename>` — **in-place per-file rotation** at repo/config root (e.g., `bak_1_statusline.conf`, `bak_2_statusline.conf`). Used when a single config file is being edited and the convention is to preserve the previous 1–2 versions adjacent.

**In scope:** snapshots enabling revert/recovery, RESTORE.md convention, retention/pruning scripts, archive locations.
**Out of scope:** primary logs themselves (`events.jsonl`, `wal.jsonl` live as state; their archives live here), shell history (`shell-logs/` has its own cleanup).

**Conventions:**
- Named backup dirs: `YYYYMMDD-<label>/` under `assets/backups/`
- Every named backup includes `RESTORE.md` — symptom → cause → revert-command table
- In-place rotation: `bak_1_<file>`, `bak_2_<file>` (older); rotate before editing
- `prune-backups.sh` never touches `~/.claude/backups/` (CLI-managed) or root-level `bak_*` (manual)

---

### `std::claude::improvement` — Self-correction & learning **[facet]**

**Surface:** State (distributed across 6+ locations)
**Paths (all sub-labels):**

| Sub-label | Path | Purpose |
|---|---|---|
| `::improvement::ideas` | `~/.claude/improvement-ideas.md` | Backlog of system-level improvements noticed during work |
| `::improvement::mistakes` | `~/.claude/atone/events.jsonl` (raw) + `~/.claude/mistake-patterns.md` (derived) | Append-only mistake event log + auto-regenerated curated view. Skill: `/atone`. Spec: `features/atone.md` |
| `::improvement::affirmations` | `~/.claude/affirm/events.jsonl` (raw) + `~/.claude/compliments.md` (derived) | Append-only affirmed-behavior log + auto-regenerated curated view. Skill: `/affirm`. Sibling of mistakes axis. |
| `::improvement::proposals` | `~/.claude/proposals.jsonl` + `scripts/propose.sh` | Append-only JSONL backlog filed mid-task with status lifecycle (`open`/`done`/`rejected`) |
| `::improvement::insights` | `~/.claude/skills/runtime-notes.md` + `runtime-notes-archive-<quarter>.md` | Post-skill-run insights; prepended via `prepend-runtime-note.sh` |
| `::improvement::dreams` | `~/.claude/subconscious/dreams/`, `metacog/`, `introspection/`, `intentions/`, `valence/` | Async self-reflection daemon outputs |
| `::improvement::triggers` | `~/.claude/atone/derived/triggers.json` | Unified lookup table (atone + affirm). Consumed by hinters `05-atone-tldr`, `30-atone-nudge`, `50-atone-periodic-refresh`. |

**In scope:** any mechanism for noticing, recording, and acting on lessons, gaps, or failures. Cross-session learning artifacts. Self-reflection daemons.
**Out of scope:** raw session log (WAL, which is `::scratchpad`-adjacent state), user-level memories (`::memory`), code-pattern seeds (`::code::ideas`).

**Distinctions worth keeping sharp:**
- `::improvement::ideas` vs `::code::ideas` — the former is about improving Claude's *config/workflow*; the latter is about code patterns for building *features*. Different audiences, different read triggers.
- `::improvement::insights` (per-skill, structured) vs `::improvement::dreams` (async, free-form). Both capture lessons; different production mechanism.
- `::improvement::mistakes` (user-correction-triggered, raw is unbounded but curated view caps at top-20 by score) vs `::improvement::proposals` (self-filed). Mistakes are behaviors to avoid; proposals are improvements to file.
- `::improvement::mistakes` vs `::improvement::affirmations` — the two axes of behavioral tracking. Mistakes = what to avoid; affirmations = what to repeat. Same architecture (append-only event log, derived curated view, kernel protection, git-tracked) but different schemas (severity + RCA on atone, neither on affirm).

**Governance:**
- `~/.claude/atone/events.jsonl` is append-only and kernel-locked (`chflags uappnd`); never deletes raw events
- `~/.claude/mistake-patterns.md` is now a DERIVED view (regenerated by `atone-consolidate.sh`); top-20 by ranking score, rest in `derived/archive.md` — never edited by hand
- `proposals.jsonl` never deletes — `reject --reason` preserves the audit trail
- `runtime-notes.md` archives quarterly via `/archive-notes` skill when length grows
- `improvement-ideas.md` uses scannable sections; graduate items to `proposals.jsonl` when ready for action

---

### `std::claude::startup` — Login-time maintenance

**Surface:** Executable
**Path:** `~/.claude/scripts/startup/` + `~/Library/LaunchAgents/dev.claude-startup.plist`
**Trigger:** macOS LaunchAgent fires once per user-login session (RunAtLoad=true). On this single-user box where the user restarts ~weekly without logging out, that's effectively per-reboot.

Modular maintenance: `run.sh` orchestrates `tasks/NN-<slug>.sh` in lexical order. Each task supports `--dry-run`, prints one-line stats, and documents revival in its header.

Current tasks:
- `10-cleanup-tab-state.sh` — drops stale `/tmp/claude-tab-*` (>7 days)
- `20-prune-transcripts.sh` — gzip `projects/*.jsonl` >6 mo, delete `.jsonl.gz` >12 mo

Add a task by dropping a script into `tasks/`. See `scripts/startup/README.md` for the contract.

**Manual run:** `bash ~/.claude/scripts/startup/run.sh [--dry-run|--task NAME|--list]`
**Log:** `~/.claude/logs/startup.log`

---

### `std::claude::checkpoints` — Session-keyed checkpoint registry

**Surface:** State + Executable
**Path:** `~/.claude/checkpoints/` (data) + `~/.claude/scripts/checkpoint/` (helpers)
**Consumers:** `/core-dump` (writer), `/catchup` (reader)

Solves the "multiple long-running agents clobbering a single global pointer" problem. Each `/core-dump` writes:
- `<session-id>.json` — that session's own pointer (refreshable, no contention)
- one line appended to `index.jsonl` — chronological log driving the `/catchup` picker
- `~/.claude/_last-checkpoint.json` — legacy single-slot pointer (back-compat; removed in migration 0008, tracked by proposal `prop-20260515-141140-44`)

**Helpers (in `scripts/checkpoint/`):**
- `write.sh` — atomic write of all three files
- `list.sh` — formatted recent-entries table (drives the picker UI)
- `resolve.sh` — pick a checkpoint by `--session-id`, `--pick N`, or `--auto` (exit 2 = ambiguous → caller shows picker)

**Why this design:** the prior single-slot pointer caused parallel sessions in different projects to overwrite each other; the woken-up session would read the wrong project's checkpoint. Session-keyed addressing means a long-running agent always resolves to its own pointer, no fight.

---

### `std::claude::migrations` — Structural change log

**Surface:** Reference
**Path:** `~/.claude/migrations/`

Index file `MIGRATIONS.md` plus one doc per migration (`NNNN-slug.md`, zero-padded, gaps allowed, never renumbered).

**In scope:** any rename, move, or restructure of global Claude config that could break references in memory files, scratchpad, skills, or CLAUDE.md pointers. **Retroactive migration docs are allowed** — backfill a migration for a past structural change so the log is the canonical index.
**Out of scope:** routine file edits, code changes inside a skill.

---

## Cross-namespace rules

- **A file lives in exactly one namespace.** If it seems to fit two, pick the surface it leads with. Dual-citizenship causes drift.
- **Facets are read-mostly.** You don't create a `tui/` or `backups/` directory to "consolidate". Real files live where they already are.
- **Moving a file crosses a namespace boundary only via a migration.** Renaming inside the same cluster is a normal edit.
- **Relabelling is free.** Adding a namespace label to an existing file is not a migration — just update NAMESPACE.md.
- **Labels in prose are fine.** Say "the `::shared` locks" in a comment. Don't force formal prefixes everywhere.

---

## Recovery from stale references

If you encounter a path or label in CLAUDE.md, a memory file, a scratchpad plan, or a skill that no longer resolves:

1. **First check** `~/.claude/migrations/MIGRATIONS.md` — scan the index for anything touching the stale path.
2. **Open the migration doc** (e.g., `0001-namespace-introduction.md`) and read the "Files affected" + "Path moves" tables.
3. **Update the reference in place** — use the new path from the migration doc. If the migration is still `⏳ Planned`, leave the old reference and note it in the WAL.
4. **If no migration covers it**, it is probably a typo or a deletion — grep for the old path, delete dead references, and file a `::improvement::proposals` entry via `propose.sh`.

A future PreToolUse hook could warn when reading a known-stale path, but the primary recovery mechanism is this convention + the migration log.

---

## Contribution model

To add a new namespace:

1. Pick a label — one word, lowercase, sibling depth (`std::claude::<name>`).
2. Decide the surface (Reference / Executable / Behavior / State). One only.
3. If artifacts are distributed, mark `[facet]` and list all paths.
4. Add a row to the tree above and a full section below.
5. If any existing files move into it, open a migration under `::migrations`.
6. Update `LOOKUP.md` only if tactical file-level pointers change.

To retire a namespace:

1. Migration doc first — document what it absorbed and what consumers must update.
2. Remove from the tree. Leave a short note in the migration log.

---

## Under consideration (deferred)

These may become namespaces later but are not promoted yet:

- `::config` — CLAUDE.md, LOOKUP.md, settings.json, settings.local.json. Currently just "the root". Promotes if config surface area grows.
- `::observability` — `events.jsonl`, `wal.jsonl`, runtime-notes viewed through the "what happened?" lens. Currently covered by `::scripts` (emit-event) + `::improvement::insights` + `::backups` (archives). Could promote if a telemetry dashboard emerges.
- `::agents` — custom agent definitions at `~/.claude/agents/`. Sibling candidate; currently too small.
- `::hooks` — subset of `::scripts` filtered by "registered in settings.json hooks". Facet candidate if hook catalog grows distinct from CLI scripts.

Don't create a namespace speculatively — wait until at least two artifacts want the label.

---

## Migration history

| # | Title | Status | Doc |
|---|---|---|---|
| 0001 | Introduce std::claude namespace system | ✅ All phases executed (Phase 2 split to 0004) | `migrations/0001-namespace-introduction.md` |
| 0002 | Phase 1+2 upgrade (retrofit) | ✅ Applied 2026-04-17 | `migrations/0002-phase12-upgrade-retrofit.md` |
| 0003 | Add ::backups and ::improvement namespaces | ✅ Phase 0b executed 2026-04-17 | `migrations/0003-backups-improvement-namespaces.md` |
| 0004 | Global memory tier | ✅ Executed 2026-04-17 (revised: additive, no move) | `migrations/0004-memory-global-tier.md` |
| 0005 | Add ::vision, ::network, ::widgets, ::todos namespaces | ✅ Phase 0c executed 2026-04-17 | `migrations/0005-vision-network-widgets-todos.md` |

Full log: `~/.claude/migrations/MIGRATIONS.md`

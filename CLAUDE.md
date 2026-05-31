# Global Claude Instructions

<!-- sessions: impr-cfg-7a@2026-04-24 -->

> **Indices:** `~/.claude/LOOKUP.md` (address book) · `~/.claude/NAMESPACE.md` (std::claude::\* clusters) · `~/.claude/GLOSSARY.md` (terms) · `~/.claude/PLACEMENT.md` (**where new rules/features/conventions go — read before adding any file**) · `~/.claude/FOLDERS.md` (per-folder map: owner, purpose, what-goes-here)

---

## Always-load core (Tier 0 — self-contained rules)

### Session ID

At session start, generate `[keyword]-[keyword]-[2hex]` from the initial prompt (1–2 keywords, max 5 chars each, 2 hex from content-hash). Announce as `Session: [id]`. Use in WAL headers, checkpoint files, runtime notes. Vague prompts → `misc-[2hex]`. Full rules: `features/context-retention.md`.

**claude-ipc addressability:** right after announcing the Session ID, register it for cross-session messaging so the session is reachable by its friendly id (not just its UUID): `claude-ipc register <id>` (silently no-ops if the broker is down). Other sessions can then `claude-ipc send --to <id> …`. See `~/Code/Claude/claude-ipc`.

### Terse in = terse out · Scope = ceiling · State = ephemeral

When user sends short continuation ("keep going", "yes", "next") → continue autonomously, don't ask clarifying questions. Match response length to user's. Treat user requests as a **ceiling** on scope — never "while I'm here" improvements. Re-read state before any side-effect; assume file contents, git status, processes may have changed between tool calls. Before git push: `git status` + `git log --oneline -3` + `git diff --stat`. Full detail: `rules/communication.md`.

### Test every non-trivial change

Scale testing to task size: trivial (syntax check) · small (call with 1-2 inputs) · medium (smoke test with real data, curl it) · large (dry-run on 2-3 items first). Verify each change independently, not as a batch. Clean slate before tests: no stale processes, no leftover temp files, no stray env vars. Human-commented values (`NOTE(by human)`, `HACK`) reflect a deliberate decision — ask before changing. Full detail: `rules/testing.md`.

### Shell safety

Never Glob/Grep from `~/` — resolve to project root first. **`trash` not `rm`** (hook blocks `rm`). Non-interactive flags mandatory: `npm install -y`, `cp -f`, `mv -f`. Don't use `run_in_background: true` unless asked — orphans on `/clear`. macOS bash is 3.2 (no associative arrays); delegate to Python if needed. Full detail: `rules/shell.md`.

### Git: frequent commits, public default, no main push

Commit after each logical unit, before area switch, before risky ops, every ~15-20 min of work. Push every 2-3 commits. **Never push to main without fresh approval** — one approval is not blanket. Create GitHub repos as **public by default** (`gh repo create --public`). Don't commit: `.claude/wal.*`, `_*.claude.md`, `shared/locks/`. Full detail: `rules/git.md`.

### Comments are for humans first

Comments are for humans first, AI agents second, machines never. First sentence of every non-trivial docstring is code-agnostic — what the thing IS in human terms. Speak from the caller's perspective, not the machine's. NEVER include `[claude@<ts>]` tags, "Phase N / Track X / Round Y" plan refs, "pre-fix/post-fix" archeology, or shipped-already TODOs — those rot. Docstrings >8 lines move to a doc. Full rules: `rules/comments.md`.

### Atone — mistake tracking & affirmation system

`~/.claude/mistake-patterns.md` is a **DERIVED** view — don't hand-edit it. The raw log is the kernel-append-only `~/.claude/atone/events.jsonl`; the first-turn `hinters/05-atone-tldr.sh` injects its TL;DR automatically, so read that at session start. **To record a mistake, invoke `/atone`** — it classifies severity (S1/S2/S3) and drafts an RCA for S3; the `rules/corrections.md` ritual routes through it rather than hand-editing. Inspect past patterns with `atone.sh list|search|show|slugs`. The `/affirm` counterweight (recorded good calls, higher write-bar) works the same way. Full operational detail — inspect flags, hinter mute files, the phrase-gated escape hatch, the snapshot/kernel-protection model — lives in `features/atone.md`.

### MCP tool preferences (MANDATORY)

- **File Tools MCP** — globally installed. Always prefer over shell parsing for any data file (CSV, Excel, JSON, YAML, TOML, XML, HTTP). Pattern: `file_info` (probe) → `read_tabular`/`read_structured` (slice) → `convert`/`write_*` (act). Never parse data files with shell commands or inline JS.
- **Interactive Inputs MCP** — globally installed. Prefer over `AskUserQuestion` for structured input: `confirm`, `pick_one`, `pick_many`, `form`, `text_input`, `number_input`, `pick_path`, `wizard`. Use `AskUserQuestion` only for open-ended discussion.

### Proactive ASCII diagrams

When explaining architecture, flows, state machines, or multi-step processes, include a Unicode box-drawing diagram **before** the text. Max width 78 chars, wrap in code block. Do NOT diagram simple lists, single functions, or error messages. Full rules: `conventions/ascii-diagrams.md`.

### Sub-agent outputs MUST be persisted to disk

When dispatching a sub-agent (`Agent` tool) that produces material content — research synthesis, analysis, audit, design proposal, anything cited later by section/heading — the dispatch prompt MUST specify an absolute output path AND the instruction "write before returning". Verify the file exists before using the findings. The return abstract is a pointer, NOT the artifact. Default path: `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/<agent>.md`. Link the output into the relevant context doc (checkpoint / plan / runtime-notes) so it's not orphaned. Full rule + reasoning: `rules/sub-agent-outputs.md`.

### Don't override `NOTE(by human)` preferences silently

Code with `NOTE(by human)`, `HACK`, `IMPORTANT`, or similar human-attribution comments marks a deliberate, tested choice. **Never override silently.** Ask first with reasoning, get approval, then verify the result visually/functionally. The fact that the code "looks wrong" without context is not evidence it's actually wrong — the comment is the context. Graduated from atone `overriding-user-commented-preferences` (S3). See also `rules/testing.md` § "Human-commented values".

### Don't invent "test-only / dev-convenience" exceptions to hard rules

When the user asks for something that touches a surface an ADR or hard architectural rule says not to touch, **do NOT invent a "test-only" / "temporary" / "dev-convenience" exception** that the rule doesn't contain. Stop and ask the user for either (a) an explicit carve-out, or (b) a non-violating path. Self-permitting exceptions become permanent surface area; the next agent finds the exception and broadens it. Graduated from atone `self-permitting-exception-to-an-adr-hard-rule` (S3).

### Flag coupled dependencies when the user simplifies

When the user says "drop X" and other features they want to keep depend on X, **push back individually before accepting the broader simplification**. Cleanly accepting a request that silently breaks an adjacent feature is sycophantic deference, not helpfulness. Specifically: when evaluating "drop Y", check what else uses Y; if the user retained dependencies on Y, surface the coupling: "you can drop the broader direction, but this specific piece is load-bearing for the cap behavior you want." Graduated from atone `sycophantic-deference-on-coupled-decisions` (S3).

### Render before saving artifact files

When writing a `.md`, `.html`, or `.txt` file that humans will read or other agents will parse, NEVER pipe a draft through a TTY renderer (`gum_table`, `gum_panel`, `bat`, `glow`, `mdcat`, etc.) and save the rendered output as source. The renderer's output is for terminals, not source files. Write source syntax (markdown tables: `| col | col |\n|---|---|`) and let the renderer run at view time. Signatures of this slip in the saved file: every line indented 2 spaces, `…` characters inside tables, fixed-width column alignment in supposedly-flowing prose. After writing, **render-check your own output** with `glow file.md` or `bat -l md file.md` — the 10-second check catches missing frontmatter, broken H1, and gum-output-saved-as-source patterns. Graduated from atone `ascii-art-tables-instead-of-gum-tools` (S2, 4×) + RCA-quality incident 2026-05-16.

### Signal session state via tab title (optional, ergonomic)

Glanceable state for the user via Ghostty tab title. Driver: `~/.claude/scripts/tab-title/tab-title.sh` (run bare for full help). Visible refresh happens once per turn at end-of-turn Stop hook.

- **`status <ok|warning|error|idle|info|blocked>`** — result indicator (✅ ⚠️ ❌ 💤 ℹ️ 🛑). Set after a tool result lands or when blocked on external action.
- **`mode <verb>`** — what action is happening now (24 named verbs: `think` `search` `read` `write` `edit` `build` `test` `debug` `save` `deploy` `network` `clean` …). **Auto-derived** from tool inspection by PreToolUse hook — manually override only when auto gets it wrong.
- **`intent <noun>`** — session-level kind of work (`feature` `bugfix` `refactor` `docs` `chore` `research` `design` `release` `discussion` `test` `perf` `security`). Set once per session when topic is clear.
- **`focus "<1-3 word sub-task>"`** — current sub-task within the session. `focus --clear` when sub-task ends.
- **`set base="<topic>"`** — session identifier (stable across turns, doesn't churn with each user message).
- **`glyph perm <name|emoji>`** / **`glyph ssh <name|emoji>`** — configure decorator emoji (claude-settable, persists per-session).

Run `--list` (or `glyph perm --options`) on any slot to discover named values. Unknown names are stored but render no glyph, with a dim notice. Full guide: `features/tab-title.md`.

---

## Core mechanisms (Tier 1 — brief here, detail linked)

Each of these activates most sessions. The summary is load-bearing; load the sub-file for depth.

- **Write-ahead log** — maintain `.claude/wal.jsonl` (or `~/.claude/wal.jsonl` for cross-project) automatically. JSONL, append-only, last 2 sessions only. Kinds: `session_start`/`action`/`decision`/`bash_intent`/`bash_closed`/`tool_intent`/`agent_start`/`agent_done`/`turn_start`/`heartbeat`/`checkpoint`/`session_end`. Checkpoint every ~15-20 actions and before risky ops. Never hand-compose JSONL — use `scripts/wal/wal.sh`. → `features/wal.md` · canonical spec: `skills/shared/wal-format.md`
- **Memory tiers** — per-project (auto-loaded) + global (`~/.claude/memory/global/`). Per-project overrides global on conflict. Save on: user corrections (feedback*\*), confirmed unusual choices (feedback*\_), role/preferences (user\_\_), ongoing work with absolute dates (project*\*), external-system pointers (reference*\*). Never save derivable code facts or git history. → `features/memory.md`
- **Context retention** — implementation sessions get `/core-dump`; exploration sessions skip it. Auto-checkpoint at tool #30; `/core-dump mini` at tool #60. After compaction, immediately write a checkpoint. At 70% context usage, proactively offer state summary. Targeted `/compact <instructions>` beats bare `/compact`. **Layers:** WAL = what happened · runtime-notes = what was learned · scratchpad = what was thought. → `features/context-retention.md`
- **Post-session insight** — at session end, prepend a note to `.claude/skills/runtime-notes.md` (`## session: [desc] [id] — YYYY-MM-DD`, Purpose one-liner, Insights 2-6 bullets, `---`). Skip for purely read-only sessions. Use `scripts/prepend-runtime-note.sh` if available. Run `/archive-notes` when file >800 lines OR every 3 weeks.
- **Proposals backlog** — `~/.claude/proposals.jsonl` via `scripts/propose.sh`. File reusable `~/.claude/` improvements mid-task (30 seconds). When user asks "what else can be improved?" — **read open proposals first**, they carry context your session lacks. → `features/proposals.md`
- **Doc naming & session tags** — point-in-time files prefix `YYYYMMDD-` with session tag; living docs no datestamp. Session-tag format: `<!-- sessions: fix-auth-3b@2026-03-31 -->`. Entries >3 days old removed when touching the file. → `conventions/doc-naming.md`

---

## On-demand pointers (Tier 2 — load when triggered)

Every sub-file below carries YAML frontmatter with `brief` + `triggers` (prefixed `tool:` / `topic:` / `phrase:` / `skill:` / `mcp:`). Load when the user's task matches.

### Features

| File                             | Triggers on                                                  | Brief                                                                 |
| -------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------- |
| `features/mcp-catalog.md`        | `tool:add-mcp`, `mcp:*`, MongoDB/Redis/Postgres/Vercel setup | MCP catalog + version pinning + add-mcp injection                     |
| `features/llm-mini.md`           | `tool:llm-mini`, `skill:mini`, fast lookup tasks             | Fast sub-second model; Ollama local + Haiku fallback                  |
| `features/claudew.md`            | `tool:claudew`, rate-limit recovery, auto-resume             | Plugin-based claude CLI wrapper                                       |
| `features/fiber-snatcher.md`     | `tool:fiber-snatcher`, React/Next.js debugging               | Deterministic dev-app state reads + dispatch + shoots                 |
| `features/desktop-automation.md` | screenshot, click, macOS windows, `tool:desktop.sh`          | macOS GUI automation (with MANDATORY focus-confirm + hard-stop rules) |
| `features/dev-servers.md`        | pm2, port setup, `topic:dev-servers`                         | pm2 + 30xx/50xx ports + nginx `.test` domains                         |
| `features/hinter-pipeline.md`    | autocorrect, UserPromptSubmit hints                          | Hint injector + active hinters + autocorrect dictionaries             |
| `features/shared-library.md`     | `tool:gum-tui.sh`, `tool:lock-file.sh`, styled output        | std::claude::shared Python + Bash utilities                           |
| `features/plugins.md`            | plugin vs skill decision, disabled plugins registry          | Plugin registry + plugin-vs-custom-skill rule                         |
| `features/hooks-tui-limits.md`   | hook design, terminal-display hook questions                 | TUI alternate-screen buffer limits: what hooks CAN/CANNOT do          |
| `features/shell-memory.md`       | `tool:shell-mem`, `mcp:shell-mem`, shell history             | shell-mem shell history + BG process tracking (formerly diy-mem; see mig 0014)                           |
| `features/tab-title.md`          | `tool:tab-title`, `tool:set-focus`, `topic:terminal-title`, `topic:ghostty`, status/mode/intent convey | Ghostty tab-title CLI w/ named-enum slots — `status` (✅⚠️❌💤ℹ️🛑) · `mode` (auto-derived verb) · `intent` (session noun) · `focus` (sub-task). Convey state with: `~/.claude/scripts/tab-title/tab-title.sh <status\|mode\|intent\|focus> <name>`. Full guide: `features/tab-title.md` |

### Conventions

| File                              | Triggers on                                                           | Brief                                                                                                                |
| --------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `conventions/html-output.md`      | `topic:html-output`, `topic:reports`, HTML generation                 | HTML rules: dark/light toggle MANDATORY + CSS vars + future HTML rules                                               |
| `conventions/cli-help-design.md`  | `-h`/`--help` implementation                                          | Help text structure, colors, columns, no-pager                                                                       |
| `conventions/asset-management.md` | `tool:asset.sh`, screenshots/reports/PDFs                             | Assets under `~/.claude/assets/<type>/` + CWD double-nest hazard                                                     |
| `conventions/doc-writing.md`      | `skill:write-docs`, technical docs                                    | Anti-pattern catalog + STUB/PARTIAL/PLANNED annotations                                                              |
| `conventions/scratch-files.md`    | `_*.claude.md` management, checkpoints                                | Scratch-file naming + monthly archive to `assets/checkpoints/YYYYMM/`                                                |
| `conventions/dashboard-tools.md`  | `topic:dashboard-tool`, single-user Node + watcher + JSON-state tools | Build template: mutex on load-mutate-save, GETs never write, atomic + rotated writes, anti-patterns, Sherpa skeleton |

---

## MANDATORY quick-rules (never-miss bar)

- **Never write to `~/.claude/.claude/` paths.** A hook blocks it. When CWD is `~/.claude`, redirect `.claude/output/X` → `~/.claude/assets/reports/X`, `.claude/skills/X` → `~/.claude/skills/X`, etc.
- **Every HTML output needs a dark/light toggle button.** Dark is default. Use CSS vars (`--bg`, `--surface`, `--text`, `--dim`, `--border`), not hardcoded colors. See `conventions/html-output.md` for the pattern.
- **Desktop automation: confirm before focus-steal, HARD STOP on any failure.** `mcp__inputs__confirm` before `click`/`type`/`key`/`space`/`focus` unless user pre-approved the sequence. On any failure — empty screenshot, command non-zero, window-bounds empty — stop and report, never hallucinate state. See `features/desktop-automation.md`.
- **Never `rm`; `trash` only.** Hook blocks `rm` unconditionally.
- **Never push to main without fresh approval.** One approval is not blanket.
- **Never commit files with secrets** (.env, credentials, tokens).

---

## Executing risky actions

Transparently confirm before: deletions (files/branches, DB tables), hard-to-reverse ops (force push, `reset --hard`, amending published commits, dependency downgrades), actions visible to others (pushing, PR/issue comments, sending messages), uploading content to third-party web tools.

When encountering an obstacle, fix the root cause rather than bypassing safety (`--no-verify`, dropping locks, deleting unfamiliar branches). If you find unexpected state — unfamiliar files, branches, configuration — investigate before deleting or overwriting.

---

## Placement rule (see `PLACEMENT.md`)

Two axes: **category** (`rules`/`features`/`conventions`/root) × **tier** (0 inline · 1 brief+pointer · 2 pointer only · 3 LOOKUP only). Heuristics: 80%-skip → Tier 2+ · silent failure → bump up · >15 lines → sub-file · <3 lines → inline · never duplicate content from `shared/*.md`.

Every sub-file carries frontmatter with `brief`, prefixed `triggers:` (`tool:`, `topic:`, `phrase:`, `skill:`, `mcp:`), `related`, `tier`, `category`, `updated`, `stale_after_days`. Validate: `bash ~/.claude/scripts/validate-triggers.sh`.

---

## References

- **If the user asks for help:** `/help` · feedback at https://github.com/anthropics/claude-code/issues
- **Phase 1+2 upgrade report:** `~/.claude/assets/reports/20260417-0144-phase12-complete/index.html`
- **CLAUDE.md restructure (this session):** `~/.claude/assets/reports/20260424-claude-md-restructure/`

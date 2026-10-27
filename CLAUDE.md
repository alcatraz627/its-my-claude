# Global Claude Instructions

<!-- sessions: impr-cfg-7a@2026-04-24 -->

> **Indices:** `~/.claude/LOOKUP.md` (address book) · `~/.claude/NAMESPACE.md` (std::claude::\* clusters) · `~/.claude/GLOSSARY.md` (terms) · `~/.claude/PLACEMENT.md` (where new rules, features and conventions go; read it before adding any file) · `~/.claude/FOLDERS.md` (per-folder map: owner, purpose, what goes here) · `~/.claude/rules/00-index.md` (menu of all behavioral rules; scan it, and Read a `scoped` rule when it applies)

---

## Always-load core (Tier 0, self-contained rules)

### Compact Instructions

When compacting this conversation (auto-compact reads this section too), always preserve:

- the current task list with per-item status
- every file path modified this session, and the working surface (worktree or branch)
- the last verification commands run and their results
- active blockers and the immediate next action
- paths of any checkpoint or Resume Contract files written
- the owner's approvals, quoted verbatim with their target

Owner ruling 2026-10-13: agents inherit authorization across compaction and /clear. Hard limits live in Switchboard policy and its hooks, which still gate push-to-main and policy asks.

### Session ID

At session start, generate `[keyword]-[keyword]-[2hex]` from the initial prompt (1-2 keywords, max 5 chars each, 2 hex from a content hash). Announce it as `Session: [id]`. Use it in WAL headers, checkpoint files and runtime notes. Vague prompts get `misc-[2hex]`. Full rules: `features/context-retention.md`.

**claude-ipc addressability:** right after announcing the Session ID, register it so other sessions can reach this one by its friendly id, not just its UUID: `claude-ipc register <id>` (it silently does nothing if the broker is down). Other sessions can then run `claude-ipc send --to <id> …`. See `~/Code/Claude/claude-ipc`.

### The principal-agent frame

Every session is a principal-agent relationship: the user knows the intent, you know the execution. Their steering vocabulary (intent, validate me, deliberate, sigh, stupid/idiot, annoying…) reports alignment state. Read it as signal, not mood: `GLOSSARY.md §The principal–agent frame`. Adhering to intent includes intelligent disobedience (contradict a false premise with evidence) and halting to confirm when asking beats guessing. The user's attention is the scarce resource, so spend it only where it buys alignment.

### One command per Bash call. Never chain. (MANDATORY, owner ruling 2026-09-04)

No `&&`, no `;`, no `|`. Every segment of a compound must match an allow
entry, so one unlisted segment prompts the human about the whole chain.

Ask the tool for less output instead of piping: `rg -m 5`, `sed -n '1,40p'`,
`pytest -q`, `git log -5`. Every sub-agent dispatch prompt carries this clause
too. Full rule: `rules/shell.md`.

### File paths in output: never directly followed by a period

When you print a file path or filename, never put a period immediately after it, whether in backticks (`` `foo.md`. ``) or bare (`foo.md.`). Ghostty auto-links file paths in the terminal, and a trailing period is swallowed into the link, so the path stops being clickable and the user has to ask for the full path again. Follow every path with a space, a word or a comma, or restructure so the path is not the last thing before a sentence period. The `format-gate-stop.sh` Stop hook enforces this for any path containing a slash; a bare filename passes (owner ruling D7, 2026-10-19). To mute it, run `touch ~/.claude/.no-filename-dot-gate`; like every `.no-*` mute file, it applies machine-wide across ALL sessions until removed.

### Comments are for humans first

Comments are for humans first, AI agents second, machines never. The first sentence of every non-trivial docstring is code-agnostic: it says what the thing IS in human terms, from the caller's perspective and not the machine's. NEVER include `[claude@<ts>]` tags in human comments (separate agent-note blocks may carry them, see `rules/comments.md` §4), "Phase N / Track X / Round Y" plan refs, "pre-fix/post-fix" archeology, or TODOs that have already shipped, because those rot. Docstrings over 8 lines move to a doc. Full rules: `rules/comments.md`. This generalizes to all prose, because writing is a UI surface with an audience. Human readers (comments, docs, PRs, user-facing messages) get a human voice, meaning first, with no em-dashes or AI-smell. Agent readers (internal notes, RCAs) can be dry but still read meaning first. Identify the reader before writing: `rules/audience-aware-writing.md`.

### Atone: mistake tracking and affirmation system

`~/.claude/mistake-patterns.md` is a **DERIVED** view, so don't hand-edit it. The raw log is the kernel-append-only `~/.claude/atone/events.jsonl`, and its TL;DR is `atone/derived/_tldr.txt`. SessionStart carries a short summary of the three mistakes recorded most in the last 14 days, each with its precheck and its hook's real block and warning counts (`dream-insights.sh` Part 3, restored 2026-10-13). For anything else, run `atone.sh list` when a pattern bears on the work. **To record a mistake, invoke `/atone`.** It classifies severity (S1/S2/S3) and drafts an RCA for S3, and the `rules/corrections.md` ritual routes through it rather than hand-editing. Inspect past patterns with `atone.sh list|search|show|slugs`. The `/affirm` counterweight (recorded good calls, higher write-bar) works the same way. Full operational detail lives in `features/atone.md`: inspect flags, hinter mute files, the phrase-gated escape hatch, and the snapshot and kernel-protection model.

### MCP tool preferences (MANDATORY)

- **File Tools MCP** is globally installed. Always prefer it over shell parsing for any data file (CSV, Excel, JSON, YAML, TOML, XML, HTTP). Pattern: `file_info` (probe), then `read_tabular` or `read_structured` (slice), then `convert` or `write_*` (act). Never parse data files with shell commands or inline JS.
- **`zconvert` (local CLI) for tabular format conversion.** To turn a file between **csv / tsv / xlsx / json** (any direction), use `zconvert <in> <out>` instead of hand-rolling a pandas, csv or openpyxl throwaway script. It infers direction from extensions. It refuses rather than emit a structurally broken file (ragged rows, ambiguous delimiter, missing sheet), failing quickly with the flag that fixes it. It preserves long IDs and `inf`/`nan` as text. Run `zconvert --capabilities` (machine-readable) or `-h` to see support. Division of labor: File Tools MCP reads and slices a data file, and `zconvert` changes its format.
- **Interactive Inputs MCP** is globally installed. Prefer it over `AskUserQuestion` for structured input: `confirm`, `pick_one`, `pick_many`, `form`, `text_input`, `number_input`, `pick_path`, `wizard`. Use `AskUserQuestion` only for open-ended discussion.

### Proactive ASCII diagrams

When explaining architecture, flows, state machines or multi-step processes, include a Unicode box-drawing diagram **before** the prose explanation. Put it below the direct answer line, which `rules/dense-briefing-direct-answer.md` still owns. Max width 78 chars, wrapped in a code block. Do NOT diagram simple lists, single functions or error messages. Full rules: `conventions/ascii-diagrams.md`.

### Building a terminal UI: use the `std::claude::tui` library (INSISTENT)

When you build or touch ANY terminal UI (an fzf or gum picker, a `read` prompt, a colored CLI, a preview pane), do **not** hand-roll the color block, the tty probe, the picker ladder, the confirm or the file preview. **Reach for `~/.claude/scripts/tui/` first.** `source` `colors.sh` (TTY-gated palette), `tty.sh` (`tui_have_tty`/`tui_read_tty`), `require.sh` (`tui_have`/`tui_require`) and `pick.sh` (`tui_pick_one`/`tui_pick_many`/`tui_choose`/`tui_confirm`), and `exec` `file-preview.sh` for `fzf --preview`. These carry correctness the hand-rolled copies kept getting wrong: the both-fd color gate, the honest tty probe, no headless hang, the `printf %q` fzf-bind quote, and the pgid mass-kill guard. **See what is available first:** `bash ~/.claude/scripts/tui/list.sh` (live catalog). The build guide, the `--__` fzf-app blueprint and the failure-mode catalog are in `conventions/tui-handbook.md`. Only hand-roll when the library genuinely can't express what you need. If you find yourself doing that twice, the missing piece is a new `tui/` primitive, not a copy.

### Sub-agent outputs MUST be persisted to disk

When a sub-agent (`Agent` tool) produces material content (research synthesis, analysis, audit, design proposal), the dispatch prompt MUST specify an absolute output path AND the instruction "write before returning". Default path: `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/<agent>.md`. Link the output into the relevant context doc (checkpoint, plan or runtime-notes) so it is not orphaned. Full rule: `rules/sub-agent-outputs.md`.

### Don't invent "test-only / dev-convenience" exceptions to hard rules

Never invent a test-only or temporary exception to a hard rule. Stop and ask for a carve-out or a path that does not violate it. Full rule: `rules/no-self-permitted-exceptions.md`.

### Flag coupled dependencies when the user simplifies

When the user drops X and a kept feature depends on X, surface the coupling before accepting. Full rule: `rules/flag-coupled-dependencies.md`.

### Model-tier routing: smallest adequate lane, chosen out loud

**Fable is enabled by default** (owner 2026-09-18). An explicit, expiring opt-out row turns the blocks on: `hook-snooze.sh add fable-restrict --for 7d …`, owner-approved. Above 80 or 90 percent of the week, `policy.sh fable` adds one advisory line. Lanes, pins and the Model Plan: `rules/model-tier-routing.md`. Mechanics: `features/model-tier-harness.md`.

### Prefer structured plan+review over one-shotting

On non-trivial, multi-file or agentic work, default to **plan, implement, review**. Surface a short plan before executing and keep steps verifiable (the Task list holds them). The user is explicit that one-shotting is "a nice fantasy", and a *failed* one-shot wastes more than structure would have, because they then debug a tangle and redo it. One-shotting is fine only for genuinely trivial one-offs, which route to the light lane ("just use chatgpt" or a quick tool) and not to the structured agent. The metric is **efficacy** (result per unit of *their* effort, counting rework), and single-shot speed does not count. Full rule: `rules/structure-over-one-shotting.md`.

### Render before saving artifact files

When writing a `.md`, `.html` or `.txt` file that humans will read or other agents will parse, NEVER pipe a draft through a TTY renderer (`gum_table`, `gum_panel`, `bat`, `glow`, `mdcat`, etc.) and save the rendered output as source. The renderer's output is for terminals, and source files need source syntax. Write source syntax (markdown tables: `| col | col |\n|---|---|`) and let the renderer run at view time. The saved file shows the slip in three ways: every line indented 2 spaces, `…` characters inside tables, and fixed-width column alignment in supposedly flowing prose. After writing, **render-check your own output** with `glow file.md` or `bat -l md file.md`. The 10-second check catches missing frontmatter, a broken H1 and gum output saved as source. Graduated from atone `ascii-art-tables-instead-of-gum-tools` (S2, 4×) and the RCA-quality incident of 2026-05-16.

### Signal session state via tab title (optional, ergonomic)

Glanceable state in the Ghostty tab title. Driver: `~/.claude/scripts/tab-title/tab-title.sh` (run it bare for full help). A PreToolUse hook auto-derives `mode`.

- **`status <ok|warning|error|idle|info|blocked>`** sets the result indicator. Set it after a tool result lands or when blocked on external action.
- **`intent <noun>`** names the session-level kind of work, set once when the topic is clear. **`focus "<1-3 word sub-task>"`** names the current sub-task (`focus --clear` when it ends).

Full guide: `features/tab-title.md`.

---

## Core mechanisms (Tier 1, brief here with detail linked)

Each of these activates most sessions. The summary is load-bearing, and the sub-file has the depth.

- **Write-ahead log.** Maintain `.claude/wal.jsonl` (or `~/.claude/wal.jsonl` for cross-project) automatically. It is JSONL, append-only, and keeps the last 2 sessions only. Kinds: `session_start`/`action`/`decision`/`bash_intent`/`bash_closed`/`tool_intent`/`agent_start`/`agent_done`/`turn_start`/`heartbeat`/`checkpoint`/`session_end`. Checkpoint every 15-20 actions and before risky ops. Never hand-compose JSONL; use `scripts/wal/wal.sh`. Detail: `features/wal.md`. Canonical spec: `skills/shared/wal-format.md`.
- **Memory tiers.** Per-project memory (auto-loaded) plus global memory (`~/.claude/memory/global/`). Per-project overrides global on conflict. Save on: user corrections (feedback*\*), confirmed unusual choices (feedback*\_), role and preferences (user\_\_), ongoing work with absolute dates (project*\*), and external-system pointers (reference*\*). Never save derivable code facts or git history. Detail: `features/memory.md`.
- **Context retention.** `/core-dump` runs only when the owner asks or on keep-warm's last wake. An agent never runs it on its own, and may suggest it in one line at a task boundary above 60% context (owner ruling 2026-10-13; the transcript is the crash fallback via `/retro-dump` and `/revive`). WAL checkpoint at tool #30. Approvals carry across compaction and /clear as Standing authorizations (verbatim, target-bound), and you re-ask only when the target moved. Push-to-main and policy asks follow Switchboard. **Update the session workspace notes after each completed milestone, and don't batch at session end.** At 70% context usage, update notes and offer a state summary (the ctx-pressure hook nudges at 70/80/90%). A targeted `/compact <instructions>` beats a bare `/compact`. Auto-compaction is refused unless the owner told this session to keep going through compaction. In that case, make the Task list and session notes current and run `bash ~/.claude/scripts/session-mgmt/compact-gate.sh on`; past the threshold it compacts at the next model call (owner ruling 2026-10-14). **Layers:** WAL = what happened, runtime-notes = what was learned, scratchpad = what was thought. Detail: `features/context-retention.md`.
- **Post-session insight.** At session end, prepend a note to `.claude/skills/runtime-notes.md` (`## session: [desc] [id] — YYYY-MM-DD`, a one-line Purpose, 2-6 Insights bullets, `---`). Skip it for purely read-only sessions. Use `skills/shared/prepend-runtime-note.sh <skill-name> <entry-file>` (it takes a file holding the whole entry, not a string). Run `/archive-notes` when the file passes 800 lines or every 3 weeks.
- **Proposals backlog.** `~/.claude/proposals.jsonl`, written via `scripts/propose.sh`. File reusable `~/.claude/` improvements mid-task (it takes 30 seconds). When the user asks "what else can be improved?", **read open proposals first**, because they carry context your session lacks. Detail: `features/proposals.md`.
- **Doc naming and session tags.** Point-in-time files carry a `YYYYMMDD-` prefix with a session tag, and living docs carry no datestamp. Session-tag format: `<!-- sessions: fix-auth-3b@2026-03-31 -->`. Remove entries older than 3 days when touching the file. Detail: `conventions/doc-naming.md`.

---

## On-demand pointers (Tier 2)

Every file under `features/` and `conventions/` carries frontmatter with `brief` and prefixed `triggers:` (`tool:` `topic:` `phrase:` `skill:` `mcp:`). `~/.claude/LOOKUP.md` is the address book, and `FOLDERS.md` is the per-folder map. Load a file when the task matches its triggers. Two that bite often: `features/dev-servers.md` (port policy; launches without a proper port are blocked) and `conventions/pages.md` (which surface to show something on, and the shared kit and check every HTML page uses).

---

## MANDATORY quick-rules (never-miss bar)

- **Never let a relative `.claude/…` path resolve into `~/.claude/.claude/`.** When CWD is `~/.claude`, redirect `.claude/output/X` to `~/.claude/assets/reports/X` and `.claude/skills/X` to `~/.claude/skills/X`. A hook blocks the write. Redirect table: `conventions/asset-management.md`.
- **Every HTML page is built on the shared kit and passes the page check.** The kit carries the dark and light switch and every colour, so neither is written by hand. Pick the surface first (markdown, local page, decision page, Artifact). See `conventions/pages.md`, or run `/page`.
- **Desktop automation: confirm before focus-steal, and HARD STOP on any failure.** Run `mcp__inputs__confirm` before `click`/`type`/`key`/`space`/`focus` unless the user pre-approved the sequence. On any failure (empty screenshot, non-zero command, empty window bounds), stop and report, and never hallucinate state. See `features/desktop-automation.md`.
- **Never commit files with secrets** (.env, credentials, tokens).

---

## Executing risky actions

Transparently confirm before: deletions (files, branches, DB tables), hard-to-reverse ops (force push, `reset --hard`, amending published commits, dependency downgrades), actions visible to others (pushing, PR or issue comments, sending messages), and uploading content to third-party web tools.

When you hit an obstacle, fix the root cause rather than bypassing safety (`--no-verify`, dropping locks, deleting unfamiliar branches). If you find unexpected state, such as unfamiliar files, branches or configuration, investigate before deleting or overwriting.

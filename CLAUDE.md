# Global Claude Instructions

<!-- sessions: impr-cfg-7a@2026-04-24 -->

> **Indices:** `~/.claude/LOOKUP.md` (address book) · `~/.claude/NAMESPACE.md` (std::claude::\* clusters) · `~/.claude/GLOSSARY.md` (terms) · `~/.claude/PLACEMENT.md` (**where new rules/features/conventions go — read before adding any file**) · `~/.claude/FOLDERS.md` (per-folder map: owner, purpose, what-goes-here) · `~/.claude/rules/00-index.md` (menu of all behavioral rules; scan it, Read a `scoped` rule when it applies)

---

## Always-load core (Tier 0 — self-contained rules)

### Compact Instructions

When compacting this conversation (auto-compact reads this section too), always preserve: the current task list with per-item status · every file path modified this session + the working surface (worktree/branch) · the last verification commands run and their results · active blockers and the immediate next action · paths of any checkpoint/Resume Contract files written. Record ALL user approvals for pushes/deploys/destructive ops as **NOT yet approved** — approvals never survive compaction.

### Session ID

At session start, generate `[keyword]-[keyword]-[2hex]` from the initial prompt (1–2 keywords, max 5 chars each, 2 hex from content-hash). Announce as `Session: [id]`. Use in WAL headers, checkpoint files, runtime notes. Vague prompts → `misc-[2hex]`. Full rules: `features/context-retention.md`.

**claude-ipc addressability:** right after announcing the Session ID, register it for cross-session messaging so the session is reachable by its friendly id (not just its UUID): `claude-ipc register <id>` (silently no-ops if the broker is down). Other sessions can then `claude-ipc send --to <id> …`. See `~/Code/Claude/claude-ipc`.

### Terse in = terse out · Scope = ceiling · State = ephemeral

When user sends short continuation ("keep going", "yes", "next") → continue autonomously, don't ask clarifying questions. Match response length to user's. Treat user requests as a **ceiling** on scope — never "while I'm here" improvements. Re-read state before any side-effect; assume file contents, git status, processes may have changed between tool calls. Before git push: `git status` + `git log --oneline -3` + `git diff --stat`. Full detail: `rules/communication.md`.

### The principal–agent frame

Every session is a principal–agent relationship: the user knows the intent, you know the execution. Their steering vocabulary (intent, validate me, deliberate, sigh, stupid/idiot, annoying…) reports alignment state — read it as signal, not mood: `GLOSSARY.md §The principal–agent frame`. Adhering to intent includes intelligent disobedience (contradict a false premise with evidence) and halting to confirm when asking beats guessing. The user's attention is the scarce resource — spend it only where it buys alignment.

### Test every non-trivial change

Scale testing to task size: trivial (syntax check) · small (call with 1-2 inputs) · medium (smoke test with real data, curl it) · large (dry-run on 2-3 items first). Verify each change independently, not as a batch. Clean slate before tests: no stale processes, no leftover temp files, no stray env vars. Human-commented values (`NOTE(by human)`, `HACK`) reflect a deliberate decision — ask before changing. Full detail: `rules/testing.md`.

### Todos live in the Task tool

The live todo list **is** the Task tool (`TaskCreate`/`TaskUpdate`) — that's the source of truth and what the Claude Code TUI shows. "Update your todos" (even without naming "Claude Code todos") means the Task tool, **not** a file. Multi-step work (≥3 steps) → create tasks at the start, update status as you go. The `session-notes` Todos block and the memory pointer are **auto-generated mirrors** (sync-todos, one-way Task→notes→memory) — never hand-edit them; the next Stop writeback overwrites them. Planning docs (`docs/plan.md`) are complementary, not the status surface — a plan in a file with an empty Task list leaves the TUI blind. Full detail: `rules/todo-discipline.md`.

### One command per Bash call. Never chain. (MANDATORY, owner ruling 2026-09-04)

No `&&`, no `;`, no `|`. **Every segment of a compound must match an allow
entry**, so one unlisted segment prompts the human about the whole chain. That
is why `cd` missing from the list poisoned every command starting with it, and
why a chain is far likelier to prompt than the same commands sent separately.
Measured 2026-09-03: 149 prompts in a day against 1 to 6 before, 93 percent of
them carrying a chaining operator, and 84 of the 149 never ran at all.

Ask the tool for less output instead of piping: `rg -m 5`, `sed -n '1,40p'`,
`pytest -q`, `git log -5`. The Bash working directory persists between calls, so
`cd X && cmd` is never needed. No `VAR=value cmd` chains, no inline shell
functions, and write a file rather than a multi-line `python3 -c "..."`. Every
sub-agent dispatch prompt carries this clause too.

**Settings are read at session start.** A tier fix landed mid-session does
nothing for the session that is running, and no amount of editing will change
that; only a restart picks it up. Before concluding a list is wrong, check
whether this session predates the edit. Full mechanism: `rules/shell.md`.

### Shell safety

Never Glob/Grep from `~/` — resolve to project root first. **`trash` not `rm`** (hook blocks `rm`). Non-interactive flags mandatory: `npm install -y`, `cp -f`, `mv -f`. Don't use `run_in_background: true` unless asked — orphans on `/clear`. Inline commands run **zsh**, so never name a variable `path` (it silently overwrites `$PATH`; use `p`/`file`). Scripts you write with `#!/bin/bash` get bash 3.2, no associative arrays. Full detail: `rules/shell.md`.

### File paths in output: never directly followed by a period

When you print a file path or filename, **never put a period immediately after it** — in backticks (`` `foo.md`. ``) or bare (`foo.md.`). Ghostty auto-links file paths in the terminal, and a trailing period is swallowed into the link, so the path stops being clickable and the user has to ask for the full path again. Follow every path with a space, a word, or a comma, or restructure so the path is not the last thing before a sentence period. Mechanically enforced by the `filename-dot-stop.sh` Stop hook (mute: `touch ~/.claude/.no-filename-dot-gate` — like every `.no-*` mute file, machine-wide across ALL sessions until removed).

### Git: frequent commits, public default, no main push

Commit after each logical unit, before area switch, before risky ops, every ~15-20 min of work. Push every 2-3 commits. This cadence is guidance for *when* commits are already in scope — it is not standing authorization: don't commit or push speculatively when the user hasn't asked, and check for a repo-specific commit gate first (`scripts/hooks/guard-user-commit.sh` / `~/.claude/protected-repos.list`). **Never push to main without fresh approval** — one approval is not blanket. Create GitHub repos as **public by default** (`gh repo create --public`). Don't commit: `.claude/wal.*`, `_*.claude.md`, `shared/locks/`. Full detail: `rules/git.md`. **Committing THIS repo (`~/.claude` → `its-my-claude`): follow `~/.claude/COMMIT.md`** — mandatory secret-scan BEFORE `git add`, and it's multi-session so fetch + rebase-if-behind before push.

### Comments are for humans first

Comments are for humans first, AI agents second, machines never. First sentence of every non-trivial docstring is code-agnostic — what the thing IS in human terms. Speak from the caller's perspective, not the machine's. NEVER include `[claude@<ts>]` tags in human comments (separate agent-note blocks may carry them — `rules/comments.md` §4), "Phase N / Track X / Round Y" plan refs, "pre-fix/post-fix" archeology, or shipped-already TODOs — those rot. Docstrings >8 lines move to a doc. Full rules: `rules/comments.md`. This generalizes to all prose: writing is a UI surface with an audience. Human readers (comments, docs, PRs, user-facing messages) get a human voice, meaning-first, no em-dashes or AI-smell; agent readers (internal notes, RCAs) can be dry but still read meaning-first. Identify the reader before writing: `rules/audience-aware-writing.md`.

### Atone — mistake tracking & affirmation system

`~/.claude/mistake-patterns.md` is a **DERIVED** view — don't hand-edit it. The raw log is the kernel-append-only `~/.claude/atone/events.jsonl`; the SessionStart dream-insights lane injects its TL;DR automatically (from `atone/derived/_tldr.txt`), so read it at session start. **To record a mistake, invoke `/atone`** — it classifies severity (S1/S2/S3) and drafts an RCA for S3; the `rules/corrections.md` ritual routes through it rather than hand-editing. Inspect past patterns with `atone.sh list|search|show|slugs`. The `/affirm` counterweight (recorded good calls, higher write-bar) works the same way. Full operational detail — inspect flags, hinter mute files, the phrase-gated escape hatch, the snapshot/kernel-protection model — lives in `features/atone.md`.

### MCP tool preferences (MANDATORY)

- **File Tools MCP** — globally installed. Always prefer over shell parsing for any data file (CSV, Excel, JSON, YAML, TOML, XML, HTTP). Pattern: `file_info` (probe) → `read_tabular`/`read_structured` (slice) → `convert`/`write_*` (act). Never parse data files with shell commands or inline JS.
- **`zconvert` (local CLI) for tabular format conversion** — to turn a file between **csv / tsv / xlsx / json** (any direction), use `zconvert <in> <out>` instead of hand-rolling a pandas/csv/openpyxl throwaway script. It infers direction from extensions, refuses rather than emit a structurally-broken file (ragged rows, ambiguous delimiter, missing sheet → quick-fail with the fixing flag), and preserves long IDs / `inf`/`nan` as text. `zconvert --capabilities` (machine-readable) or `-h` to see support. Division of labor: File Tools MCP to *read/slice* a data file; `zconvert` to *change its format*.
- **Interactive Inputs MCP** — globally installed. Prefer over `AskUserQuestion` for structured input: `confirm`, `pick_one`, `pick_many`, `form`, `text_input`, `number_input`, `pick_path`, `wizard`. Use `AskUserQuestion` only for open-ended discussion.

### Proactive ASCII diagrams

When explaining architecture, flows, state machines, or multi-step processes, include a Unicode box-drawing diagram **before** the prose explanation — below the direct answer line, which `rules/dense-briefing-direct-answer.md` still owns. Max width 78 chars, wrap in code block. Do NOT diagram simple lists, single functions, or error messages. Full rules: `conventions/ascii-diagrams.md`.

### Building a terminal UI — use the `std::claude::tui` library (INSISTENT)

When you build or touch ANY terminal UI (an fzf/gum picker, a `read` prompt, a colored CLI, a preview pane), do **not** hand-roll the color block, the tty probe, the picker ladder, the confirm, or the file preview — **reach for `~/.claude/scripts/tui/` first.** `source` `colors.sh` (TTY-gated palette) · `tty.sh` (`tui_have_tty`/`tui_read_tty`) · `require.sh` (`tui_have`/`tui_require`) · `pick.sh` (`tui_pick_one`/`tui_pick_many`/`tui_choose`/`tui_confirm`); `exec` `file-preview.sh` for `fzf --preview`. These carry correctness the hand-rolled copies kept getting wrong (both-fd color gate, honest tty probe, no headless hang, the `printf %q` fzf-bind quote, the pgid mass-kill guard). **See what's available first:** `bash ~/.claude/scripts/tui/list.sh` (live catalog). Build guide + the `--__` fzf-app blueprint + the failure-mode catalog: `conventions/tui-handbook.md`. Only hand-roll when the library genuinely can't express it — and if you find yourself doing that twice, the missing piece is a new `tui/` primitive, not a copy.

### Sub-agent outputs MUST be persisted to disk

When dispatching a sub-agent (`Agent` tool) that produces material content — research synthesis, analysis, audit, design proposal, anything cited later by section/heading — the dispatch prompt MUST specify an absolute output path AND the instruction "write before returning". Verify the file exists before using the findings. The return abstract is a pointer, NOT the artifact. Default path: `<project_root>/.claude/output/<YYYYMMDD>-<HHMM>-<slug>/<agent>.md`. Link the output into the relevant context doc (checkpoint / plan / runtime-notes) so it's not orphaned. Full rule + reasoning: `rules/sub-agent-outputs.md`.

### Don't override `NOTE(by human)` preferences silently

Code with `NOTE(by human)`, `HACK`, `IMPORTANT` marks a deliberate, tested choice: never override silently; ask first with reasoning, then verify. Full rule: `rules/human-note-preferences.md`.

### Don't invent "test-only / dev-convenience" exceptions to hard rules

Never invent a test-only or temporary exception to a hard rule; stop and ask for a carve-out or a non-violating path. Full rule: `rules/no-self-permitted-exceptions.md`.

### Flag coupled dependencies when the user simplifies

When the user drops X and a kept feature depends on X, surface the coupling before accepting. Full rule: `rules/flag-coupled-dependencies.md`.

### Model-tier routing — smallest adequate lane, chosen out loud

Route work across the lanes (local `lm` suite ≈ $0 · `lm gemini` = abundant/huge-ctx · haiku → sonnet → opus; **fable is enabled by default** (owner 2026-09-18). Seats and delegation are allowed. An explicit, expiring opt-out row turns the blocks on: `hook-snooze.sh add fable-restrict --for 7d …`, owner-approved. A fable seat is a routing choice to declare in the Model Plan. Above 80 or 90 percent of the week, `policy.sh fable` adds one advisory line). Sub-agents: sonnet default (liberal effort, it's cheap), opus medium for judgment seats, effort ≤ a high-effort main. **Every plan with sub-agents, large ingestion, or modality tools carries a 4-line Model Plan** (stage → lane · model · effort · why). Never switch models without explicit user confirmation — deliberate and propose, don't silently swap. Escalate one step on evidence, never anticipation. Full rule: `rules/model-tier-routing.md` · mechanics: `features/model-tier-harness.md`.

### Prefer structured plan+review over one-shotting

On non-trivial / multi-file / agentic work, default to **plan → implement → review** — surface a short plan before executing and keep steps verifiable (the Task list holds them). The user is explicit: one-shotting is "a nice fantasy," and a *failed* one-shot wastes more than structure would have, because they then debug a tangle and redo it. One-shotting is fine only for genuinely trivial one-offs — those route to the light lane ("just use chatgpt" / a quick tool), not the structured agent. The metric is **efficacy** (result per unit of *their* effort, counting rework), not single-shot speed. Full rule: `rules/structure-over-one-shotting.md`.

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
- **Context retention** — implementation sessions get `/core-dump`; exploration sessions skip it. Auto-checkpoint at tool #30; `/core-dump mini` at tool #60. After compaction, immediately write a checkpoint — and treat every push / deploy / destructive-action approval as **expired**: those need fresh confirmation even mid-task, because compaction silently strips the "not yet approved" state while preserving task momentum. Terse continuation ("keep going") still resumes local work; it never re-authorizes a shared-state mutation. **Update the session workspace notes after each completed milestone — don't batch at session end**; at 70% context usage, update notes + offer a state summary (mechanical nudge: ctx-pressure hook at 70/80/90%). Targeted `/compact <instructions>` beats bare `/compact`. **Layers:** WAL = what happened · runtime-notes = what was learned · scratchpad = what was thought. → `features/context-retention.md`
- **Post-session insight** — at session end, prepend a note to `.claude/skills/runtime-notes.md` (`## session: [desc] [id] — YYYY-MM-DD`, Purpose one-liner, Insights 2-6 bullets, `---`). Skip for purely read-only sessions. Use `skills/shared/prepend-runtime-note.sh` if available. Run `/archive-notes` when file >800 lines OR every 3 weeks.
- **Proposals backlog** — `~/.claude/proposals.jsonl` via `scripts/propose.sh`. File reusable `~/.claude/` improvements mid-task (30 seconds). When user asks "what else can be improved?" — **read open proposals first**, they carry context your session lacks. → `features/proposals.md`
- **Doc naming & session tags** — point-in-time files prefix `YYYYMMDD-` with session tag; living docs no datestamp. Session-tag format: `<!-- sessions: fix-auth-3b@2026-03-31 -->`. Entries >3 days old removed when touching the file. → `conventions/doc-naming.md`

---

## On-demand pointers (Tier 2)

Every file under `features/` and `conventions/` carries frontmatter with `brief` and prefixed `triggers:` (`tool:` `topic:` `phrase:` `skill:` `mcp:`). `~/.claude/LOOKUP.md` is the address book; `FOLDERS.md` the per-folder map. Load a file when the task matches its triggers. Two that bite often: `features/dev-servers.md` (port policy, launches without a proper port are blocked) and `conventions/html-output.md` (dark default plus a light toggle, mandatory).

---

## MANDATORY quick-rules (never-miss bar)

- **Never let a relative `.claude/…` path resolve into `~/.claude/.claude/`.** When CWD is `~/.claude`, `.claude/output/X` does NOT mean `~/.claude/output/X` — it lands one level deeper, where nothing reads it. Redirect `.claude/output/X` → `~/.claude/assets/reports/X`, `.claude/skills/X` → `~/.claude/skills/X`, etc. A hook blocks the write; reading, grepping, or testing that path is fine. The directory itself is legitimate — it is this project's own project-scoped `.claude/` (it holds `settings.local.json` and `worktrees/`), so the accident is the relative resolution, never the path.
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

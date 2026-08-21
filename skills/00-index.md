---
brief: One-line-per-skill retrieval menu (name + invoke mode + gist), DERIVED from each SKILL.md's frontmatter via scripts/skills-index.sh. The search surface for "I half-remember a skill exists".
triggers:
  - topic:skills-index
  - phrase:"which skill"
  - phrase:"is there a skill"
  - skill:pick-skill
related:
  - skills/pick-skill/SKILL.md
  - rules/00-index.md
tier: 2
category: skills
updated: 2026-08-21
stale_after_days: 365
---

# Skills index

One line per skill in `~/.claude/skills/`. Scan or `rg` this menu, then read the
full `skills/<name>/SKILL.md` before invoking. DERIVED from frontmatter;
regenerate with `bash ~/.claude/scripts/skills-index.sh` (fast; run it first,
then read).

The **Invoke** column: `yes` = user `/name` and model auto-invoke both allowed ·
`user-only` = `disable-model-invocation: true`, the user must type it ·
`bg` = `user-invocable: false`, background knowledge, not in the `/` menu.

Regenerated 2026-08-21 15:53.

| Skill | Invoke | Gist |
|-------|--------|------|
| `adversarial-review` | user-only | Prosecutes work already declared done — re-runs the verification paths the author skipped, cross-examines every done/works/tested claim against executed evidence, and … |
| `affirm` | yes | Records an affirmed-good behavior — non-obvious approach the user explicitly approved. Sibling of /atone. Higher write bar than atone (only fires for genuinely … |
| `arch-qa` | yes | Answers technical architecture questions by tracing code paths through the codebase — analyzing feature implementations, data flows, auth middleware, and service … |
| `archive-notes` | yes | Archives old runtime-notes entries beyond a threshold to a dated archive file, keeping the active notes file lean. Accepts a project path argument. |
| `atone` | yes | Records a mistake — gathers context, classifies severity (S1/S2/S3), and writes a structured entry to ~/.claude/atone/events.jsonl. For S3 events, also drafts an RCA … |
| `autocorrect` | yes | Manage the autocorrect typo-correction dictionaries — view/edit mappings, review correction logs, teach new corrections, and check stats. Use to inspect or tune the … |
| `backlog-triage` | yes | Review the triaged gcc improvement backlog and act on it. Reads the ranked triage file produced by backlog-consolidate.py (PROMOTE / WATCH / DROP-REVIEW), presents the … |
| `banner` | yes | Generates a customized terminal banner by prompting for title, sections, and theme — renders using std::claude::shared banner.py with guaranteed alignment. |
| `banner-fun` | yes | Render a daily fun terminal banner with weather, quote, moon phase, and code riddle. Use for the daily fun banner — not dev metrics, which live in the statusline. |
| `bloop` | yes | Drives a non-trivial build task through six stages — plan, build, review, validate, fix, docs — with an adversarial sub-agent validation gate that independently tries to … |
| `build-change` | yes | Plans a non-UI change and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the change, states problems … |
| `build-ui` | yes | Plans a page-level UI build or renovation and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the … |
| `callouts` | yes | Persists the owner's review findings as re-runnable acceptance rows per surface, and gates any later "done" claim on re-running the open rows. Use when the owner calls … |
| `capabilities` | yes | Generates a report of everything this Claude instance can do — skills, hooks, MCP servers, memory, runtime architecture, widgets, and all std::claude infrastructure. |
| `catchup` | yes | Resumes a session from a /core-dump checkpoint. Resolves via the ~/.claude/checkpoints/ index (picker when ambiguous) or a named _checkpoint.claude.md, loads only … |
| `cleanup-comments` | yes | Prune, simplify, and remove low-value comments in changed code (or a path you pass) per the repo comment-style rubric. Strips [claude@] tags, plan refs … |
| `cogitate` | yes | Use when the user wants to research a topic and keep a durable, growing note on it — answers a query and files a dated structured response under … |
| `context-prime` | user-only | Loads project index, gotchas, recent git log, and open issues into context at the start of a session — bootstrapping Claude's awareness without any manual prompting. |
| `core-dump` | yes | Writes _checkpoint.claude.md (or a named file) condensing the session into goal, actions, expectation, and pending items; "mini" mode for quick notes. Indexes a … |
| `create-agent` | yes | Scaffolds an autonomous agent SKILL.md (context: fork, no prompts, structured output) from instructions, or converts an existing skill to agent form, after reading the … |
| `create-report` | yes | Takes a markdown file and generates a polished, self-contained HTML report with a clean UI. Supports 13 visual styles (default, notion, dashboard, magazine, terminal, … |
| `create-skill` | yes | Turns a skill idea (a spec, intent, or checklist answers) into a finished SKILL.md with a tailored validation rubric and ledger steps, reviewed by a fresh seat for … |
| `deadline` | yes | Run work against a hard deadline while spending the user's scarce return visits as the true currency — one front-loaded decision exchange, reversible-default autonomy … |
| `decision-wizard` | yes | Collect a batch of human decisions with near-zero human effort. When you are about to ask the user more than ~3 related judgments — a design review, a migration … |
| `deck` | yes | Turns a source document (or the conversation) into one self-contained HTML slide deck with a synced presenter-notes window, verifies that no slide overflows by measuring … |
| `deep-research` | yes | Answers a question that needs evidence from outside this machine, by splitting it into claims, researching each in parallel, verifying the load-bearing ones against … |
| `describe` | yes | Analyzes a named Claude skill, MCP server, plugin, or custom feature in depth — reads its prompt, code, and runtime notes, then generates a terminal-style HTML report … |
| `designer-reviewer` | user-only | Reviews UI screenshots against the user's terminal-dashboard aesthetic fingerprints. Gives scored critiques with actionable CSS fixes. Use when reviewing pm2-manage, … |
| `diagram` | yes | Renders terminal diagrams — flowcharts, sequence diagrams, trees, tables, state machines, and architecture layouts — using gum-tui.sh for box-accurate rendering. Use … |
| `doctor` | yes | On-demand environment health check — worktrees, pm2 status, disk, WAL staleness, git dirtiness, plus hook/event-log integrity. Use when the user asks "what's wrong", … |
| `file-gh-issue` | yes | File a MINOR technical issue to the current repo's GitHub Issues, with a human gate. Dry-run by default. Use when an agent surfaces a small technical cleanup worth … |
| `gated-plan` | yes | The planning process for owner-gated work, meaning anything that cannot correctly proceed until a human decides. Investigates until it can falsify its own proposal, … |
| `gcc-explore` | yes | Sit down with the gcc and look around. Renders the config as three panels (SHAPE, what it is; MOVEMENT, which way it is drifting; CYCLE, the loops keeping it alive) from … |
| `gcc-map` | user-only | Maps how instruction content actually loads into an agent and the CLAUDE.md doc graph, measuring ground truth first and diffing it against what the indices claim, then … |
| `gcc-proposal` | yes | Files a ~/.claude improvement proposal into the backlog via propose.sh — derives the title, category, effort, and cross-links from a rough description or from the … |
| `generate-image` | yes | Generates raster images from a text prompt using the LOCAL imagine model (mflux/MLX Flux on Apple Silicon — $0, offline, no cloud). Uses only models already cached on … |
| `generate-pdf` | yes | Converts a markdown file to a styled PDF with 4 style variants (default, professional, academic, compact), optional cover page, TOC generation, and landscape mode. … |
| `git-setup` | yes | Initializes, audits, and maintains git repositories — sets up .gitignore, branch protection, conventional commits, PR templates, and runs health checks on existing repos. |
| `gotchas-update` | yes | Appends a new dated entry to gotchas.md after a bug fix, architectural discovery, or lesson learned — keeping the project's developer pitfall log current. |
| `improve-config` | yes | Audits the project's .claude/ directory (or ~/.claude/ for global config) using /user-config context to catalogue instructions and skill patterns, produces a prioritized … |
| `improve-skill` | yes | Audits skills against the house rules and their run history (runtime notes incl. archives, skill-log outcomes, their own Validation rubric), applies approved fixes, and … |
| `intake` | yes | Models a request before work starts, restating it as goal, scope ceiling, register, and what the wording exemplifies versus specifies, with one line back when readings … |
| `ipc` | yes | Work the claude-ipc fabric from any session. Who's live, what's owed, send/reply with the safety rails, triage an inherited or orphaned mailbox, and first-line broker … |
| `kanban` | yes | Drives the agent-populated kanban board — inits a board for the current project, re-syncs cards from docs/checkpoints/session-notes, pulls the human's unread card notes, … |
| `magi` | yes | Multi-agent supervisor-led deliberation. DEFAULTS TO --mode lite (3 voters, no personas/jester/voting, ~$3-8/run with research on) for routine tradeoffs. Opt into --mode … |
| `migrate` | yes | Create a migration entry for a structural change to ~/.claude/. Required before/alongside any change that moves a canonical path, renames a script other things … |
| `mini` | yes | Fast mini-model query (<1s) using local Ollama or cloud Haiku — for quick lookups, titles, summaries, and command composition |
| `new-migration` | user-only | Generates a Drizzle ORM migration from a plain-English schema change description — updates the schema file and runs db:generate to produce the SQL migration. … |
| `past-sessions` | yes | Browse, search, and summarize past Claude Code conversation transcripts from ~/.claude/projects/. Use when the user asks "what did we do last time", "find the session … |
| `persona` | yes | Adopt a working-mode persona (~/.claude/personas/) for the current task — pick by name or let the skill match one, load its role contract into context, and record the … |
| `pick-skill` | yes | The front door when the right instrument is not obvious. Two jobs. Retrieval, for "I half-remember a skill exists", answered with a ranked shortlist you pick from by … |
| `pin-for-dream` | yes | Pin a structured insight from the current Claude Code session for i-dream's next dream cycle to examine. Auto-gathers session context (cwd, recent files touched, … |
| `plan` | yes | Routes a planning request to the instrument that fits it, by naming which of six needs the request actually has, and refuses to plan a change to something that already … |
| `plugs` | yes | Show what context-injecting and learning-capturing "plugs" are wired into the session (start / per-turn / compact / end) — what's registered, what's muted, and the … |
| `pr-description` | yes | Write a PR description that briefs the reviewer in the author's voice: content-model-first. Extracts the behavioral inventory from the ACTUAL diff (never commit … |
| `preference-graduation` | user-only | Harvests recurring preference and vocabulary signals from the post-insight streams (atone, affirm, i-dream, runtime-notes, checkpoints), dedupes them against existing … |
| `probe` | yes | Drives a defect to its confirmed mechanism before any fix: a runnable probe isolates the one unknown, the harness is ruled out first, and a second fix attempt on the … |
| `project-index` | yes | Scans the project structure, key files, dependencies, and architectural patterns — generates a comprehensive index markdown and optional HTML report. Runs in an isolated … |
| `pyramid-sweep` | yes | Runs a pyramid-of-intelligence corpus sweep — mine a large transcript corpus for candidate items with cheap mechanical passes, then refine through progressively smarter … |
| `readme` | yes | Scans a git repo's structure, docs, package metadata, and prior skill reports — generates a polished README.md with GitHub-style badges, a pixel-art cover image, a … |
| `retro-dump` | yes | Manually trigger a retroactive /core-dump on a past session that ended without one. Headless — spawns `claude -p --resume <uuid>` to read the transcript and synthesize a … |
| `revive` | yes | Lists Claude Code session transcripts under ~/.claude/projects/, cross-references with the checkpoint index, presents a picker, and prints the exact `claude --resume … |
| `roster-budget` | yes | Measures the skill roster against its listing budget and names the skills whose descriptions are being dropped, ranked by what each long description costs. Use when a … |
| `scan-sessions` | yes | Deep-scan past Claude Code sessions for patterns, frustration signals, and improvement opportunities |
| `session-stats` | yes | Full session analytics report — cost, tokens, tools, rate limits, context usage, and activity timeline |
| `shell-mem` | yes | Look up recent shell commands, background process history, or mark background processes as done. Use when asked about recent commands, what's running, shell history, or … |
| `skeptical-review` | yes | Skeptically reviews the code changed this session by forking a fresh adversarial reviewer that grounds every finding in the actual tree — surrounding context, sibling … |
| `statusline` | yes | (no description; add frontmatter) |
| `statusline-config` | user-only | Interactively toggle statusline segments and profiles |
| `ste-writing` | yes | Rewrite prose into Simplified Technical English adapted to this account. Covers docs, READMEs, PR descriptions and their inventories, error messages, release notes, … |
| `summarize-changes` | yes | Generates a categorized changelog of recent work, scoped by three orthogonal axes (time / topic / source) and rendered in a user-selected format. Treats git as ONE … |
| `svg` | yes | Authors, edits, optimizes, and render-checks SVG graphics — icons, logos, diagrams, illustrations, patterns. Claude writes the SVG markup directly (no image-gen … |
| `tag` | user-only | Captures something worth keeping (a rule, convention, feature doc, glossary term, code snapshot, or note) and files it into the ~/.claude global config at its correct … |
| `tasks` | yes | Show the current task list as ONE grouped, tagged, sequenced table (project's ruled key; width free, height within 44 lines). Also the write path when the harness has no … |
| `test` | yes | Run tests for the current folder using a cached per-folder framework detection. First run probes the folder for pyproject.toml/package.json/Cargo.toml/go.mod etc and … |
| `thesaurus` | yes | Ten-second capture of a style verdict into the style thesaurus — the ledger of how the user wants Claude to write (word choice, comments, prose, report structure). … |
| `ui` | yes | Routes a UI request to the one instrument that fits it, and refuses to start until an existing surface has a written capability list. The account holds a whole cluster … |
| `ui-categorical-check` | yes | Checks a UI change for CATEGORICAL bug-classes — the non-primitive defects that pass every DOM/behavioral assertion and only a human notices (a transparent floating … |
| `ui-direction` | yes | Finds and rules on a visual direction before anyone plans or builds. Grounds the work in a cited research sheet that reads the owner's rejection record FIRST, runs the … |
| `ui-gripe` | yes | Diagnoses WHY a UI feels stupid, confusing, or frustrating — runs the local see --ui structural inventory as $0 ground truth, then a native-vision judgment pass to name … |
| `user-config` | yes | Lists and manages all Claude configuration in this project — guidelines, skill definitions, personal settings, and shared utilities. Use /user-config to view config or … |
| `validate` | yes | Routes a finished or nearly-finished change to the checks it actually needs, by first naming every validation question the change raises and then saying which instrument … |
| `vis-compare` | yes | Judges whether a recreated image faithfully imitates a reference — runs the local `see diff A B` deterministic evidence pack (text/color/hash/shape, zero-cost, … |
| `visual-regression` | yes | Captures baseline screenshots via Playwright MCP and compares against later snapshots to detect visual regressions — pixel-diff reports with highlighted change regions. |
| `wake` | user-only | Arm an opt-in wake monitor that revives THIS session if an outage leaves it alive-but-idle. A turn killed by a transient API error stops dead until a human types "keep … |
| `web-design` | yes | Reviews, generates, and systematizes web UI designs — screenshot-based critique with actionable CSS fixes, design token extraction, and page layout generation with … |
| `word-doc` | yes | Turns a markdown file, notes, or the conversation into a .docx that reads well in Word and Google Docs, planning the structure from the content and rendering the house … |
| `workspace` | yes | Manage per-session workspace docs at <project>/.claude/session-notes/<session-id>.md. Each serious session has its own Todos, Notes, Doc Links, and Decisions file that … |
| `write-docs` | yes | Scans a codebase to generate focused technical documentation — API references, guides, ADRs, changelogs, or onboarding docs — with anti-fluff voice calibration. |

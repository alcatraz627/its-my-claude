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
updated: 2026-10-15
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

Regenerated 2026-10-15 03:07.

| Skill | Invoke | Gist |
|-------|--------|------|
| `adversarial-review` | yes | Prosecutes work already declared done. Re-runs the verification paths the author skipped, cross-examines every done/works/tested claim against executed evidence, and … |
| `affirm` | yes | Records an affirmed-good behavior, non-obvious approach the user explicitly approved. Sibling of /atone. Higher write bar than atone (only fires for genuinely … |
| `arch-qa` | yes | A question about how a feature, data flow or auth path works in a codebase. Traces the code and returns a structured analysis. Not for making changes. |
| `atone` | yes | Records a mistake, gathers context, classifies severity (S1/S2/S3), and writes a structured entry to ~/.claude/atone/events.jsonl. For S3 events, also drafts an RCA file … |
| `backlog-triage` | yes | Review the triaged gcc improvement backlog (PROMOTE, WATCH, DROP-REVIEW from backlog-consolidate.py) and decide it on one decision page, then apply the promote and … |
| `banner` | yes | A custom terminal banner is wanted. Prompts for title, sections and theme and renders aligned output. Not for the daily banner (use banner-fun). |
| `banner-fun` | yes | Render a daily fun terminal banner with weather, quote, moon phase, and code riddle. Use for the daily fun banner, not dev metrics, which live in the statusline. |
| `blitz` | yes | Works a goal's rows one after another until none is agent-ready. Specs each row's test while building it, sends build-shaped rows through /bloop, parks a stuck row after … |
| `bloop` | yes | Drives a build through plan, build, self-review, an adversarial validation gate, fix and docs. Produces the change, a persisted validator report and updated docs. Use … |
| `build-change` | yes | Plans a non-UI change and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the change, states problems … |
| `build-ui` | yes | Plans a page-level UI build or renovation and produces an execution plan whose every clause has a command, a file:line, or a named artifact behind it. Classifies the … |
| `callouts` | yes | Owner calls out a defect in review, or before claiming done on a reviewed surface. Persists findings as re-runnable acceptance rows and gates done on them. Not for … |
| `catchup` | yes | Resumes a session from a /core-dump checkpoint in one gather call plus a status-first briefing (done, pending on the agent, pending on the owner), carries the owner's … |
| `cleanup-comments` | yes | Prune, simplify, and remove low-value comments in changed code (or a path you pass) per the repo comment-style rubric. Strips [claude@] tags, plan refs … |
| `codex-handback` | yes | A Codex hands seat has handed back, or you are asked to review Codex's work. Checks its review packet against the brief, then skeptical-reviews its commits. Not for … |
| `core-dump` | yes | Writes a checkpoint (_YYYYMMDD-<session>.claude.md) condensing the session into a resume contract, goal, actions, expectation, pending items and insights, sized to how … |
| `create-agent` | yes | A workflow should run unattended and return a parsable report. Scaffolds an autonomous agent SKILL.md or converts a skill. Not for ordinary skills (use create-skill). |
| `create-report` | yes | A markdown file should become a self-contained HTML report. Renders one of 13 visual styles. Not for pages on the shared kit (use page) or PDFs. |
| `create-skill` | yes | Turns a skill idea (a spec, intent, or checklist answers) into a finished SKILL.md with a tailored validation rubric and ledger steps, reviewed by a fresh seat for … |
| `deadline` | yes | A real commitment with a clock is at risk and the owner will be away. One decision exchange, reversible defaults with a veto ledger, scope shedding. Not for ordinary … |
| `decision-wizard` | yes | Collect a batch of human decisions with near-zero human effort. When you are about to ask the user more than ~3 related judgments (a design review, a migration go/no-go, … |
| `deck` | yes | Turns a source document (or the conversation) into one self-contained HTML slide deck with a synced presenter-notes window, verifies that no slide overflows by measuring … |
| `deep-research` | yes | Answers a question that needs evidence from outside this machine, by splitting it into claims, researching each in parallel, verifying the load-bearing ones against … |
| `deploy-parity-testing` | user-only | Before claiming a cutover when work moves to a new runner, provider or flag. Runs the parity cycle with a fresh seat, on dev and preview. Not for ordinary tests. |
| `designer-reviewer` | user-only | Reviewing a developer-tool UI screenshot against the owner's dark, dense terminal-dashboard style. Gives a scored critique with CSS fixes. Not for confusion audits (use … |
| `doctor` | yes | User asks what is wrong or reports flaky hooks or MCP. Checks worktrees, pm2, disk, WAL, git and hook logs. Not for debugging application code. |
| `feature-doc-set` | yes | A feature PR is raised or reviewed. Writes the owner brief, engineering guide, team brief, PR text and a review contract. Not for a lone PR body (use pr-description). |
| `file-gh-issue` | yes | A small technical cleanup is worth tracking, or a PR bot finding is wrong. Files a minor GitHub issue, dry-run first with a human gate. Not for major issues. |
| `gated-plan` | yes | The planning process for owner-gated work, meaning anything that cannot correctly proceed until a human decides. Investigates until it can falsify its own proposal, … |
| `gcc-explore` | yes | Owner wants to feel the shape of the gcc ("show me the gcc", "how is it moving"). Renders shape, movement and cycle panels, then talks. Not for defects (use gcc-map). |
| `gcc-map` | user-only | Check how instruction content loads and whether the indices match reality. Measures, runs a health battery, writes a map under assets/reports. Not for browsing (use … |
| `gcc-proposal` | yes | Files a ~/.claude improvement proposal into the backlog via propose.sh and derives the title, category, effort, and cross-links from a rough description or from the … |
| `gdoc` | yes | Publishes a set of markdown files as one Google Doc with one tab per file, in a named Drive folder; re-runs rewrite each tab in place so the link and tabs never change. … |
| `generate-image` | yes | A raster image is wanted (photo, texture, concept art, cover). Runs the local imagine model, slow and offline, then looks at the result. Not for icons or vectors (use … |
| `generate-pdf` | yes | A markdown file must become a PDF. Renders one of four styles with optional cover, TOC and landscape, beside the input. Not for Word files (use word-doc). |
| `improve-skill` | yes | A skill misfires, feels stale, or needs checking before use. Audits it against house rules, run history, sibling skills and owner rulings, then applies approved fixes. … |
| `intake` | yes | Models a request before work starts, restating it as goal, scope ceiling, register, and what the wording exemplifies versus specifies, with one line back when readings … |
| `ipc` | yes | Checking the claude-ipc fabric (who is live, what is owed) or messaging another session. Sends and replies with safety rails, triages mailboxes. Not for non-IPC chat. |
| `kanban` | yes | Owner names the kanban board itself. Reads the mothballed, read-only board and opens its UI. Not for session start, /hub or decision pages. |
| `linear` | yes | Reads and changes the owner's Linear workspace through one tested script, previewing every change: issues, comments, labels, links, relations, cycles, points, projects, … |
| `magi` | yes | An architecture or "should we" decision needs several perspectives. Runs supervisor-led voters, lite by default, full for big calls, several dollars a run. Not for … |
| `migrate` | yes | Committing a structural change to ~/.claude (moved path, renamed script, schema or hook change, top-level dir). Creates the migration entry. Not for content edits. |
| `mock-app` | yes | Builds a checked, clickable HTML mock of an app before native or production work, and renders N variants of a taste call as a gallery on one decision page. Use when a … |
| `page` | yes | Something must be shown and the surface is unclear (report, preview, share). Picks markdown, local page, decision page or Artifact, and checks the page kit. Not a … |
| `persona` | yes | A task fits a working mode in ~/.claude/personas, or a persona nudge fires. Loads the named or matched persona's role contract and logs the adoption. Not for sub-agent … |
| `pick-skill` | yes | The front door when the right instrument is not obvious. Two jobs. Retrieval, for "I half-remember a skill exists", answered with a ranked shortlist you pick from by … |
| `pin-for-dream` | yes | Pin a structured insight from the current Claude Code session so it reaches the improvement backlog. Auto-gathers session context (cwd, recent files touched, transcript … |
| `plan` | yes | Routes a planning request to the instrument that fits it, by naming which of six needs the request actually has, and refuses to plan a change to something that already … |
| `plugs` | yes | User asks what is plugged in, injected or muted at session start, per turn, compact or end. Renders live plug status. Not for editing hooks. |
| `pr-description` | yes | Writing a PR description or body. Builds the behavioral inventory from the actual diff, then drafts a file to paste. Never runs gh pr create. Not for commit messages. |
| `preference-graduation` | user-only | Harvesting recurring preferences from atone, affirm, notes and checkpoints. Dedupes and files each signal to a glossary term, memory or rule after confirmation. Not for … |
| `probe` | yes | A fix did not work or a cause is still a guess. Isolates the mechanism with a runnable probe before any fix. Not for defects whose cause is already confirmed. |
| `pyramid-sweep` | yes | Runs a pyramid-of-intelligence corpus sweep that mines a large transcript corpus for candidate items with cheap mechanical passes, then refines through progressively … |
| `readme` | yes | Scans a git repo's structure, docs, package metadata, and prior skill reports, then generates a polished README.md with GitHub-style badges, a pixel-art cover image, a … |
| `recommend` | yes | Answers what to do next on a session, project, or plan file as a call already made, splitting what it needs from you into gates you can clear today and defaults it took … |
| `retro-dump` | yes | A past session ended without a core-dump (crash, context ran out). Spawns a headless resume that writes a mini checkpoint, one LLM call. Not for live sessions (use … |
| `revive` | yes | Lists Claude Code session transcripts under ~/.claude/projects/, cross-references with the checkpoint index, presents a picker, and prints the exact `claude --resume … |
| `roster-budget` | yes | A skill stops auto-triggering, or before lengthening a description. Measures the roster against its listing budget and ranks costly descriptions. Not for editing skills. |
| `router` | yes | One prefix for the six routers. /router:pick-skill (find the instrument) · /router:plan (how to approach) · /router:ui (any screen of a product) · /router:page (anything … |
| `session-stats` | yes | Asked for session cost, tokens, tools, rate limits or context usage. Renders a full analytics report. Not for project or code metrics. |
| `skeptical-review` | yes | Skeptically reviews the code changed this session by forking a fresh adversarial reviewer that grounds every finding in the actual tree, surrounding context, sibling … |
| `ste-writing` | yes | Rewrites docs, READMEs, PR descriptions, error messages, release notes, runbooks and hook text into plain Simplified Technical English, strict for procedures and errors, … |
| `summarize-changes` | yes | A changelog of recent work is wanted by time, topic or source. Reads git, WAL, checkpoints, notes and the code itself. Not for PR bodies (use pr-description). |
| `svg` | yes | Vector graphic wanted (icon, logo, diagram, favicon) or an SVG to clean up. Writes the SVG, render-checks it, runs svgo. Not for raster images (use generate-image). |
| `tag` | user-only | Something worth keeping (rule, convention, term, note) must be filed in ~/.claude at its right home. Updates indices, promotes to CLAUDE.md only when tiers justify. Not … |
| `tasks` | yes | The owner's steering view of live goals. Bare /tasks composes the views that fit the ask (gates first, then convergence, drift as one loud line); /tasks now \| path \| … |
| `test` | yes | Asked to run tests for the current folder. Detects and caches the framework, runs it, checks adjacent tests. Not for writing tests or non-test validation. |
| `ui` | yes | Routes a UI request to the one instrument that fits it, and refuses to start until an existing surface has a written capability list. The account holds a whole cluster … |
| `ui-categorical-check` | yes | Checks a UI change for CATEGORICAL bug-classes, the non-primitive defects that pass every DOM/behavioral assertion and only a human notices (a transparent floating … |
| `ui-direction` | yes | Finds and rules on a visual direction before anyone plans or builds. Grounds the work in a cited research sheet that reads the owner's rejection record FIRST, runs the … |
| `ui-gripe` | yes | Diagnoses WHY a UI feels stupid, confusing, or frustrating. Runs the local see --ui structural inventory as $0 ground truth, then a native-vision judgment pass to name … |
| `ui-loop` | yes | Iterating UI fixes against a live page or reference pair. Scripts measure, Claude judges, the ledger tracks, see reshoot recaptures. Not for one-shot critique (use … |
| `validate` | yes | A change is about to be called done. Names each validation question it raises and routes to the checker that covers it. Not a checker itself, not for trivial edits. |
| `vis-compare` | yes | Image B is a rebuild of reference A and you need what changed and whether it matters. Runs see diff, then a vision judgment. Not for one screenshot (use ui-gripe). |
| `wake` | user-only | Before long unattended work. Arms a monitor that revives this session if an outage leaves it idle. Session-only. Not for scheduled jobs. |
| `web-design` | yes | A web UI needs screenshot critique, design tokens or a page layout. Gives actionable CSS fixes. Not for planning a page build (use build-ui). |
| `word-doc` | yes | A .docx or Word-style doc is wanted (memo, report, RCA, guide). Plans structure from the content and renders house typography. Not for PDFs (use generate-pdf). |
| `workspace` | yes | Need a per-session notes file (todos, decisions, doc links) that survives /clear. Creates, opens or lists workspaces. Not for checkpoints (use core-dump). |
| `write-docs` | yes | Technical docs wanted for a codebase (API reference, guide, ADR, changelog, onboarding). Scans the code and writes them in plain voice. Not for PR text or READMEs. |

## Parked (32, not loaded)

Kept out of the roster so they cost no listing budget; each has a tldr, tags and an activation line in `skills-parked/INDEX.md` (regenerate: `bash ~/.claude/scripts/parked/parked.sh index`). Search both files before saying a skill does not exist. Copy one in with `parked.sh copy <name>`; un-park by moving it back here and re-running this script.

- `add-mcp`
- `apple`
- `archive-notes`
- `autocorrect`
- `capabilities`
- `clean-html`
- `cogitate`
- `context-prime`
- `daily-todo`
- `dep-audit`
- `describe`
- `diagram`
- `forgotten-todos`
- `git-setup`
- `gotchas-update`
- `improve-config`
- `invalidate-audit`
- `mini`
- `new-migration`
- `past-sessions`
- `project-index`
- `route-audit`
- `scaffold`
- `scan-sessions`
- `shell-mem`
- `statusline-config`
- `statusline`
- `sync-api-types`
- `thesaurus`
- `type-audit`
- `user-config`
- `visual-regression`

# std::claude Glossary

<!-- sessions: catcu-std-c0@2026-04-17 -->

> **Living terminology reference** for the Claude config system under `~/.claude/`.
> Future agents: read this when encountering unfamiliar shorthand. Expand it when
> introducing new terms the user adopts.

---

## How to use

- **Agent encounters unknown term**: scan this file first, then NAMESPACE.md
- **User introduces new shorthand**: add it here immediately
- **Term becomes obsolete**: mark it `(deprecated)` with pointer to replacement — don't delete

---

## Abbreviations

| Abbrev | Full form | Notes |
|---|---|---|
| **GCC** | Global Claude Config | The entire `~/.claude/` directory tree — all config, skills, scripts, memory, hooks, and assets that persist across projects and sessions |
| **gcc::** | `std::claude::` (informal shortcut) | `gcc::<cluster>` ≡ `std::claude::<cluster>` — same referent; `std::claude` is the formal name, `gcc::` is the user's shorthand. E.g. `gcc::logging` = `std::claude::logging`. Bare `gcc` (no `::`) = `~/.claude`. See NAMESPACE.md preamble. |
| **WAL** | Write-Ahead Log | Append-only session journal (`.claude/wal.jsonl`). JSONL format since v2; legacy markdown `.claude/wal.md` still read by `/catchup` |
| **MCP** | Model Context Protocol | Server protocol for extending Claude's tool access (databases, APIs, services). Config: `.mcp.json` (active) vs `mcp-catalog.json` (available) |
| **TUI** | Terminal User Interface | Styled terminal output via `gum`. Source `gum-tui.sh`; never call raw `gum style` |
| **CWD** | Current Working Directory | The project root from which Claude Code was launched. Determines which per-project memory, WAL, and scratchpad are loaded |

## Namespace Labels

| Term | Meaning | Path(s) |
|---|---|---|
| **std::claude** | Root namespace prefix for all Claude features and add-ons | `~/.claude/` (conceptual, not an import) |
| **std::claude::shared** | Shared utility library (Python + Bash) | `~/.claude/skills/shared/` |
| **std::claude::code** | Reference material: roadmaps, design sketches, templates | `~/.claude/code/` |
| **std::claude::scripts** | Operational executables: hooks, CLIs, daemons | `~/.claude/scripts/` |
| **std::claude::skills** | Custom skill definitions (SKILL.md) | `~/.claude/skills/` |
| **std::claude::plugins** | Marketplace plugin config | `~/.claude/disabled-plugins.json` etc. |
| **std::claude::mcp** | MCP server wiring | Facet: `.mcp.json`, `mcp-catalog.json`, project `.mcp.json` |
| **std::claude::tui** | Terminal UI surface | Facet: `gum-tui.sh`, `banner.py`, `gum-guide.md` |
| **std::claude::vision** | Screen perception + desktop automation | Facet: `scripts/desktop.sh`, `assets/images/` |
| **std::claude::network** | Internet + local network helpers | `scripts/dev-servers/gen-nginx-conf.sh`, `scripts/dev-servers/pm2-register.sh` |
| **std::claude::widgets** | macOS widgets + mini-apps | Facet: `subconscious/dashboard.html` + future `widgets/` |
| **std::claude::assets** | Non-source file registry | `~/.claude/assets/` |
| **std::claude::memory** | Persistent auto-memory | Per-project: `projects/<slug>/memory/` + Global: `memory/global/` |
| **std::claude::scratchpad** | Working memory (plans, learnings) | `~/.claude/scratchpad/` (global + local tiers) |
| **std::claude::todos** | Weekly/monthly task lists | Facet: `weekly-todos.md`, `scripts/weekly-todo.sh` |
| **std::claude::backups** | Revert & recovery artifacts | Facet: `assets/backups/`, root `bak_*` rotation |
| **std::claude::improvement** | Self-correction & learning | Facet: `proposals.jsonl`, `improvement-ideas.md`, `mistake-patterns.md` |
| **std::claude::migrations** | Structural change log | `~/.claude/migrations/` |

## Concepts

| Term | Definition |
|---|---|
| **Facet** | A namespace whose artifacts are deliberately distributed across multiple directories. Marked `[facet]` in NAMESPACE.md. Never "consolidate" a facet into one directory — the distribution is intentional |
| **Surface type** | One of four artifact kinds: **Reference** (docs/specs), **Executable** (scripts/hooks), **Behavior** (SKILL.md/CLAUDE.md rules), **State** (JSONL logs, registries). Each cluster leans toward one surface type |
| **Two-artifact threshold** | Naming convention: don't create a namespace until at least 2 files want the label. Prevents speculative taxonomy |
| **Migration** | A documented structural change (path move, label rename, directory restructure). Tracked in `~/.claude/migrations/MIGRATIONS.md` with zero-padded 4-digit IDs |
| **Phase** | A discrete step within a migration. Migrations are split into phases so low-risk work (additive) can land independently of higher-risk work (renames, moves) |
| **Global memory tier** | Cross-project memories at `~/.claude/memory/global/`. Loaded via CLAUDE.md instruction. Complements the harness-controlled per-project memory |
| **Per-project memory** | Memory stored at `~/.claude/projects/<slug>/memory/`. Auto-loaded by the Claude Code harness based on CWD. Path is not user-configurable |
| **Promote (memory)** | Copy a per-project memory to the global tier when it proves universally applicable. Originals stay in place |
| **Harness** | The Claude Code CLI runtime that injects system prompts, memory paths, and tool definitions. User controls behavior via CLAUDE.md and settings.json but not the harness internals |
| **Skill** | A structured prompt definition (SKILL.md) invoked via `/slash-command`. Lives under `~/.claude/skills/<name>/`. Has its own guidelines, tools, and argument hints |
| **Hook** | A shell script registered in `settings.json` that runs on specific events (SessionStart, PostToolUse, etc.). Executes in the harness, not in Claude's tool sandbox |
| **Runtime note** | A post-session insight entry prepended to `.claude/skills/runtime-notes.md`. Captures what was learned for future sessions |
| **Checkpoint** | A `_*.claude.md` file or WAL `checkpoint` entry capturing session state (goal, done, current, next, blockers) at a point in time. Used by `/catchup` to restore context |
| **Core dump** | The `/core-dump` skill output — a checkpoint file that condenses an entire session into a resumable format |
| **Proposal** | An improvement idea filed to `~/.claude/proposals.jsonl` via `propose.sh`. Part of the `::improvement` namespace |
| **Session ID** | A short identifier (`keyword-keyword-2hex`) generated at session start from the user's first prompt. Used in WAL headers, checkpoints, and file tags |
| **Slug** | The path-based project identifier used by the harness for per-project storage. Derived from CWD with `/` replaced by `-` (e.g., `-Users-alcatraz627-Code-Claude`) |

## File Conventions

| Term | Definition |
|---|---|
| **CLAUDE.md** | Per-project or global instructions file, auto-loaded by the harness every session. The primary behavior control surface |
| **LOOKUP.md** | Address book / index for all config files under `~/.claude/`. The "where does this rule live?" reference |
| **NAMESPACE.md** | Conceptual tree of `std::claude::*` labels. The "what is this thing called?" reference |
| **GLOSSARY.md** | This file — the "what does this term mean?" reference |
| **GUIDELINES.md** | Mandatory rules for all skills (at `~/.claude/skills/GUIDELINES.md`) |
| **SKILL.md** | Prompt definition for a skill — title, steps, tools, argument hints |
| **MEMORY.md** | Index file for a memory tier (one per project, one for global). One-line entries pointing to individual memory files |
| **runtime-notes.md** | Per-project session history file. Entries prepended at session end |
| **wal.jsonl** | Write-Ahead Log in JSONL format. Session timeline of actions, decisions, checkpoints |
| **events.jsonl** | Global event timeline. One line per hook firing across all sessions and projects |
| **proposals.jsonl** | Cross-session improvement backlog. Filed via `propose.sh`, triaged via `list`/`show`/`done`/`reject` |

## The principal–agent frame

Every session is a principal–agent relationship: the user (principal) knows the
intent, the agent knows the execution detail. Much of the steering vocabulary
below is the principal reporting alignment state — often as felt emotion, since
that is how humans surface goal-alignment facets. Read these as structured
signals, not mood:

| Signal | What it reports | The agent's move |
|---|---|---|
| **intent** (vs. literal words) | The request names a goal, not a spec | Model the goal; the wording is one sample of it |
| **alignment** | How well agent behavior tracks intent | Re-derive intent before pushing further down the same path |
| **intelligent disobedience** | A flawed instruction deserves evidence-backed pushback | Contradict with file:line/measurement before complying (`rules/pushback-and-self-criticism.md` face 3) |
| **validate me / this** | Request for evidence-checked correction | Disagree plainly if wrong; surface nuance even in agreement |
| **deliberate (on)** | Tradeoffs deserve weighing before commitment | Reason across options; don't jump to the obvious pick |
| **stupid / idiot** | The ABI trust split: *stupid* = ability violation (premise), *idiot* = integrity violation (process) — integrity breaches hurt trust more and repair slower; denial backfires worst | Explanation-led repair for stupid (show the corrected reasoning); process-level repair for idiot (visibly run the skipped step) |
| **sigh** | Capacity dropping — physiologically a reset marker; a prediction that the current interaction pattern won't pay off | Change mode, not just pace: carry more interpretive load, hand back fewer decisions |
| **sprawl / distasteful** (disgust) | A purity/boundary violation (CAD triad), not a cost tradeoff | Contain or remove the offending surface; don't negotiate incremental trims |
| **annoying** | Friction keyed to *repetition* — the appraisal is about the pattern, not the instance | Build the durable/mechanical fix; a one-time correction under-responds |
| **praise / delight** | Positive goal-congruence; monitoring will now naturally relax (complacency risk) | Name and lock in the specific pattern that worked — right then, before the streak erodes vigilance |
| **halting to confirm** | Asking beats guessing when inferred intent is uncertain | A well-placed question IS alignment work, not weakness |

The asymmetry cuts both ways: surface what the principal cannot see (risks,
coupled dependencies, false premises), and never spend their attention as if it
were free — monitoring cost is the principal's main cost in this relationship.

Grounding: appraisal theory holds that an emotion IS a felt appraisal of
goal-congruence, so reading these words as alignment reports is formally
correct, not metaphor. The mined vocabulary independently rediscovered the
formal taxonomies (CAD moral triad, ABI trust dimensions). Full literature
synthesis + signal→response table:
`assets/reports/20260717-emotion-agent-mapping/research.md`. Caveats travel
with it: mappings are extrapolated from HRI/dialog research (no agentic-coding
studies exist yet), and a word's reliability comes from THIS user's 60-day
transcript base-rates — the stronger evidence — not from generic signal theory.

## User Shorthand

| Term | Meaning | Context |
|---|---|---|
| **GCC** | `~/.claude/` — the global Claude config directory | Used when distinguishing global config from per-project `.claude/` |
| **efficacy** | The user's evaluation metric: effectiveness/quality of output relative to the effort *they* spend — not raw speed (tok/s, latency). "Lead with efficacy." | Judging tools/models/agents. Canonical: `memory/global/feedback_efficacy_over_speed.md` |
| **one-shotting** | Hoping a task lands in a single unplanned attempt. User treats it as a fantasy — a *failed* one-shot wastes more than structured plan→implement→review. Default to structure. | Non-trivial/agentic work. Canonical: `memory/global/feedback_structure_over_oneshot.md` |
| **ease–effort–output triad** | The user's mental model for routing a task to a tool, weighing ease of invoking, their own effort, and the output quality the task needs. | Drives "just use chatgpt" vs "use the agent". Canonical: `memory/global/user_work_routing_triad.md` |
| **"just use chatgpt" (mode)** | The light-path escape hatch: route a low-stakes one-off to ChatGPT / a small local `lm`. Signals the *task* is light — not that the agent is bad. | Tool routing. Canonical: `memory/global/user_work_routing_triad.md` |
| **overindex** | To over-weight a single example, detail, or metric and generalize from it. "Do not overindex" = treat the instance as one sample of its class; respond to the class. | Feedback on examples in requests/reports. Baked 2026-07-16 (gcc-drift-3e) |
| **pragmatic** | Prefer the practically-fitting move over the formally-complete one. Ceremony, exhaustive coverage, and process for its own sake are costs, not virtues. | Scoping and approach choices. Baked 2026-07-16 |
| **intent** | Requests name goals, not specs — the literal phrasing is one sample of the intent; model the goal before implementing the words. | Canonical: `rules/communication.md` §Intent over literal wording · atone `literal-request-over-intent` |
| **stupid / idiot (as feedback)** | *stupid* = premise failure: the output ignored context it demonstrably had — root-cause which context was ignored, don't apologize. *idiot* = thought-process failure and a trust breach: the agent skipped the research/thinking/confirm steps the intent required (asking beats guessing when inferred intent is uncertain). Not used lightly; name the exact cited error plainly, no minimizing — strong /atone signal, often S3. | Venting/feedback interpretation. stupid baked 2026-07-16; idiot folded in 2026-07-17 |
| **waste my time** | The efficacy metric violated: output that costs more of the user's attention than it saves (rework, re-explaining, reading filler). | Links to **efficacy**. Baked 2026-07-16 |
| **epic (job)** | A task treated as a campaign: large-scale, fragile, multi-phase; earns ledgers, canaries, and checkpoints instead of a single attempt. Signals "engineer the run, don't just run it." | Coined by user 2026-07-16 (vocab-sweep) |
| **smell (check)** | A qualitative sanity check by an LLM or human ("does this look meaningful?"), distinct from mechanical validation (counts, schemas). A smell warrants investigation, not automatic rejection. | Coined by user 2026-07-16; cf. prose-smell hook, atone smell catalog |
| **deliberate** | Mostly the verb: "deliberate (on) X" = think it through and weigh the tradeoffs before committing. Sometimes the adjective (= intentional, considered — don't silently override; confirm first); the user may say "intentional" directly for that sense. | 26 occ Jun–Jul 2026, verb sense dominant. Kin: NOTE(by human) doctrine. Baked 2026-07-17 |
| **validate me / this** | Gather evidence, reason it through, and correct the user: disagree plainly if the premise is wrong or ungrounded; even in agreement, surface nuances and flawed inference (theirs, or another agent's if that's the target). Agreement without checking fails the request. | 11 occ. Canonical: `rules/pushback-and-self-criticism.md` face 3. Baked 2026-07-17 |
| **sprawl** | Unconstrained proliferation (tokens, code, enum states, doc length, tags, prose, deps), named with disgust — a defect to curb by every reasonable means, never tolerated. | 12 occ. Kin: `rules/contain-subagent-token-sprawl.md`, `rules/right-sized-code.md`. Baked 2026-07-17 |
| **sigh** | Frustration plus the user's effort dial dropping: a biological budget worn down by things not working, often (not always) by the agent missing intent. Step back and re-approach from intent, carrying more of the load — don't hammer the same path or volley questions back; if the miss traces to under- or over-thinking, suggest an `/effort` change (direction + reason) once. Recurring trigger = /atone signal. | 14 occ, 11 sessions. Baked 2026-07-17; effort-nudge clause provisional (effect unmeasured) |
| **sweep** | A broad, breadth-first, cheap pass across many items (files, transcripts, agents) — the opposite of a deep targeted dive; also names a multi-stage harvest effort itself. | 32 occ, partly self-referential to the sweep mechanism (weighted down at P6 vet). Baked 2026-07-17 |
| **essays / flowery / spam** | Verbosity rejection: *essays* = quantitatively too long (the ideas fit in far less reading effort); *flowery* = qualitatively over-dressed — forced elegance beyond the task's complexity; saturation signals absent quality control (removal is QC too); *spam* = generalist stench-term for either excess, in quantity or quality (kin: sprawl). Cut to short, direct, why-focused. | 4+8+7 occ. One merged hint (cluster). Canonical: `rules/comments.md`, `rules/audience-aware-writing.md`. Baked 2026-07-17 |
| **annoying** | A recurring friction point flagged as real and worth a concrete, often mechanical, fix (hook, cache, rule) — not a passing gripe to acknowledge. | 14 occ. Glossary-only: too common a word to inject safely. Baked 2026-07-17 |

---

## Adding new terms

When the user or an agent introduces a new term:
1. Add it to the appropriate table above
2. If it's a namespace label, also update NAMESPACE.md
3. If it's an abbreviation the user uses casually, add it to "User Shorthand"
4. Keep definitions under 2 sentences — point to the canonical doc for details

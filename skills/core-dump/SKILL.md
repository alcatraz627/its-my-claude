---
name: core-dump
description: Writes _checkpoint.claude.md (or a named file) to the project root — condensing the active session into original goal, sequential agent actions, current expectation, and pending items. Supports "mini" mode for quick abbreviated notes. Records a session-keyed pointer + chronological index entry under ~/.claude/checkpoints/ so multiple long-running agents do not clobber each other. Serves as a hand-off artifact for /catchup after /clear.
allowed-tools: Read, Write, Glob, Bash, Edit, mcp__inputs__form, mcp__inputs__confirm
argument-hint: "[mini] [filename] [--name NAME] [--no-prompt] [instructions]"
user-invokable: true
---

## Brief

Snapshot the active session into a structured `_checkpoint.claude.md` file (or a
named alternative) in the project root, then record a session-keyed pointer under
`~/.claude/checkpoints/` so `/catchup` can find it. The checkpoint captures the
initial user goal, agent actions in sequence, current user expectation, and
pending to-dos — task context, not conversational tone. This is the hand-off
artifact `/catchup` consumes after `/clear`.

Two outputs make this skill work, and both are load-bearing:

1. The **checkpoint file** with its parse-critical sections (below).
2. The **global pointer write** in Phase 3.6 — without it, `/catchup` cannot
   locate the checkpoint and the file is orphaned.

## Continuation advisory: recommending /core-dump + /clear vs /compact

This skill is one half of a decision the agent should make OUT LOUD. When session
continuation is expected (a ctx-pressure nudge fired, a natural task boundary was
reached with more work queued, or the user says they'll come back to this),
proactively recommend one of the two continuation paths in a single line, with
the reason:

| situation | recommend | why |
|---|---|---|
| task boundary reached; next work is separable | `/core-dump` then `/clear` | The checkpoint is auditable and cheap; `/catchup` restores exactly what was written, and a fresh window beats a lossy summary. This is the DEFAULT. |
| mid-task, and the working state lives in conversation nuance (a long debugging thread, undistilled user decisions, an unfinished deliberation) | `/core-dump mini` then `/compact` | The summary preserves conversational momentum a checkpoint cannot; the mini dump backstops what compaction strips (constraints, caveats, approvals). Prefer a targeted `/compact <instructions>` over bare `/compact` (CLAUDE.md § Compact Instructions). |
| context under 70% and no boundary | neither | The ctx-pressure hook is the instrument; without its notice, keep working (`rules/communication.md` § context-load claims). |

Two facts anchor the recommendation. Compaction reliably preserves task momentum
while stripping constraints, caveats, and not-yet-approved state (the documented
drift engine behind `rules/invariant-graduation.md`), so anything that must
survive belongs in a written checkpoint BEFORE compacting; the PreCompact hook's
shell snapshot is a safety net, not a substitute, because it does no LLM
synthesis. And approvals for pushes, deploys, and destructive ops expire across
BOTH paths, so neither choice carries authorization forward.

> **Parse contract — do not rename.** `/catchup` parses the checkpoint by exact
> headings: `## Resume Contract`, `## Initial Goal`, `## Agent Actions`,
> `## Current Expectation`, `## Pending Items`, `## Session Insights`. Keep them
> verbatim. (Resume Contract + Session Insights are tolerated-missing on mini /
> precompact / pre-2026-07 checkpoints; the middle four are mandatory.) The
> default filename `_checkpoint.claude.md` is also a contract — `/catchup`
> falls back to it.

## Step 0 — Load shared guidelines and runtime context

Read `.claude/skills/GUIDELINES.md` and apply its rules for the whole run:
forbidden paths, retry logic, tool preferences, verbosity, timeouts, post-run
insights, and the file-lock protocol. Also read `.claude/skills/runtime-notes.md`
for past run history; continue without it if absent.

Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at the
start to clear stale locks from crashed sessions. Acquire a lock before every
Edit/Write and release it immediately after. Never write to `runtime-notes.md` or
any SKILL.md without holding its lock.

## Usage

```
/core-dump [mini] [filename] [--name NAME] [--no-prompt] [instructions]
```

| Argument       | Type     | Description |
| -------------- | -------- | ----------- |
| `mini`         | optional | If the first token is literally `mini`, run **mini mode** — an abbreviated checkpoint (done / not-done / next-steps / goal) for quick `/catchup` recovery, not a thorough hand-off. |
| `filename`     | optional | Target filename, must end in `.md`. Defaults to `_YYYYMMDD-<session-id>.claude.md` (e.g. `_20260331-fix-auth-3b.claude.md`). A symlink `_checkpoint.claude.md` → latest is created for `/catchup`. |
| `--name NAME`  | optional | Human-readable label shown in the `/catchup` picker. Skips the Phase 3.5 name prompt; defaults to the session-id. |
| `--no-prompt`  | optional | Skip the Phase 3.5 interactive form. Use for headless / sub-agent runs. Defaults are still recorded. |
| `instructions` | optional | Free-form style notes for this dump (e.g. "focus on design decisions only", "be terse"). Ignored in mini mode. |

If both a filename and instructions are present, the filename is detected first
(starts with `_` or ends in `.md`); all remaining text is treated as instructions.

## Phase 1 — Parse arguments

1. Read the args string (may be empty).
2. **Mini mode:** if the first token is literally `mini` (case-insensitive), set
   `mode = mini` and remove it. Otherwise `mode = full`.
3. **Pull out flags** before treating the rest as filename/instructions:
   - `--name <value>` → store as `ARG_NAME`, remove both tokens (value may be quoted).
   - `--no-prompt` → set `ARG_NO_PROMPT=1`, remove the token.
4. Scan for a filename token (ends in `.md` or starts with `_`). If found, use it;
   else default to `_YYYYMMDD-<session-id>.claude.md`. After writing, create/update
   the `_checkpoint.claude.md` symlink → the written file so `/catchup` finds the latest.
5. Treat remaining text as style instructions for Phase 2 (ignored in mini mode).
6. Print the resolved mode, filename, name (if any), and instructions.
7. If `mode = mini`, go to **Phase 2-mini**. Skip Phase 2 (full).

## Phase 2-mini — Abbreviated summary (mini mode only)

Produce a flat, scannable checkpoint — no deep analysis, no insights section, no
`improvement-ideas.md` update. Just the essentials for `/catchup`:

1. **Goal** — 1-2 sentences: what the user originally asked for.
2. **Resume** — ONE imperative sentence: the very first move on resume. Add a
   `**Blocked on:**` line only when something actually blocks (USER: / external).
   Add a `**Standing constraints:**` line (verbatim, with checks) and a
   `**Standing caveats:**` line (verbatim) whenever any exist — mini mode is not
   exempt from carrying them; omit the lines entirely only when there are none.
3. **Done** — what was accomplished (files modified, features added, bugs fixed).
4. **Not Done** — what remains incomplete.
5. **Next Steps** — numbered immediate actions for the next agent, in priority order.
6. **Key Files** — file paths central to the work.

Write using this template:

```markdown
# Mini Core Dump — <ISO timestamp>

**Goal:** <1-2 sentences>

**Resume:** <one imperative sentence — the first move>

**Done:**

- <item>

**Not Done:**

- <item>

**Next Steps:**

1. <step>

**Key Files:**

- `<path>`

---

_Generated by /core-dump mini. Resume with /catchup._
```

Then go to **Phase 3** (write) and **Phase 5** (verification). Skip the Phase 4
visual summary in mini mode — print only the standard verification block.

---

## Phase 2 — Summarize session (full mode)

Analyze the conversation and produce a structured summary. Focus on task context;
skip session tone, pleasantries, and off-topic exchanges.

Cover every item below:

- What was done (files modified, features added, bugs fixed)
- Next steps, in priority order
- The original user goal (and any mid-session pivot)
- User feedback received (corrections, preferences, constraints)
- Tangential scope that came up but wasn't addressed
- Insights — what worked, what didn't, problems, gotchas
- Notes for future agents (things not obvious from the code)
- The immediate next step (what to do right now)

For insights that are broadly applicable (not project-specific), also append a
dated entry to `~/.claude/improvement-ideas.md` (create with a
`# Claude Improvement Ideas` header if absent).

> **Route insights to the right surface — keep these distinct:**
> - `improvement-ideas.md` — **general cross-project learnings** (tool bugs, shell
>   gotchas, workflow patterns, "next time consider X"). Free-form, dated. Future
>   agents read for context.
> - `~/.claude/proposals.jsonl` — **actionable system improvements** someone should
>   ship. Filed via `propose.sh add`.
> - `runtime-notes.md` — **skill-specific run history** for this project.
>
> Routing: "I learned X" / "X is a gotcha" → `improvement-ideas.md`. "We should
> build X" / "X needs fixing" → `propose.sh add`. "When `/foo` ran, Y happened" →
> `runtime-notes.md`. Some learnings later graduate to proposals — don't duplicate
> at write-time.

### 2.1 Initial goal

One to three sentences capturing what the user originally asked for. If the goal
shifted mid-session, note the original goal and the pivot.

### 2.2 Agent actions (sequential log)

A numbered list of actions in order. For each:

- State what was done and why (one line).
- For large data (file reads, API results, long code): reference the source path
  or describe what was found — don't reproduce content verbatim.
- For tool calls: note the tool and the outcome.
- For decisions: capture the decision, not the deliberation.

Example: `3. Read src/data/pipeline/pipeline.types.ts — found PipelineArgs type mismatch at line 42; proposed fix captured below`

### 2.3 Current expectation

One to two sentences: what does the user expect to happen next? What are they
waiting for, or about to do?

### 2.4 Pending items / to-dos

A bullet list of what's needed to complete the current task — both agent-side and
user-side.

Seed this from the live Task list first: read `~/.claude/tasks/session-<sid8>/*.json`
(sid8 = first 8 hex of `$CLAUDE_CODE_SESSION_ID`; each file is `{id, subject,
status}`) and treat every non-`completed` task as pending.
Then add anything the conversation surfaced that the task list missed. The live
Task list is the freshest record of what's open; the conversation fills gaps.

### 2.5 Session insights & meta

Capture meta-observations: what worked well, what didn't (dead ends, wasted
effort), gotchas (non-obvious traps), notes for future agents, user feedback
(corrections/preferences/constraints), and tangential scope not addressed.

Broadly-applicable insights also get a dated entry in
`~/.claude/improvement-ideas.md`.

### 2.6 Resume Contract

Synthesize the one block the next agent can act on without reading anything else
— this is the standardized "continue prompt" (it exists because users had to ask
for one by hand). Eight fields, one line each; write `none` rather than omitting
a field, so absence is legible. The two conservative fields lead — they fence
everything below them:

- **Standing constraints** — plan-level invariants and protected assets that
  bind every next step: "existing UI is reused, not rebuilt", an API contract
  that must hold, an asset worth days of iteration — each with the check that
  would catch its loss (parity ledger, baseline screenshots, a named flow).
  Copy each constraint VERBATIM from its source (doc line, user message);
  paraphrase is where laundering starts. Carry the full list forward into every
  later checkpoint until the user retires an entry. Provenance: doc-22
  (constraints dropped while task momentum survived — see
  `rules/invariant-graduation.md`).
- **Standing caveats** — the honest qualifications that must survive
  summarization: unverified claims, `UNCONFIRMED — <reason>` markers,
  "N commits unreviewed", undispositioned review findings (count + ledger
  path). Copied verbatim, never compressed. A summary that drops a caveat is
  wrong, not shorter ("checkpoint compression laundered the debt" — claude-ipc
  RCA, 2026-07-16).
- **Next action** — ONE imperative sentence, the first move. Distinct from
  Pending Items (the backlog): this is what to do right now.
- **Blocked on** — `USER: <what>` · `AGENT: none — go` · external actor + what.
- **Expired authorizations** — approvals that die at compact/clear/resume
  (pushes, deploys, destructive ops, account or identity switches). Listing them
  is what makes the fresh-confirmation rule mechanical instead of remembered.
- **Decaying prerequisites** — environment state you had to fix or start this
  session for a surface to work, which rots silently between write and read:
  credentials/tokens on a timer (gcloud ADC, a refreshed login), tunnels, dev
  daemons/servers, seeded or mutated data. List each with its fix command, so the
  next agent re-arms it instead of hitting a stale failure. Prompt: "what did I
  have to fix or start this session for this to work?"
- **Verification state** — last real run + result + the command that produced it
  ("`pnpm typecheck` green after action #7" · "UNCONFIRMED — nothing run").
- **Key anchor** — the single most load-bearing file:line, or `—`.

Keep it 8-12 lines total. Pull the continuation-critical Session Insights here
(the 2.5 section keeps the full detail); under "be terse" instructions compress
the values, never drop the field labels — and never "compress" a Standing
constraint or caveat into a paraphrase; those two fields carry verbatim or not
at all.

### 2.7 Apply style instructions

If Phase 1 extracted instructions, adapt the sections: "focus on design decisions
only" → collapse 2.2 to decisions; "be terse" → compress each section; "include
file references" → cite a file path in every 2.2 action. No instructions → use the
default balanced style.

## Phase 3 — Write checkpoint

### 3.1 Locate project root

Use Glob to find `.claude/` in the working-directory tree. The project root is the
directory containing `.claude/`. Print it.

**Name the working surface.** If the session's work lives in a git worktree or a
non-default branch that differs from the invoked CWD, capture the absolute
worktree path + branch — the Quick Summary leads with it, or a `/catchup` agent
edits the wrong tree. Resolve via `git rev-parse --show-toplevel` +
`git branch --show-current`.

### 3.2 Acquire lock and write

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "_checkpoint.claude.md" "core-dump"
```

Write to `<project-root>/<resolved-filename>` using the Write tool. The `##`
section headings below are parsed verbatim by `/catchup` — keep them exact:

```markdown
# Quick Summary (for LLMs) — <ISO timestamp>

**Working surface:** <absolute worktree/repo path> · branch `<branch>`
<!-- Include this line whenever work lives in a git worktree or a non-default branch
     that differs from CWD, so a /catchup agent edits the right tree. Omit only when
     working in the plain project root on the default branch. -->

> <3-5 sentence executive summary: what the session accomplished, what's in progress,
> the immediate next step, and any critical blockers. Written for an agent that loads
> this file first and decides what to read in detail below.>

# Core Dump — <ISO timestamp>

## Resume Contract

- **Standing constraints:** <each verbatim, with its check | none>
- **Standing caveats:** <each verbatim | none>
- **Next action:** <one imperative sentence>
- **Blocked on:** <USER: … | AGENT: none — go>
- **Expired authorizations:** <list | none>
- **Decaying prerequisites:** <each with its fix command — creds/tunnels/daemons/seeded data | none>
- **Verification state:** <last run + result + command | UNCONFIRMED — nothing run>
- **Key anchor:** <file:line | —>

## Initial Goal

<2.1 content>

## Agent Actions

<2.2 numbered list>

## Current Expectation

<2.3 content>

## Pending Items

<2.4 bullet list>

## Session Insights

<2.5 content — what worked, what didn't, gotchas, notes for future agents>

---

_Generated by /core-dump. Resume with /catchup._
```

The **Quick Summary** is the first section — an agent can read only it to decide
whether to deep-dive. Write it last (after the other sections) so it reflects the
complete state. Then release the lock:

```bash
bash ~/.claude/skills/shared/lock-file.sh release "_checkpoint.claude.md" "core-dump"
```

### 3.3 Format, then validate the parse contract (mandatory)

```bash
npx prettier --write <resolved-filename>
bash ~/.claude/scripts/checkpoint/validate-checkpoint.sh <resolved-filename>   # add --mini in mini mode
```

The validator refuses any dump missing the four mandatory exact headings, and
its refusal is the gate, not this sentence: a 2026-08-13 dump with improvised
headings ("Resume prompt", "Done, and verified") parsed as nothing and orphaned
the /catchup that read it. On FAIL, rename the sections to the contract
headings and re-run until OK; never proceed to 3.5 with a failing file.

### 3.4 Additional context files (rare)

If the summary is too large for one file, create supplementary `_*.claude.md`
files (e.g. `_decisions.claude.md`) and reference each under a
`## Supplementary Files` section. This is the exception, not the default.

### 3.5 Prompt for checkpoint name + summary

Before the global pointer write, give the user a chance to set a human-readable
name and one-line summary — both appear in the `/catchup` picker.

Skip the prompt when any of: `mode == mini`; `ARG_NO_PROMPT == 1`; `ARG_NAME` was
supplied; or no TTY / structured-output mode (CI, sub-agent, `claude -p` headless).

Compute defaults first:
- `DEFAULT_NAME` = `ARG_NAME` if set, else the session-id (e.g. `auth-refactor-a7`).
- `DEFAULT_SUMMARY` = the first non-empty sentence of the 2.1 goal, ~80 chars.

If skipping: set `CKPT_NAME=$DEFAULT_NAME`, `CKPT_SUMMARY=$DEFAULT_SUMMARY`,
continue. Otherwise ask in PLAIN TEXT in the conversation, never through
`mcp__inputs__form` or any dialog tool. The inputs dialogs are unusable in the
owner's fullscreen TUI (memory `feedback_askuserquestion_tui_fullscreen`).
Print both defaults and say "reply with overrides, or go". Any terse
continuation (go, yes, ok, or the next instruction) accepts the defaults.
Never block on this step.

### 3.6 Write the global pointers — the load-bearing step

> **This is the step that makes the checkpoint discoverable.** Without it, the
> file you just wrote is orphaned: `/catchup` reads `~/.claude/checkpoints/` to
> find checkpoints, and a checkpoint that never wrote its pointer simply does not
> appear. Mini mode runs this step too. Do not skip it.

Call the checkpoint writer — it performs all three writes (session-keyed pointer,
chronological index, legacy back-compat) atomically:

```bash
~/.claude/scripts/checkpoint/write.sh \
  --session-id      "<session id slug>" \
  --session-uuid    "${CLAUDE_CODE_SESSION_ID:-}" \
  --project-root    "<absolute project root>" \
  --checkpoint-path "<absolute path to checkpoint file>" \
  --name            "$CKPT_NAME" \
  --summary         "$CKPT_SUMMARY"
```

`--session-uuid` is the full Claude Code session UUID from
`$CLAUDE_CODE_SESSION_ID`. It lets `/revive` join checkpoints to the transcript at
`~/.claude/projects/<encoded>/<uuid>.jsonl`.

This writes:
- `~/.claude/checkpoints/<session-id>.json` — your session's own pointer (no
  contention with other sessions).
- `~/.claude/checkpoints/index.jsonl` — append-only chronological log feeding the
  `/catchup` picker.
- `~/.claude/_last-checkpoint.json` — legacy single-slot pointer (back-compat;
  readers drop it after migration 0008, tracked by `prop-20260515-141140-44`).

The per-session directory + index (instead of one shared file) is why multiple
long-running agents across projects don't clobber each other — each gets its own
pointer; no last-writer-wins.

Then print: `Checkpoint indexed as "$CKPT_NAME" — resume with /catchup`.

### 3.7 Workspace doc diff (optional, non-blocking)

Operate on this session's own doc — `<notes-dir>/$CLAUDE_CODE_SESSION_ID.md` — not
the shared `_active.md` symlink (which may point at another concurrent session's
notes). If that doc exists, propose updates; never blind-overwrite.

The `## Todos` block (between `<!-- sync:auto:start -->` and
`<!-- sync:auto:end -->`) is auto-managed by the `stop-sync` hook every turn — do
not propose todos into it; they'd be overwritten. The high-value writeback here is
the durable narrative (notes, decisions, doc links), not task checkboxes. Proposal
schema and the diff/apply flow are in `EXAMPLES.md` § "Workspace-doc proposal".

Steps: build the proposal JSON from the Phase 2 synthesis → show the diff via
`session-notes/diff.sh --session-id "${CLAUDE_CODE_SESSION_ID:-$SESSION_ID}"` →
ask apply / edit / skip in PLAIN TEXT (dialog tools hang the owner's fullscreen
TUI; memory `feedback_askuserquestion_tui_fullscreen`). Key the doc by the full
session UUID so it's the same file the `stop-sync` mirror writes. Skip silently if
the session's own doc doesn't exist.

### 3.8 Contribute a gcc-improvement proposal (full mode, only when reusable friction surfaced)

End-of-session is the cheapest moment to capture an improvement to `~/.claude`
itself, because the Session Insights (2.5) are already in front of you. A friction
worth more than a checkpoint note belongs in the improvement backlog, where the
weekly consolidation triages it — not buried in a checkpoint nobody re-reads.

From the Session Insights, judge two things: was there a friction that is **(a)
about the gcc itself** (a hook gap, a missing guard, a skill that misfired, a
clunky workflow) — not project-specific — **and (b) reusable beyond this one
session**?

- **No** → skip silently. This is the common case; most sessions contribute nothing,
  and that is correct. Do not invent a contribution to fill the slot (see
  `rules/right-sized-code.md` and `speculative-abstractions-without-a-load-bearing-caller`).
- **Yes** → file **exactly one** proposal (cap: one per session — if several
  surfaced, pick the highest-value; do not batch). Cross-link it to the residue
  that motivated it so the weekly consolidation can corroborate it:

```bash
bash ~/.claude/scripts/propose.sh add \
  --title "<imperative — what to change in ~/.claude>" \
  --body  "<the friction · where it bit (file:line if known) · the proposed fix>" \
  --category hooks|scripts|skills|config|docs|other \
  --effort  small|medium|large \
  --session "${CLAUDE_CODE_SESSION_ID:-}" \
  --tags    "src:session-contrib link:atone:<slug> link:dream:<id> link:prop:<id>"
```

The `--session` stamp lets the `gcc-signal-capture` Stop hook see that this session
already filed, so it won't also auto-stub a duplicate.

Set only the `link:*` tags you actually have — an atone slug you filed this session,
a dream insight id you acted on, a related open proposal id. Do **not** set a
value/priority: that is computed at triage from how many independent streams
corroborate the item, so you never have to guess it. Skip in mini mode and in
headless / sub-agent runs. This is the deliberate, high-quality capture path; the
`gcc-signal-capture` Stop hook is its data-path safety net (it auto-stubs a proposal
on a strong signal if this step is skipped), so a missed contribution is never lost.

## Phase 4 (optional, full mode only): visual summary

A terminal-only convenience: render the sealed record via the shared trace
renderer. It is **not** written to the checkpoint file and is **not**
load-bearing. The checkpoint and the Phase 3.6 pointer are what matter. Skip it
entirely in mini mode, and feel free to skip it under headless/sub-agent runs.

1. Write session data to `/tmp/core-dump-data-<session-id>.json` (per-session
   naming avoids a parallel session's stale data). If the file exists, `trash` it
   first. The full JSON schema and authoring notes are in `EXAMPLES.md`.
2. Render:
   ```bash
   /bin/bash ~/.claude/scripts/render/trace.sh /tmp/core-dump-data-<session-id>.json
   ```

`/catchup` calls the same script with `--kind catchup`. That shared call is what
makes the record and the briefing read as one house style. Section vocabulary is
a court sitting: DECREE, DOCKET, OBJECTION, CHRONICLE, AMENDMENTS, COUNSEL, each
carrying a one-word plain gloss so nothing needs decoding.

Three regalia are kept and one is picked at random per render. Pass `--theme
a|b|c` (or set `TRACE_THEME`) to pin one. `--width N` overrides the terminal
width. Colour is forced by default because a skill's output always goes through
a pipe, where `gum` and most tools strip it; `NO_COLOR` still wins. File rows are
project-relative, with OSC 8 hyperlinks available behind `TRACE_LINKS=1`.

The script is macOS bash 3.2 compatible. Every empty state omits its section
rather than printing a placeholder.

---

## Phase 5: verification

1. Read back the written file to confirm it exists and is non-empty.
2. Confirm the Phase 3.6 pointer write succeeded (the writer prints a confirmation
   line; a non-zero exit means `/catchup` won't find this checkpoint).
3. Confirm the parse contract survived:
   ```bash
   rg -c '^## (Resume Contract|Initial Goal|Agent Actions|Current Expectation|Pending Items|Session Insights)$' <checkpoint>
   ```
   Six hits in full mode. Fewer means `/catchup` will not parse it.

**The Phase 4 render IS the closing statement.** Do not follow it with a plain
summary box: the rendered trace already carries the file path in its seal, the
status in its header, and the pending work in its DOCKET. A dry ASCII box printed
underneath undoes the whole point of the visual and is the last thing the user
reads.

In **mini mode**, or when Phase 4 was skipped, print the seal alone rather than a
bare block, so even the abbreviated path closes in the same language:

```bash
printf '{"session_id":"<sid>","timestamp":"<ts>","status":"<status>",
        "project_root":"<root>","checkpoint_path":"<file>"}' \
  > /tmp/core-dump-seal-<sid>.json
/bin/bash ~/.claude/scripts/render/trace.sh /tmp/core-dump-seal-<sid>.json
```

With every section absent, the renderer emits a header and a seal and nothing
between them, which is exactly the right shape for a receipt.

**Then keep the prose short.** The render did the reporting. Say only what the
render cannot: an unverified claim, a blocker needing the user, or a decision
awaiting them.

## Notes

- **No sub-agents.** Core-dump needs the full parent conversation (initial goal,
  all actions, current state). A `context: fork` sub-agent can't see the parent,
  and passing the full conversation as a prompt would exceed limits. Evaluated and
  rejected 2026-04-06.
- Always overwrite — never append. The checkpoint is a point-in-time snapshot.
- If no meaningful work happened (e.g. run right after `/clear`), write a minimal
  checkpoint noting the session was empty rather than skipping the write.
- Internal context files follow `_*.claude.md` naming (start `_`, end `.claude.md`).
  Never use a bare `checkpoint.md`.
- `/catchup` is the companion that reads this file to restore context after `/clear`.
- **Pre-compact hook:** `~/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh`
  runs before all compaction (auto and manual `/compact`). It writes a lightweight
  `_precompact-checkpoint.claude.md` and a WAL CHECKPOINT — the shell-level
  counterpart to `/core-dump mini` (faster, less detail).
- Post-run: write a runtime-notes entry via
  `~/.claude/skills/shared/prepend-runtime-note.sh` (GUIDELINES.md §7). Always use
  the absolute path — this skill may run from any directory.

## See Also

- `~/.claude/skills/core-dump/EXAMPLES.md` — visual-summary JSON schema,
  workspace-proposal schema, and the five render-validation scenarios.
- `~/.claude/skills/catchup/SKILL.md` — the resume consumer; parses the section
  headings above (Resume Contract first) and restores task context.
- `~/.claude/skills/forgotten-todos/SKILL.md` — consumes this checkpoint's
  **Pending Items** (ingested into `dreams/pending-todos.jsonl`) to surface the
  cross-session backlog.
- `~/.claude/personas/task-goal-planner.md` — the planning working-mode that uses
  the Task tool + WAL + `/core-dump`/`/catchup` as the plan → status → resume
  backbone.
- `~/.claude/skills/revive/SKILL.md` — heavier resume; rehydrates the full
  transcript via the `--session-uuid` recorded in Phase 3.6.

---
name: core-dump
description: Writes a checkpoint (_YYYYMMDD-<session>.claude.md) condensing the session into a resume contract, goal, actions, expectation, pending items and insights, sized to how much the session did. Indexes a session-keyed pointer under ~/.claude/checkpoints/. Hand-off artifact for /catchup after /clear, and the session's journal. Run only when the owner asks or on keep-warm's last wake.
allowed-tools: Read, Write, Glob, Bash, Edit, mcp__inputs__form, mcp__inputs__confirm
argument-hint: "[mini] [filename] [--name NAME] [--no-prompt] [instructions]"
user-invocable: true
---

## Brief

Snapshot the active session into a structured `_checkpoint.claude.md` file (or a
named alternative) in the project root, then record a session-keyed pointer under
`~/.claude/checkpoints/` so `/catchup` can find it. The checkpoint captures the
initial user goal, agent actions in sequence, current user expectation, and
pending to-dos. It holds task context, not conversational tone. This is the hand-off
artifact `/catchup` consumes after `/clear`.

Two outputs make this skill work, and both are load-bearing:

1. The **checkpoint file** with its parse-critical sections (below).
2. The **global pointer write**, done by finalize (Phase 3.3); without it, `/catchup` cannot
   locate the checkpoint and the file is orphaned.

## When this skill runs (owner ruling 2026-10-13)

Exactly two triggers:

1. **The owner asks.** A typed `/core-dump`, including one written inside a longer
   message ("do X, then /core-dump"), in the owner's own latest message.
2. **Keep-warm's last wake.** Its hook text says to run the full dump; that is the
   dump the owner resumes from after the cache goes cold.

An agent never runs it on its own. A wake is not the owner: a task notification,
ipc mail, a monitor event, a goal check-in or a context-pressure nudge does not
authorize a dump. The session's transcript is the crash fallback (`/retro-dump`,
`/revive`), so nothing needs dumping "just in case". Owner, verbatim: "I want to cut
down on core-dump usage, but make it valuable when it happens."

**Suggesting one is fine, once, in one line.** At a task boundary, with the
ctx-pressure notice showing 60% or more used and more work queued, say: "Context is
N%; `/core-dump` then `/clear` would drop each later call from about N k to about
170k tokens and pays for itself after about 50 calls." Then keep working. Below 60%,
or mid-task, say nothing. `/compact` is the owner's call; a targeted
`/compact <instructions>` beats a bare one (CLAUDE.md § Compact Instructions).

**Already dumped?** If gather reports `existing_dump` with no owner turn since (keep-warm
or an earlier request already wrote it), do not write another: print the existing
path and its resume line, `/catchup at <path>`, and stop. The owner can say "dump
again" to force a fresh one.

> **Parse contract, do not rename.** `/catchup` parses the checkpoint by exact
> headings: `## Resume Contract`, `## Initial Goal`, `## Agent Actions`,
> `## Current Expectation`, `## Pending Items`, `## Session Insights`. Keep them
> verbatim. (Resume Contract + Session Insights are tolerated-missing on mini /
> precompact / pre-2026-07 checkpoints; the middle four are mandatory.) The
> default filename `_checkpoint.claude.md` is also a contract: `/catchup`
> falls back to it.

## The shape of a run: gather, one Write, finalize

Every tool call in a dump re-reads the whole session context, often 700k tokens or
more, so the run is deliberately short: gather, `CronList`, one Write, finalize, and
only the goal-record or insight writes this session actually needs:

1. **Gather** (one Bash call):
   `bash ~/.claude/scripts/checkpoint/gather.sh --session-id <announced session id> --uuid "$CLAUDE_CODE_SESSION_ID"`.
   Pass both: a script cannot know the id you announced, and the shared
   current-session file can belong to another session. It
   prints every fact the dump must copy rather than recall: project root, working
   surface, default filename, transcript path, session size and depth hint,
   `existing_dump`, the previous same-stem dump, goal (harness and gcc), goal record,
   task store, wake, deadline, ipc alias, this session's atone ids, pending approval
   codes. Then call `CronList` once for the crons line.
2. **Write** (one call): the checkpoint, from the template in Phase 3, filled from
   the gather block plus your synthesis.
3. **Finalize** (one Bash call):
   `bash ~/.claude/scripts/checkpoint/finalize.sh <file> --session-id <id> --uuid "$CLAUDE_CODE_SESSION_ID"`.
   It formats, validates, diffs caveats and constraints against the previous dump,
   checks every Standing authorization against the transcript, checks ruling paths,
   symlinks, writes the global pointer, and renders the closing record. On `FIX:`,
   make one repair Edit and run finalize again.

The checkpoint filename is session-unique, so no lock is taken for it
(`GUIDELINES.md` lock protocol exemption). Do not read GUIDELINES.md or
runtime-notes.md for a dump; nothing in the dump consumes them.

**Depth fits the session** (owner ruling 2026-10-13: "If core-dump does not need
expensive work, then let it not do more than needed"). When gather's depth hint is
`light` (a one-off session that did one or two things), keep every heading but write
one or two lines under each, `none` for empty Resume Contract fields, and skip the
3.6 proposal. Never pad a section to look thorough.

## Usage

```
/core-dump [mini] [filename] [--name NAME] [--no-prompt] [instructions]
```

| Argument       | Type     | Description |
| -------------- | -------- | ----------- |
| `mini`         | optional | The headless template `/retro-dump` uses (`retro-dump.sh` runs `/core-dump mini --no-prompt`). Interactive sessions never choose it: the owner rarely did, agents did it in limbo, and mini resumes scored worse (mean 3.40 against 3.91 over 197 handoffs). A light session gets a short full dump instead (depth rule above). |
| `filename`     | optional | Target filename, must end in `.md`. Defaults to `_YYYYMMDD-<session-id>.claude.md` (e.g. `_20260331-fix-auth-3b.claude.md`). A symlink `_checkpoint.claude.md` → latest is created for `/catchup`. |
| `--name NAME`  | optional | Human-readable label shown in the `/catchup` picker; defaults to the session id. |
| `--no-prompt`  | optional | Headless run (retro-dump, sub-agents): finalize gets `--headless` and prints the receipt seal instead of the render. |
| `instructions` | optional | Free-form style notes for this dump (e.g. "focus on design decisions only", "be terse"). Ignored in mini mode. |

If both a filename and instructions are present, the filename is detected first
(starts with `_` or ends in `.md`); all remaining text is treated as instructions.

## Phase 1: Parse arguments

1. Read the args string (may be empty).
2. **Mini mode:** if the first token is literally `mini` (case-insensitive), set
   `mode = mini` and remove it. Otherwise `mode = full`.
3. **Pull out flags** before treating the rest as filename/instructions:
   - `--name <value>` → store as `ARG_NAME`, remove both tokens (value may be quoted).
   - `--no-prompt` → set `ARG_NO_PROMPT=1`, remove the token.
4. Scan for a filename token (ends in `.md` or starts with `_`). If found, use it;
   else default to `_YYYYMMDD-<session-id>.claude.md`. After writing, create/update
   the `_checkpoint.claude.md` symlink → the written file so `/catchup` finds the latest.
   **Browser extension roots:** if the project root holds a `manifest.json` with
   `manifest_version`, write the checkpoint and its symlink into `<root>/.claude/`,
   never the root. Chrome will not load an unpacked extension whose root holds a
   `_` file (2026-10-20, better-file-browser). `guard-extension-root.sh` blocks it.
5. Treat remaining text as style instructions for Phase 2 (ignored in mini mode).
6. Print the resolved mode, filename, name (if any), and instructions.
7. If `mode = mini`, go to **Phase 2-mini**. Skip Phase 2 (full).

## Phase 2-mini: Abbreviated summary (mini mode only)

Produce a flat, scannable checkpoint. No deep analysis, no insights section, no
`improvement-ideas.md` update. Just the essentials for `/catchup`:

1. **Goal**: what the user originally asked for, in 1-2 sentences.
2. **Resume**: the very first move on resume, as ONE imperative sentence. Add a
   `**Blocked on:**` line only when something actually blocks (USER: / external).
   Add a `**Standing constraints:**` line (verbatim, with checks) and a
   `**Standing caveats:**` line (verbatim) whenever any exist. Mini mode is not
   exempt from carrying them; omit the lines entirely only when there are none.
3. **Done**: what was accomplished (files modified, features added, bugs fixed).
4. **Not Done**: what remains incomplete.
5. **Next Steps**: numbered immediate actions for the next agent, in priority order.
6. **Key Files**: file paths central to the work.

Write using this template:

```markdown
# Mini Core Dump, <ISO timestamp>

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


## Re-arm in the TUI

<one line per commitment the owner may want to re-arm after /clear, each a paste-ready
command; this block is the bare-minimum guarantee that the goal is never lost.
Mandatory when any goal exists or is proposed; the wake and deadline lines are
optional and appear only when the session's shape warrants them.>

- goal (STILL VALID, harness ARMED|not armed): `/goal <text>`   <bare, one line, no rail characters: the owner selects and pastes it>
  <EVERY clause must be one the AGENT can finish alone. See 2.6.>
- (or, when none was set) proposed goal from Pending Items: `/goal <proposed text>`
- wake, only if work is parked on a clock (a CI run, a peer reply, a cron): `/wake <when> <what>`
- deadline, only if the owner named a due time or the work has a natural one: `/deadline <when> <commitment>`

---

_Generated by /core-dump mini. Resume with /catchup._
```

Then finalize with `--headless --mini` (Phase 3.3); without `--mini` the full-dump
contract rejects the mini shape and nothing is indexed.

---

## Phase 2: Summarize session (full mode)

Analyze the conversation and produce a structured summary. Focus on task context;
skip session tone, pleasantries, and off-topic exchanges.

Cover every item below:

- What was done (files modified, features added, bugs fixed)
- Next steps, in priority order
- The original user goal (and any mid-session pivot)
- User feedback received (corrections, preferences, constraints)
- Tangential scope that came up but wasn't addressed
- Insights: what worked, what didn't, problems, gotchas
- Notes for future agents (things not obvious from the code)
- The immediate next step (what to do right now)

Only when an insight is broadly applicable (not project-specific), also append a
dated entry to `~/.claude/improvement-ideas.md` (create with a
`# Claude Improvement Ideas` header if absent). Each extra call re-reads the whole
context, so skip it at light depth and when nothing qualifies.

> **Route insights to the right surface and keep these distinct:**
> - `improvement-ideas.md`: **general cross-project learnings** (tool bugs, shell
>   gotchas, workflow patterns, "next time consider X"). Free-form, dated. Future
>   agents read for context.
> - `~/.claude/proposals.jsonl`: **actionable system improvements** someone should
>   ship. Filed via `propose.sh add`.
> - `runtime-notes.md`: **skill-specific run history** for this project.
>
> Routing: "I learned X" / "X is a gotcha" → `improvement-ideas.md`. "We should
> build X" / "X needs fixing" → `propose.sh add`. "When `/foo` ran, Y happened" →
> `runtime-notes.md`. Some learnings later graduate to proposals. Don't duplicate
> at write-time.

### 2.1 Initial goal

One to three sentences capturing what the user originally asked for. If the goal
shifted mid-session, note the original goal and the pivot.

### 2.2 Agent actions (sequential log)

A numbered list of actions in order. For each:

- State what was done and why (one line).
- For large data (file reads, API results, long code): reference the source path
  or describe what was found. Don't reproduce content verbatim.
- For tool calls: note the tool and the outcome.
- For decisions: capture the decision, not the deliberation.

Example: `3. Read src/data/pipeline/pipeline.types.ts — found PipelineArgs type mismatch at line 42; proposed fix captured below`

### 2.3 Current expectation

One to two sentences: what does the user expect to happen next? What are they
waiting for, or about to do?

### 2.4 Pending items / to-dos

A bullet list of what's needed to complete the current task. Both agent-side and
user-side.

**The goal record is the truth for what is left across sessions (D1, 2026-09-23).**
When the conversation surfaced open work the goal record lacks (gather prints the
record's id; skip this at light depth or with no goal), put it ON the goal, not only
in this file, with
`~/.claude/scripts/goals/gs task <g> <mN> "<subject>"` (a row) or
`gs note <g> [id] "<handoff>"` (a one-off the next session should do as part of an
existing row, never a second row). Then this section CITES the goal
(`goal <id>: N open rows, acceptance p/a proven; run /tasks left <id>`) and lists
only what has no home on it. The agent's own Task-tool list
(`~/.claude/tasks/session-<sid8>/`) is its checklist; it seeds this section only
for rows the goal should not carry.

### 2.5 Session insights & meta

Capture meta-observations: what worked well, what didn't (dead ends, wasted
effort), gotchas (non-obvious traps), notes for future agents, user feedback
(corrections/preferences/constraints), and tangential scope not addressed.

**The session's atone record crosses the clear here.** Take gather's `atone_ids`,
copy them onto the Resume Contract's `Atone this session` line, and name each here in
one line: slug, severity, and the fix applied or promised. A fresh wound is the highest-value insight a
resume can inherit, and the SessionStart atone lane shows only the machine-wide
top patterns, never what THIS session just did. Skip silently when the session
recorded nothing.

Broadly-applicable insights also get a dated entry in
`~/.claude/improvement-ideas.md`.

### 2.6 Resume Contract

Synthesize the one block the next agent can act on without reading anything else.
This is the standardized "continue prompt" (it exists because users had to ask
for one by hand). Eight fields, one line each; write `none` rather than omitting
a field, so absence is legible. The two conservative fields lead, because they fence
everything below them:

- **Standing constraints**: plan-level invariants and protected assets that
  bind every next step: "existing UI is reused, not rebuilt", an API contract
  that must hold, an asset worth days of iteration. Give each the check that
  would catch its loss (parity ledger, baseline screenshots, a named flow).
  Copy each constraint VERBATIM from its source (doc line, user message);
  paraphrase is where laundering starts. Carry the full list forward into every
  later checkpoint until the user retires an entry. Provenance: doc-22
  (constraints dropped while task momentum survived, see
  `rules/invariant-graduation.md`).
- **Standing caveats**: the honest qualifications that must survive
  summarization: unverified claims, `UNCONFIRMED — <reason>` markers,
  "N commits unreviewed", undispositioned review findings (count + ledger
  path). Copied verbatim, never compressed. A summary that drops a caveat is
  wrong, not shorter ("checkpoint compression laundered the debt", claude-ipc
  RCA, 2026-07-16).
- **Next action**: ONE imperative sentence, the first move. Distinct from
  Pending Items (the backlog): this is what to do right now.
- **Next action's requirements:** where the asks that define "done" for that
  action live. Pointers, never copies: `file:line`, an ipc `msg-id`, a report
  path, an owner message and its timestamp. Write `in constraints (N)` when the
  Standing constraints already hold all of them, and `none` when the action is
  self-contained, such as a rerun or a commit.

  Standing constraints carry the RULINGS on a piece of work, and rulings are
  mostly born from incidents, so they describe what went wrong once. They are
  not the same thing as the requirements the owner stated when they asked for
  the work. On 2026-08-19 this dump named the deck re-plan as the next action
  and carried three deck constraints, all three traceable to the theme
  incident. The owner's original requirement list from 2026-08-18 was absent:
  grepping the finished checkpoint for `create-report`, `typography`,
  `presenter`, `second screen`, `ste-writing` and `scaffolding` returned zero
  hits each. Most of those had landed in `skills/deck/SKILL.md`, so they were
  not lost from the system, but nothing on the resume surface pointed there and
  a resumed agent would have planned against three constraints instead of ten
  asks.

  The transcript holds the requirements and `/clear` destroys the transcript.
  That is the whole reason this field exists.

- **Blocked on**: `USER: <what>` · `AGENT: none — go` · external actor + what.
  Before recording any blocker, answer: **is it reproducible on demand right
  now?** Run the thirty-second check (re-trigger the job, hit the endpoint,
  re-run the command) and record the RESULT, not a conclusion from a stale
  artifact. A predecessor's "the run log is already expired" cost a day; the
  failure reproduced via workflow_dispatch in thirty seconds
  (automation-d8ff1149, 2026-08-19).
- **Standing authorizations:** the owner's approvals, carried forward so the next
  session acts on them without asking again. Owner ruling 2026-10-13: "Let the agents
  inherit auth". Hard limits live in Switchboard policy and its hooks, not in the
  handoff. One entry per grant:
  `"<owner's verbatim words>" (<YYYY-MM-DD HH:MM>) · target: <repo[/branch|PR] @<sha or artifact>> · one-shot|standing`.
  Four fences keep this honest. The words are the owner's own, quoted, never an
  inferred stance: finalize marks a quote it cannot find in the transcript
  `UNVERIFIED:`, and an unverified grant is never acted on. The target is named, so a
  resume re-asks only when the target moved. A one-shot grant that was spent is
  dropped. A grant binds to its repo. Hook gates (push to main, policy asks) are
  unaffected and follow Switchboard. Write `none` when there are none.
- **Pending approval codes:** approval codes the owner was shown and has not
  answered (gather's `pending_codes`), as `<target> · nonce <code>`, or `none`. A
  code is keyed to this session and dies at `/clear`; listing it lets the next
  session re-issue it.
- **Decaying prerequisites**: environment state you had to fix or start this
  session for a surface to work, which rots silently between write and read:
  credentials/tokens on a timer (gcloud ADC, a refreshed login), tunnels, dev
  daemons/servers, seeded or mutated data. List each with its fix command, so the
  next agent re-arms it instead of hitting a stale failure. Prompt: "what did I
  have to fix or start this session for this to work?" Add a read-only `check:`
  command where one exists (`gcloud auth print-access-token >/dev/null`,
  `curl -sf localhost:5117/health`). Catchup runs checks, never fix commands, so a
  prerequisite the owner already fixed is not reported as expired.
- **Key files:** the absolute paths the next session will open first, comma
  separated. Catchup builds its file list from this line, not from Agent Actions.
- **Atone this session:** gather's `atone_ids`, or `none`. Catchup turns each into a
  fence, so a fresh mistake crosses the clear.
- **Rulings this session:** each owner ruling made in this session, as
  `"<quote>" -> <path where recorded>`. A ruling belongs in the project's docs, a
  rule or memory the moment it is made, not only in a checkpoint; finalize checks
  each path exists. `none` when there were none.
- **Verification state**: last real run + result + the command that produced it
  ("`pnpm typecheck` green after action #7" · "UNCONFIRMED: nothing run").
- **Live commitments:** the session's GOAL, any armed `/wake`, any `/deadline`.
  These are what a `/clear` silently drops, and the only ones the next session
  cannot reconstruct by reading code. Owner ruling 2026-08-18, verbatim:

  > if the /goal was set for a given session, have it write that down in core-dump
  > IF it thinks its still valid (erring to the side of it probably still being),
  > and catchup will either auto-re-arm it or ask the user to re-arm it

  The re-arm half was superseded on 2026-10-13: catchup now only offers the goal.
  The judgment below still decides what it offers. So this field records a JUDGEMENT, not an inventory. For each, write the
  commitment and whether it still holds:

  - `goal: <the goal, verbatim> · STILL VALID · harness ARMED|not armed · gcc set|none`
    (or `SUPERSEDED by <what>`). **Read it, do not recall it:**
    `bash ~/.claude/scripts/goal/goal.sh show` prints both sources. The `harness`
    line is the built-in `/goal` the owner actually ran (parsed from this session's
    transcript, so it is what was set, not what you remember); the `gcc` line is the
    goal file the agent or `/catchup` wrote (`~/.claude/goals/<sid>.json`), the one
    that survives `/clear`. Record BOTH states, from gather. Never write a goal
    into the gcc store yourself: `goal.sh set` is the owner's move
    (`rules/goal-statement-on-starting-work.md`). The paste line in the Re-arm block
    is how the next session's owner re-arms it. **Err toward still-valid.** Dropping a live goal costs
    the owner a re-setup on every resume, which is the exact pain this field exists
    for. Carrying a stale one costs one sentence to retire. The asymmetry is the
    whole rule. If NO goal was set anywhere, write `none` and, in the Re-arm block
    (§3.2), propose one from the Pending Items, so the owner can arm it with a paste.

    **A goal with more than one clause reports per clause.** The 2026-08-18 goal
    was "do planned and asked for goal, tasks, deck, validate, get feedback via
    ipc, and show me a summary at the end": six clauses, five served, and the
    last one never ran, because the session ended on a `/tasks` render and the
    owner returned eleven hours later. The dump marked the whole thing
    SUPERSEDED, which is defensible about the goal and silent about the clause.
    A single verdict on a compound goal always rounds toward whatever had
    momentum, and the unserved clause is the half nobody sees again.

    So when the goal names two or more deliverables, append a clause ledger:

    ```
    goal: <verbatim> · SUPERSEDED by <what> · clauses: goal=served · tasks=served
          · deck=served · validate=served · ipc=served · summary=UNSERVED
    ```

    Write `served` only for a clause you can point at a turn for. `UNSERVED` in
    caps, because it is the one the reader must act on. A single-clause goal
    skips the ledger entirely; this is not a field to pad.

  - `wake: <schedule> · ARMED` / `FIRED` / `none`. Read the live state rather than
    recalling it: `~/.claude/.turn-state/<SESSION_ID>.json`.
  - `crons: <duty-slug (job id, schedule)> …` / `none`. Read the live state with
    `CronList`, never from memory, and cross-check the duty ledger
    (`bash ~/.claude/scripts/cron/cron-duty.sh list`). State the lifetime fact
    IN the checkpoint so the resume cannot get it wrong: CronCreate jobs are
    PROCESS-scoped. They survive `/clear` and `/compact`; they die with the
    process. The resume must `CronList` first and re-arm only what is absent
    (rules/scheduling-discipline.md §CronCreate; the c2271ddc duplicate,
    2026-08-21, is what skipping that check produces).
  - `deadline: <commitment> due <when> · LIVE` / `MET` / `MISSED` / `none`. State
    lives with the skill (`skills/deadline/runtime-notes.md`, plus that run's veto
    ledger and burn projection).

  Write `none` for any never set. A commitment is not an authorization; approvals
  travel only under Standing authorizations.
- **Task list, glanced:** from gather's goal record and task store lines; let it
  shape the Next action and the offered goal in the Re-arm block. Owner ask
  2026-08-18 ("good to have: during core-dump or catchup, have the agent run /tasks
  and also suggest a new / update existing goal").
- **Goal record:** the goal id this session works under (`~/.claude/goals/by-id/<id>.json`,
  from gather). Catchup reads the record by this id and OFFERS `gs link <id>` with
  the goal paste line; linking also arms the standing-goal hinter, so it is the
  owner's call, like `/goal`. Write `—` when no goal was filed,
  and say why in one clause.
- **Task store:** the agent's own checklist store (`session-<sid8>`, under
  `~/.claude/tasks/`), for `gs adopt` if a resumed agent wants rows from it. `—` if empty.
- **ipc alias**: this session's claude-ipc alias (`claude-ipc who` or the SessionStart line), so a resume knows which dead mailbox holds its predecessor's mail.
- **Key anchor**: the single most load-bearing file:line, or `—`.

**Copy these fields from gather, do not recall them.** Live commitments, the goal
record and the task store are exactly the values a long session mis-remembers;
gather.sh reads them (the task store by content, not by this session's id, which
named an empty store in six resumes).

**The goal record needs no resolver.** It is keyed by the goal, and this session's
pointer (`~/.claude/goals/<sid>.json`, written by `gs new` / `gs link` / `goal.sh set`)
names it. Record the goal id; a resumed session links to it and is home.

The goal has two readable sources, and `bash ~/.claude/scripts/goal/goal.sh show`
prints both. `/goal <text>` is a Claude Code BUILT-IN that installs a session-scoped
Stop hook and lives in memory only; `goal.sh harness` recovers it from this session's
transcript (`~/.claude/projects/<cwd, slashes and dots as dashes>/<SESSION_ID>.jsonl`,
the `<command-name>/goal</command-name>` blocks), so record what was SET, not what
you remember. The gcc goal (`~/.claude/goals/<sid>.json`) is what the
`37-goal` hinter injects each session. Judge validity against what actually
happened this session, then write the goal, its validity, and both arm states into
Live commitments, and the paste line into the Re-arm block. `/catchup` only OFFERS
that line; it never re-arms a goal (owner ruling 2026-10-13: "only offer it, never
re-arm. The goal given to me is often vague and general").

**Every clause of a proposed goal must be one the agent can finish alone.** An
armed `/goal` installs a Stop hook, so a clause whose actor is the owner can
never be satisfied by working: the hook blocks every stop, and the agent cannot
clear a harness goal, only the owner can. vb-fable lost six consecutive stop
rounds on 2026-08-19 to a proposed goal opening "Take the owner's board review of
rounds 6 and 7", and the owner had to disarm it by hand, which is the exact cost
this field exists to remove (reported by catch-r7-a3).

So when the work genuinely waits on the owner, put the agent's half in the goal
and leave the owner's half in **Blocked on**. Write "draft the proposal and put
it to the owner", never "take the owner's review". `goal.sh set` and
`goal.sh armline` warn when they see an owner-actor clause, but the warning is
the backstop; the wording is yours.

Keep it 8-12 lines total. Pull the continuation-critical Session Insights here
(the 2.5 section keeps the full detail); under "be terse" instructions compress
the values, never drop the field labels, and never "compress" a Standing
constraint or caveat into a paraphrase; those two fields carry verbatim or not
at all.

### 2.7 Apply style instructions

If Phase 1 extracted instructions, adapt the sections: "focus on design decisions
only" → collapse 2.2 to decisions; "be terse" → compress each section; "include
file references" → cite a file path in every 2.2 action. No instructions → use the
default balanced style.

## Phase 3: Write checkpoint

### 3.1 Project root and working surface

Take both from gather (`project_root`, `working_surface`). If the work lives in a
worktree or a non-default branch, the Quick Summary leads with it, or a `/catchup`
agent edits the wrong tree.

### 3.2 Write

**Every completion claim carries how it was checked.** A successor reads this file
as fact and acts on it. "Verified", "done", "passing", and "fixed" each need the
command, the file, or the run that produced them, in the same sentence. Anything
you believe but did not check is written as unverified, in those words. The
failure this prevents is a successor inheriting confidence you never earned and
spending its session on work that was already done, or trusting a claim that was
never true. Across 122 post-gate checkpoints, completion language outnumbers
hedged language 72 to 1.

Write to `<project-root>/<resolved-filename>` using the Write tool. The `##`
section headings below are parsed verbatim by `/catchup`. Keep them exact:

```markdown
# Quick Summary (for LLMs), <ISO timestamp>

**Working surface:** <absolute worktree/repo path> · branch `<branch>`
<!-- Include this line whenever work lives in a git worktree or a non-default branch
     that differs from CWD, so a /catchup agent edits the right tree. Omit only when
     working in the plain project root on the default branch. -->

> <3-5 sentence executive summary: what the session accomplished, what's in progress,
> the immediate next step, and any critical blockers. Written for an agent that loads
> this file first and decides what to read in detail below.>

# Core Dump, <ISO timestamp>

## Resume Contract

- **Standing constraints:** <each verbatim, with its check | none>
- **Standing caveats:** <each verbatim | none>
- **Next action:** <one imperative sentence>
- **Next action's requirements:** <file:line · msg-id · report path · owner msg ts | in constraints (N) | none>

> Reconcile before writing (prop-20260716-182646-e8, owner batch 2026-09-18): re-read
> the Next action against every Standing caveat and the last three Agent Actions. If a
> caveat or an action already says the next action is done, captured or superseded,
> rewrite the next action or drop the stale caveat; never write both. Sections written
> at different moments of the session drift apart, and the resume pays for it.
- **Blocked on:** <USER: … | AGENT: none — go>
- **Standing authorizations:** <"<owner's verbatim words>" (<YYYY-MM-DD HH:MM>) · target: <repo[/branch|PR] @<sha>> · one-shot|standing … | none>
- **Pending approval codes:** <target · nonce <code> … | none>
- **Decaying prerequisites:** <each with its fix command, plus · check: <read-only command> where one exists | none>
- **Verification state:** <last run + result + command | UNCONFIRMED: nothing run>
- **Live commitments:** goal: <verbatim · STILL VALID|SUPERSEDED by …|none · clauses: <name>=served|UNSERVED … (2+ clause goals only) · harness ARMED|not armed · gcc set|none> · wake: <schedule · ARMED|FIRED|none> · deadline: <commitment due when · LIVE|MET|MISSED|none> · crons: <duty-slug (job, schedule) via CronList|none>
- **Task list, glanced:** <N open, M done · needs you: #ids · grouped by <key> | —>
- **Goal record:** <goal id | —>
- **Task store:** <store from gather | —>
- **ipc alias:** <alias | —>
- **Key anchor:** <file:line | —>
- **Key files:** <absolute paths, comma separated | none>
- **Atone this session:** <atone ids | none>
- **Rulings this session:** <"<quote>" -> <path where recorded> … | none>

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


## Re-arm in the TUI

<one line per commitment the owner may want to re-arm after /clear, each a paste-ready
command; this block is the bare-minimum guarantee that the goal is never lost.
Mandatory when any goal exists or is proposed; the wake and deadline lines are
optional and appear only when the session's shape warrants them.>

- goal (STILL VALID, harness ARMED|not armed): `/goal <text>`   <bare, one line, no rail characters: the owner selects and pastes it>
  <EVERY clause must be one the AGENT can finish alone. See 2.6.>
- (or, when none was set) offered goal covering every agent-side pending item, in short plain sentences: `/goal <text>`
- wake, only if work is parked on a clock (a CI run, a peer reply, a cron): `/wake <when> <what>`
- deadline, only if the owner named a due time or the work has a natural one: `/deadline <when> <commitment>`

---

_Generated by /core-dump. Resume with /catchup._
```

The **Quick Summary** is the first section: an agent can read only it to decide
whether to deep-dive. Compose it last so it reflects the complete state, but put it
first in the one Write.

### 3.3 Finalize (one call)

```bash
bash ~/.claude/scripts/checkpoint/finalize.sh <checkpoint> --session-id <id> --uuid "$CLAUDE_CODE_SESSION_ID" [--name NAME] [--summary TEXT] [--headless] [--mini]
```

It does, in order: format; validate the parse contract (on failure it prints `FIX:`
and stops before indexing, so you make ONE repair Edit and run it again); diff
Standing caveats and Standing constraints against the previous same-stem dump
(`DECIDE:` lines: restore each verbatim or say in the dump that it retired and why;
a silent drop is the drift `rules/invariant-graduation.md` names); check every
Standing authorization's quote against this session's transcript (marks misses
`UNVERIFIED:` in place); check every `Rulings this session` path exists; warn when an
item is pending in one section and done in another; list constraints with no source
quote as `CONFIRM OR RETIRE:` (never deletes them); symlink `_checkpoint.claude.md`;
write the global pointer (`write.sh`, which also feeds the dream ingester); and render
the closing record from the checkpoint's own headings. The render is the last thing it
prints. `--headless` prints the receipt seal instead.

The pointer write is what makes the checkpoint discoverable: `/catchup` reads
`~/.claude/checkpoints/`, and a checkpoint without its pointer is orphaned. Name
defaults to the session id and summary to the first sentence of the Initial Goal;
pass `--name` only when the owner gave one. Do not stop to ask for a name.

Read finalize's report. Act on `FIX:` and `DECIDE:`; mention `UNVERIFIED:` and
`CONFIRM OR RETIRE:` lines to the owner in one line each.

### 3.4 Additional context files (rare)

If the summary is too large for one file, create supplementary `_*.claude.md`
files (e.g. `_decisions.claude.md`) and reference each under a
`## Supplementary Files` section. This is the exception, not the default.

### 3.5 Workspace doc diff (only when the owner asks)

Operate on this session's own doc (`<notes-dir>/$CLAUDE_CODE_SESSION_ID.md`) not
the shared `_active.md` symlink (which may point at another concurrent session's
notes). If that doc exists, propose updates; never blind-overwrite.

The `## Todos` block (between `<!-- sync:auto:start -->` and
`<!-- sync:auto:end -->`) is auto-managed by the `stop-sync` hook every turn, so do
not propose todos into it; they'd be overwritten. The high-value writeback here is
the durable narrative (notes, decisions, doc links), not task checkboxes. Proposal
schema and the diff/apply flow are in `EXAMPLES.md` § "Workspace-doc proposal".

Steps: build the proposal JSON from the Phase 2 synthesis → show the diff via
`session-notes/diff.sh --session-id "${CLAUDE_CODE_SESSION_ID:-$SESSION_ID}"` →
ask apply / edit / skip (plain text, `AskUserQuestion` or `mcp__inputs__confirm`
all work). Key the doc by the full
session UUID so it's the same file the `stop-sync` mirror writes. Skip silently if
the session's own doc doesn't exist.

### 3.6 Contribute a gcc-improvement proposal (only when reusable friction surfaced)

End-of-session is the cheapest moment to capture an improvement to `~/.claude`
itself, because the Session Insights (2.5) are already in front of you. A friction
worth more than a checkpoint note belongs in the improvement backlog, where the
weekly consolidation triages it, not buried in a checkpoint nobody re-reads.

From the Session Insights, judge two things: was there a friction that is **(a)
about the gcc itself** (a hook gap, a missing guard, a skill that misfired, a
clunky workflow, but not project-specific) **and (b) reusable beyond this one
session**?

- **No** → skip silently. This is the common case; most sessions contribute nothing,
  and that is correct. Do not invent a contribution to fill the slot (see
  `rules/right-sized-code.md` and `speculative-abstractions-without-a-load-bearing-caller`).
- **Yes** → file **exactly one** proposal (cap: one per session; if several
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

Set only the `link:*` tags you actually have. An atone slug you filed this session,
a dream insight id you acted on, a related open proposal id. Do **not** set a
value/priority: that is computed at triage from how many independent streams
corroborate the item, so you never have to guess it. Skip in mini mode and in
headless / sub-agent runs. This is the deliberate, high-quality capture path; the
`gcc-signal-capture` Stop hook is its data-path safety net (it auto-stubs a proposal
on a strong signal if this step is skipped), so a missed contribution is never lost.

## Phase 4: close

finalize's render is the closing statement, with the checkpoint path as a `file` row
and the paste-ready resume line (`/catchup at <checkpoint path>`). Do not follow it
with a summary box. Say only what the render cannot: an unverified claim, a decision
the owner owes, a `DECIDE:` you resolved. End with one line naming the path forward:
`/clear` then the resume line.

## Notes

- **No sub-agents.** Core-dump needs the full parent conversation (initial goal,
  all actions, current state). A `context: fork` sub-agent can't see the parent,
  and passing the full conversation as a prompt would exceed limits. Evaluated and
  rejected 2026-04-06.
- Always overwrite: never append. The checkpoint is a point-in-time snapshot.
- If no meaningful work happened (e.g. run right after `/clear`), write a minimal
  checkpoint noting the session was empty rather than skipping the write.
- Internal context files follow `_*.claude.md` naming (start `_`, end `.claude.md`).
  Never use a bare `checkpoint.md`.
- `/catchup` is the companion that reads this file to restore context after `/clear`.
- **Pre-compact hook:** `~/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh`
  runs before all compaction (auto and manual `/compact`). It writes a lightweight
  `_precompact-checkpoint.claude.md` and a WAL CHECKPOINT. It is the shell-level
  counterpart to `/core-dump mini` (faster, less detail).
- No runtime-notes entry per dump: the checkpoint is the record, and each extra call
  re-reads the whole context.

## See Also

- `~/.claude/skills/core-dump/EXAMPLES.md`: visual-summary JSON schema,
  workspace-proposal schema, and the five render-validation scenarios.
- `~/.claude/skills/catchup/SKILL.md`: the resume consumer; parses the section
  headings above (Resume Contract first) and restores task context.
- `~/.claude/skills-parked/forgotten-todos/SKILL.md` (parked 2026-08-20): consumed
  this checkpoint's **Pending Items** via `dreams/pending-todos.jsonl`; the
  ingestion still runs, the browse skill is parked.
- `~/.claude/personas/task-goal-planner.md`: the planning working-mode that uses
  the Task tool + WAL + `/core-dump`/`/catchup` as the plan → status → resume
  backbone.
- `~/.claude/skills/revive/SKILL.md`: heavier resume; rehydrates the full
  transcript via the `--session-uuid` finalize records with the pointer.

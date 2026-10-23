---
name: catchup
description: Resumes a session from a /core-dump checkpoint in one gather call plus a status-first briefing (done, pending on the agent, pending on the owner), carries the owner's standing authorizations, offers the goal without arming it, and continues agent-side work unprompted when nothing waits on the owner. Companion to /core-dump.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[filename | --session-id ID | --pick N | --from ALIAS|SID]"
user-invocable: true
---

## Brief

Resume a cleared session from its `/core-dump` checkpoint for the fewest tool calls:
one gather call that resolves, validates and measures what moved, one read of the
checkpoint, one rendered briefing. Then keep working when the next action is the
agent's.

Owner rulings this skill carries (2026-10-13, verbatim in
`~/.claude/style/sweep/20261013-handoff-70d5/rulings.md`):

- **Goals are offered, never re-armed.** "The goal given to me is often vague and
  general anyways."
- **Authorization carries over.** "Let the agents inherit auth." Hard limits live in
  Switchboard policy and its hooks.
- **Agent-side work continues.** "Often, the last session already has what needs to
  be done next ... Let the agent keep running (optionally w a confirmation) if the
  work plan does not need me yet."

Rare branches (picker, CWD trap, WAL fast path, post-compact detail, workspace
doc, the briefing JSON schema, ipc mail, atone fences, `/tasks`) are in
`~/.claude/skills/catchup/REFERENCE.md`. Read a section there only when you hit it.

## Usage

```
/catchup [filename | --session-id ID | --pick N | --from ALIAS|SID]
```

A filename (or `at <path>`) names the checkpoint. `--session-id` and `--pick` resolve
through `~/.claude/checkpoints/`. With none, resolution prefers the project you are
in.

## `--from`: take over another session's workstream

For a session that stopped without a dump (cut off at the usage limit and left
alone by the reset gate because it had already closed out, or crashed), when you
want its work and not its cache. Only the owner starts this; nothing runs it
automatically. Takes an ipc
alias (`clanky-opus`) or a session id prefix. One call builds the digest with no
model call:

```bash
python3 ~/.claude/scripts/usage/resume-from.py <alias|sid>
```

Line 1 is a path. If it is a core-dump (a dump newer than the last turn exists),
run the normal phases below on it. Otherwise it is a digest: Read it once, then
skip to Phase 3 and brief from it (open tasks are `todos`, "Repo now" is `drift`,
the last reply is where `next_action` comes from). The digest carries no Standing
authorizations; owner approvals quoted in its Owner Messages are context, so
confirm any you would act on in one line. Then Phase 4 as usual. The old session
is left alone; never message it to stop.

## Phase 0: gather (one Bash call)

```bash
bash ~/.claude/scripts/checkpoint/resume-gather.sh [<checkpoint path> | --session-id ID | --pick N]
```

It prints one block: the resolved checkpoint and its validation; drift (branch,
ahead/behind, dirty files, PR state for PRs the checkpoint names); the result of
every read-only `check:` on a Decaying prerequisite (it never runs a fix command);
each Standing authorization with `target now: matches | moved | unknown`; pending
approval codes and whether they need re-issuing; ipc registration and waiting mail;
running background commands; the goal record's open rows; three status lists (done,
pending on the agent, pending on the owner); and `continue: yes | no (<why>)`.

- Ambiguous checkpoint: show the picker (REFERENCE §0.4.3) as plain text and wait.
- CWD is `~/.claude` with nothing indexed: stop and ask (REFERENCE §0.4.6).
- Post-compact resume (a compaction summary is in front of you): follow REFERENCE
  §Phase 0.2's light path. Keep the Task list and ipc alias; the checkpoint wins
  where it and the summary disagree.

## Phase 1: read the checkpoint (one Read)

Read the checkpoint once. What the resume acts on: the Quick Summary, the Resume
Contract, Pending Items, Current Expectation, Initial Goal. Agent Actions and Session
Insights are the journal: skim them only when the next action needs something they
hold. A mini checkpoint uses bold labels (Goal, Resume, Done, Not Done, Next Steps)
instead of headings; read those. Older checkpoints may lack the newer fields; that is
normal.

How each part binds:

- **Standing constraints and caveats** are fences. Restate them verbatim in the
  briefing and re-read the relevant one before touching a surface it names. Never
  paraphrase one into a rosier summary (`rules/invariant-graduation.md`). An entry
  finalize marked `CONFIRM OR RETIRE:` is shown as such for the owner to settle.
- **Standing authorizations** are the owner's approvals, carried over. Act on an
  entry gather lists as actionable while its target matches, or is `unknown`
  (an artifact or a repo gather could not read; the briefing names it so the owner
  can veto). Ask once, in one line, only when the target moved, the entry is
  `UNVERIFIED:` or NOT ACTIONABLE, or a one-shot grant was already spent.
  Push-to-main and policy asks still go through their hooks, as Switchboard sets
  them. A legacy checkpoint with "Expired authorizations" instead carries no
  verbatim grants: confirm those in one line before acting.
- **Pending approval codes:** a code shown before `/clear` belongs to the old
  session and no longer works. When gather says `re-issue`, re-run that blocked
  action once so a fresh code appears, and put it in the briefing.
- **Live commitments:** the goal is OFFERED as a paste line, never armed. Do not run
  `goal.sh set` or `gs link` (linking arms the standing-goal hinter); offer both. A `wake` or `deadline` marked live: ask before re-arming. `crons`:
  run `CronList` first and re-arm only what is missing. Whether CronCreate jobs
  survive `/clear` has been seen both ways (kept 2026-08-21, dropped 2026-09-05),
  so `CronList` is the instrument and a `cron-duty.sh` LIVE verdict is a claim.
- **Atone this session:** each id becomes a fence row (how: REFERENCE §3.3).
- **Completion claims** (done, verified, pushed): gather re-checked what it could
  read-only (git, PR state, `check:` lines). Everything else is "as of dump" with
  the dump's time. Never re-run a check that has side effects (a deploy, a paid run,
  a job re-trigger) just to confirm a claim.
- **An owner stance written without a quote** ("the owner approved X") is not an
  approval.
- **Goal record and task store:** take them from gather.

## Phase 2: targeted context, only for the next action

From the Resume Contract's `Key files` line (older checkpoints: Pending Items and
Agent Actions), Grep only the sections the next action touches, about ten lines
around each anchor. Never read whole files. Snippets are your working context; the
briefing cites them one line each.

## Phase 3: the briefing, status first

Write the briefing data to `/tmp/catchup-data-<session-id>.json` and render it:

```bash
/bin/bash ~/.claude/scripts/render/trace.sh /tmp/catchup-data-<session-id>.json --kind catchup
```

Order and content (keys in REFERENCE §3.1):

1. `done`: up to six short lines from gather's done list, "as of dump" unless
   re-checked.
2. `next_action`: one imperative sentence. `standing_auth` and `blocked_on` render
   as its fence line.
3. `todos`: the agent's pending items as `ready`, the owner's as `gate`, the next
   action as `now`; each `note` names its goal. Plain words, never a bare id without
   what it is.
4. `fences`: one row per Standing authorization you will act on
   (`{"head": "Standing auth", "body": "<verbatim grant> · target now: matches|unknown"}`),
   so the owner sees what you are about to do and can veto it; then constraints,
   caveats, atone prechecks, and the offered goal as
   `{"head": "Goal offered", "body": "<goal> · paste /goal <text>, and gs link <id> to track it"}`.
5. `drift`, `running`, `mail`: one line each.
6. `goal` and `files`: two lines of context.

Then the task table, below the briefing, as the tool prints it (owner, 2026-08-19:
"Show me the /tasks"; details REFERENCE §3.6):

```bash
python3 ~/.claude/scripts/goals/views/path.py --goal <goal id from the contract>
```

The render and the table are the whole report. The TUI collapses long tool output
to a couple of lines, so the owner may never see the render itself: copy its
lines into the reply as plain text, unchanged and without restating them in
prose. Nothing after them except the Phase 4 line. No Insight or star blocks, no restated summary, no "the briefing above shows"
prose.

## Phase 4: continue or ask

- **`continue: yes`** (nothing in the next action waits on the owner): say in one
  line what you are starting ("Starting: <next action>. Say stop to redirect.") and
  start it in the same turn.
- **`continue: no`**: one line naming what you need from the owner, plus the gate
  rows they can act on today. Then do any agent-side item that does not depend on
  it.

Spend no turn asking "which item first" when the checkpoint already ranks them.

A long unattended run opts into compaction with `bash ~/.claude/scripts/session-mgmt/compact-gate.sh on`, run after the notes and Task list are current, because auto-compaction is otherwise refused.

## Notes

- **Input contract:** `/core-dump` checkpoints, sections found by the exact
  headings `## Resume Contract`, `## Initial Goal`, `## Agent Actions`,
  `## Current Expectation`, `## Pending Items`, `## Session Insights`.
- **Malformed checkpoint:** gather prints the validator's missing list. Warn and
  present what exists; partial context beats none.
- **gcc friction found while resuming** (a gap in the checkpoint format, a rough edge
  here): file at most one proposal with `propose.sh add --tags "src:post-catchup"`.
  Most resumes file nothing.
- No runtime-notes entry per resume; every extra call re-reads the context.

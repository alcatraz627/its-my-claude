---
name: blitz
description: Works a goal's rows one after another until none is agent-ready. Specs each row's test while building it, sends build-shaped rows through /bloop, parks a stuck row after 2 tries or 30 min, then tests the whole run and asks the owner once. Not for one change (/bloop).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, Skill
user-invocable: true
argument-hint: "[goal id] | off | status"
---

## Brief

Drives a goal record's queue to empty without fixating on one row or halting
while work remains. Each row gets its test written as part of the row, a budget
of two attempts or 30 minutes, and a park with a reason when the budget runs
out. A Stop hook refuses to end the turn while an agent-ready row is left. At
the end the whole run is tested together, the user-facing paths are exercised
end to end, and everything only the owner can clear goes on one decision page.

# /blitz: work the queue

## How this differs from /bloop and /goal

`/bloop` takes one change through plan, build, an adversarial gate and docs, and
its floor stops that change after a second failed gate. `/goal` is a stop
condition: a few sentences that say when the session is done, with no order, no
budget and no notion of a row. Neither picks the next piece of work, notices
that it has spent forty minutes on the same row, or keeps the turn from ending
while rows are still open, which is the owner's 2026-10-14 ask ("blitz through
all but not get fixated or stuck or halt early") and the account's most repeated
halt (atone `named-the-next-work-then-stopped`, 25 times).

/blitz is that missing layer and nothing more. It reads the goal record, hands
each row to the right worker (inline for a trivial row, `/bloop` for a build),
keeps the budget, and holds the stop. The mechanics live in
`~/.claude/scripts/goals/queue-run.sh` and `~/.claude/scripts/hooks/queue-stop.sh`,
so the skill is the procedure around them. `/wake` stays what it is, outage cover
the owner arms; arm it beside a blitz that will run unattended.

## Usage

```
/blitz              # drive this session's linked goal
/blitz <goal id>    # drive the goal the owner named
/blitz status       # where the run stands
/blitz off          # pause: the Stop hook stands down, rows stay as they are
```

"stop" or "pause" from the owner means `/blitz off`, at once.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for this run. Read
`~/.claude/skills/blitz/runtime-notes.md` if it exists.

## Phase 1: Turn on

1. Name the goal. It is the session's linked goal, or the one the owner named.
   Filing a goal is fine (`gs new`), arming one is the owner's move: never
   `gs link` in their name. If there is no goal and the owner named none, offer
   one paste line and stop there; there is no queue to drive.
2. Make the session notes and Task list current, then run
   `bash ~/.claude/scripts/goals/queue-run.sh on [--goal <id>]`. It records the
   drive, which arms the Stop hook for this session, and opts the session into
   compaction (`compact-gate.sh on`), which is safe because the queue lives on
   disk, not in the context window.
3. Record where the run starts, for Phase 3: `git rev-parse HEAD` in each repo
   the goal touches, written into a `gs note <goal> goal "blitz started at <sha>"`.

## Phase 2: Work each row

Repeat until `queue-run.sh next` exits 1.

1. **Take the row.** `bash ~/.claude/scripts/goals/queue-run.sh next`. It prints
   the row and its attempt count. Exit 4 means the budget is spent: go to step 6.
   Run `next` again before every fresh attempt at the same row; that is how the
   attempt is counted.
2. **Spec its test while you build it.** Before or alongside the first line of
   the change, write the check that will prove the row: a test case, an
   assertion in an existing suite, or one runnable command with its expected
   output. It covers both directions, the bad input it catches and the good
   input it leaves alone. A guard also gets its mutation (break what it
   protects, watch it go red, restore by copy). The test is part of the row,
   never a later row.
3. **Pick the worker by shape.**
   - Trivial (a one-file edit with an obvious check): do it inline and run the
     check.
   - Build-shaped (several files, a guard, anything the owner will look at):
     run `/bloop` on the row, with the check from step 2 as its fixture. Its
     validation gate runs every time.
   - Needs a fact only the owner has: `gs gate <goal> <id> "USER: <the ask>"
     --do "<your drafted answer>"` and take the next row. Nothing is asked
     mid-run.
4. **Close with the proof.** `gs close <goal> <id> --by "<the test that ran and
   what it printed>"`. A row whose check did not run stays open.
5. **No speed trade.** Testing and review are never skipped to move faster.
   When the budget is short, the row is parked untested, never closed untested.
6. **Park when the budget is spent.** Two attempts or 30 minutes, whichever
   comes first (one line in `queue_run.py`): `queue-run.sh park <id> --why
   "<what blocked it>; evidence <path>"`. `/bloop`'s floor does the same under a
   drive. The runner retries each parked row once, after everything else.

If the turn ends while a row is agent-ready, `queue-stop.sh` sends it back naming
the next row. Three stops on an unchanged record park the row in hand for you;
treat that as a finding about the row, not an obstacle.

## Phase 3: Test everything the run changed, together

When `queue-run.sh next` exits 1:

1. List what changed since the start recorded in Phase 1:
   `git diff --stat <start-sha>` in each repo, plus uncommitted files.
2. Find every suite that covers a touched file (the tests beside each script,
   the project's suite for each touched module) and run them all again in one
   pass, fresh: no cached results, no reuse of a run from Phase 2.
3. A failure reopens the row that touched the file (`gs ready <goal> <id>`) and
   sends you back to Phase 2, where `next` takes it as a fresh row with a fresh
   budget.

## Phase 4: Exercise the whole as the owner would

Run the user-facing paths end to end, from a clean state, the way the owner
meets them: the CLI from a fresh shell, the page in a browser with a screenshot
read back (`rules/ui-visual-verification.md`), the hook with a real Stop payload.
Write down what each one showed. Where a path proves an acceptance row, record
it with `gs prove <goal> <aN> --by "<what was exercised and seen>"`. A path you
could not exercise stays unproven and is marked `UNCONFIRMED: <reason>`.

## Phase 5: Ask the owner once

1. `bash ~/.claude/scripts/goals/queue-run.sh gates --json` lists every
   owner-gated row with its drafted answer, every acceptance row only the owner
   can prove, and every parked row with its reason.
2. Put all of it on ONE `/decision-wizard` page, drafted answers attached, plus
   the Phase 3 and 4 results as context. Never a list in chat.
3. `bash ~/.claude/scripts/session-state/session-state.sh set blocked --reason
   "USER: decision page <slug>"`, then end the turn. The drive stays on: the
   Stop hook steps aside while nothing is ready, and the answered page wakes the
   session, whose next `queue-run.sh next` picks up what the answers cleared.
4. When the goal is met or the owner calls it, `queue-run.sh off`.

## Phase 6: Record the run

```bash
bash ~/.claude/scripts/skill-log.sh record blitz \
  --task "<goal id>: <outcome, short>" \
  --outcome unknown \
  --loop converged \
  --note "closed N, parked N, gated N; aggregate suites <pass/fail>; page <slug>"
```

`--outcome` stays `unknown`; the owner's verdict on the page is the outcome. Use
`--loop partial` when the run ended with parked rows. Prepend a short entry to
`~/.claude/skills/blitz/runtime-notes.md` under lock when the run taught
something reusable.

## Validation

Efficacy dimension: the queue empties without the owner chasing it, and
nothing is closed on a check that did not run. Checks, each readable from the
run's own records: (1) halts with rows left: the queue-stop block reasons in the
session transcript and the backstop parks (`"by": "queue-stop"`) in the run
ledger, which should fall; (2) fixation:
rows over budget that were not parked, from `~/.claude/goals/runs/<goal>.jsonl`,
which should be zero; (3) proof: every closed row's `verified` field names a
check that ran; (4) one ask: the owner received one decision page per run, not
questions in chat. A pass is all four readable and none trending worse.

## Notes

- **Pause and mute.** `queue-run.sh off` pauses one session's drive.
  `touch ~/.claude/.no-queue-stop-gate` mutes the Stop hook machine-wide until
  removed.
- **What counts as agent-ready.** No gate, nothing open in front of it, state
  ready or active, not parked. While any row is owner-gated, a row standing in
  front of a gate goes first. `queue-run.sh ready` is the one definition; the
  hook and `session-state.sh` both read it.
- **Not a fleet.** One row at a time, in this session. Fan-out belongs to a row
  that genuinely needs it, inside `/bloop`.

## See also

- `/bloop`: the worker for build-shaped rows
- `/wake`: outage cover for an unattended run; its reconcile step reads the same runner
- `/decision-wizard`: the one page at the end
- `rules/todo-discipline.md`: the goal record is the owner's surface
- `rules/never-halt-on-authority-you-hold.md`: the rule the Stop hook enforces

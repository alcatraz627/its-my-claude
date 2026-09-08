# /tasks redesign: the model, ruled 2026-09-04

Status: the model is ruled and the renderer is built (`scripts/task-table/task-table.sh`,
2026-09-05 onward; goal boxes, milestone bands, CLEAR NOW, one trait per column).
This file is the model the renderer answers to, not a build plan. One question
stays open at the bottom.

Provenance: an owner review on 2026-09-04, after the existing table was called
unreadable four times in one session and the agent answered the data half each
time. See `atone/rca/mist-20260904-094230-86.md` for that failure.

## What the surface is for

Four questions, in the order a person asks them:

1. What must the owner act on, today.
2. Is anything wrong: stuck, stale, contradictory, or false.
3. What is moving, and what does it wait on.
4. Which outcome does each piece serve.

Anything that serves none of these is agent bookkeeping and does not belong in
the default view.

## The unit of work is three-deep

**Goal** is an outcome a person would recognise. "The change is live on preview
and checked once." A goal is what the owner cares about and the only level in
his vocabulary.

**Milestone** is a meaningful stage inside a goal. For that example: the feature
is complete, it passes locally, a PR is open, the deploy ran, the environment
serves it, a smoke check passed. A milestone is not a goal, because on its own it
buys the owner nothing.

**Task** is an actionable row. A milestone holds one or more.

The reason for the middle level is omission, not taxonomy. Agents report a goal
met while one stage of three is real, and the missing stages surface later as
blockers. Naming stages makes the omission visible before it becomes a surprise.

### The containment rule

> A goal is not met while any of its milestones is open.
> A milestone is not met while any of its tasks is open.

The renderer enforces this rather than trusting the claim. This is the rule that
turns "it said done and stopped" from something the owner has to catch into
something the table refuses to print.

## Five states

**owner-gate.** Only the owner can move it, today, with nothing else landing
first. Two hard requirements. The row carries a concrete instruction for how he
clears it; a gate without one is malformed and renders as an error. And a task
with an agent half and an owner half becomes **two linked rows**, never one. The
single-row version produces the pattern the owner named: the agent promises to do
its part first, then halts at the gate anyway, and the gate was invisible until
it fired. Splitting also stops agents avoiding the record entirely.

**blocked.** Waiting on something that is not the owner. Every blocked row names
what would unblock it, and carries a predicate where the class allows one, so the
check is mechanical rather than a promise to re-examine. Where no predicate
exists, the row is timestamped and the render flags it as it ages. This exists
because two rows in the owner's queue were correctly worded and false: one waited
on a sentinel already minted, the other on a migration already applied.

Classes, with what actually clears each:

| class | clears when | predicate |
|---|---|---|
| `by-task` | a named row reaches done | yes |
| `by-lane` | a peer agent's queue reaches it | partial, via IPC |
| `by-subagent` | a dispatched seat returns | yes, by agent id |
| `by-job` | a CI run, deploy, build or cron finishes | yes, by run id |
| `by-review` | a peer or bot review lands | yes, by PR number |
| `by-environment` | creds, tunnel, daemon or quota restored | yes, by probe |
| `by-external` | a vendor, DNS or rate-limit window | rarely |
| `by-schedule` | a time passes | yes, by clock |
| `by-person-not-owner` | a teammate acts | no |
| `by-decision` | a ruling lands that is not the owner's | no |

A ruling the owner owns is `owner-gate`, never `by-decision`. That boundary is
where most false gates came from.

**active.** Being worked now by an agent: this session, a peer, or a dispatched
subagent that has acknowledged. Handing something to a queue is not active.
Work a human is doing is never active, because the state describes agent
behaviour and the agent cannot speak for a person.

Staleness from not having checked is tolerable. Promotion before work starts is
not. The distinction is enforced by an invariant rather than a definition:

> A lane holds at most one active row.

A lane is one process doing one thing, so a second active row in the same lane is
a false claim the renderer can catch. This is the anti-bloat mechanism; tightening
the wording alone would not work, because the agent believes it is being accurate
when it promotes ten rows after a goal is armed.

**review.** Voluntarily held short of done: a peer or subagent is reviewing, a
report awaits the owner's read, a PR is open and unmerged. Distinct from blocked
because the agent *could* proceed. The operational test: if a nudge arrived, could
it move? Yes means review. No means blocked or owner-gate.

Every review row carries why it has not proceeded. Review rows age and the render
flags them, because otherwise the last mile becomes the new dumping ground.

**deferred.** Deliberately out of scope, by the owner or by the plan. The test is
that pursuing it would derail the goal and the goal can complete without it. Each
deferred row records the goal it was deferred from, so the harvest at that goal's
close is scoped rather than one undifferentiated graveyard.

## Who runs what

Three independent fields. They are not coupled and must not share a column.

**tier** is the model that holds the judgment: fable, opus, sonnet, haiku, or an
autonomous lane such as gemini or codex. A seat calling a tool is still that seat;
an opus that invokes a vision helper is opus, not the helper. The recorded tier is
what **ran**, not what was provisioned, and it reconciles against the dispatch log
at `logs/model-dispatch.jsonl`. A mismatch is a finding. The case that motivated
this: a fable seat provisioned for planning that dispatched a sonnet subagent to
do the writing, which makes the provisioning pointless and invisible.

**lane** is the named worker within a project, where a project declares them. Most
do not. Optional, project-scoped, absent by default.

**kind** is the sort of work: plan, build, validate, check, review, docs, or
whatever the caller needs. Declared at creation so drift is visible: a planning
task that slides into building shows the mismatch rather than hiding it.

## What the header reports

Goal progress, not task counts. A finished-task total tells the owner nothing he
values; he measures a goal against the behaviour change it was for, whether that
took three tasks or thirty.

This needs data that does not exist yet: a per-goal done-condition. Until that
lands, the header states goals and their open milestone counts rather than
inventing a percentage.

## Titles, notes and citations

A task title states the outcome and stays short. Agent context goes in a notes
field that is hidden by default and shown under `--detail`, except where a note
names something the owner must know.

References resolve by **default**, not behind `--refs`. A bare task number,
proposal id or document name with nothing a stranger could resolve makes the row
malformed. Paths are absolute on first mention. Resolution is inline and compact
rather than a footnote block, because height is capped and a block spends it.

## Priority

Optional tag. Never a grouping axis. Goals organise the list, because a goal
answers yes or no about a behaviour change, while priority invites agents to skip
valuable work on a number they disagree with. Two rows in the owner's own queue
currently contradict their own priority metadata and nothing sorts by it.

## What a milestone is, ruled 2026-09-04

Milestones are always present, and the agent minimises them. One per goal is the
default and the common case for a run of a couple of hours.

**A milestone names a state the system is in. A task names an action someone
takes.** That single line settles every case the owner raised. "Three bug fixes"
and "one review" are quantities of effort. "The change is under review as a pull
request" and "the system change is in place, validation is next" are descriptions
of where things stand. A non-technical listener can picture the second kind and
can only infer busyness from the first.

The naming test, because otherwise two agents disagree about what counts:

> Read the name aloud with "right now," in front of it. If it parses as a
> true-or-false sentence about the world, it is a milestone. If it does not
> parse, it is a pile of work.

"Right now, the walmart module runs on the foundry contract" parses. "Right now,
three bug fixes" does not.

### Where to cut

One milestone is wrong, and the goal needs splitting, when either holds:

- **An owner-gate falls inside it** rather than at an edge. A milestone is a
  reachable state, so a gate in the middle means the state cannot be reached
  without the owner, which means the boundary was drawn in the wrong place. Gate
  position is therefore a diagnostic on the decomposition, not a thing to arrange
  around.
- **It cannot be finished in one sitting.** A state nobody can reach before
  stopping is not a halting point.

Those two conditions are the counter-pressure that keeps minimisation honest.
Without them, "minimise to one" reproduces the failure this whole redesign is
for: one large milestone quietly holding three stages, reported met on the
strength of one.

### The property this buys

"Can we stop here with nothing half-done" is resumability. So a milestone edge is
also the cheapest place to checkpoint and the cleanest place to resume: a clear at
a boundary loses nothing structural, while one taken mid-milestone loses the
half-state. A core-dump written at an edge is a complete handoff, and the Resume
Contract's next action becomes "start the next milestone" instead of "recover
whatever was mid-flight".

## The height ceiling is an instrument, ruled 2026-09-04

It stays at 44. The number is loose and that does not matter, because a forcing
function only has to bite reliably rather than precisely. Its job is to be a smell
detector: when a queue will not fit one screen, that usually means rows are too
verbose or too many, and the owner wants to be told.

What changes is the message. Today the overflow line apologises for the tool:

    … +165 rows held by the height cap (--detail or --json shows all)

It should accuse the data and carry the measurement that proves it:

    … 165 rows did not fit. A queue this size usually means rows are too verbose
      or too many: median subject here is 97 chars and 100 rows carry no goal.

Same constraint, same number, but it now reports the finding rather than the
limitation.

## Open, needs the owner

Does a subject-length ceiling near 70 characters land, with the overflow moved to
notes automatically rather than rejected? And is a row carrying no goal malformed?

This has teeth: 100 of 181 open rows carry no goal, and a further 38 carry a
batch with no goal, which are stages belonging to an outcome nobody wrote down.
Containment cannot attach those under any reading of the milestone rule, so they
need a decision rather than a mapping.

## The seven rulings, 2026-09-04

Answered on decision page `tasks-redesign-0904`.

| # | Question | Ruling |
|---|---|---|
| D1 | Which layout | **c**, Variant F: bordered goal panels with one internal divider |
| D2 | Subject ceiling | **a**, 70 characters, overflow moves to notes automatically |
| D3 | A row with no goal | **b**, allow it, render it in a loud UNFILED band |
| D4 | Build the dialog hook | **a**, now, blocking, with mutation tests |
| D5 | The goal store | **b**, separate change, queued as #8 #9 #10 |
| D6 | Milestone arity | **a**, three levels always, milestone mandatory |
| D7 | The residual state | **a**, `unassigned` |

**D1 note, verbatim:** "use colored ball emojis to call out blockers if helps,
call out different tasks with SOME indicator at least, the kanban is the worst
plus use column for one trait only (no stacking of lane / model / other tags in
a single col)"

The last clause is the sharpest and the current renderer violates it. It packs
`hands·opus` into one column and `fix · tasks` into another. Both split.

**D5 note, verbatim:** "And then do some testing to ensure it works fine."

## The "other fixes" goal: the call the owner asked me to take

His words: "if the agent decides to make a 'other fixes' as a goal after all
the main behavior changes are done that is fine I think? Validate me and take a
call."

**My call is no, with one carve-out, and I think he is half right.**

Against it. A goal names a behavioural change; that is his own ruling, in
capitals: "I CARE ABOUT GOALS BEING DONE AGAINST THEIR MEANINGFUL BEHAVIORIAL
INDENDED CHANGE". "Other fixes" names no change. It is a bucket, and the
measured data says buckets fill: 61 of 180 open rows in the big store already
carry neither a goal nor a milestone. Give those a legal home and 61 rows live
there permanently, which rebuilds the 181-row queue this redesign exists to
kill. It would also defeat the closure rule, because a goal that never has a
behavioural definition can never be met, so it accumulates forever and the
header's "1/2 goals met" quietly stops meaning anything.

Where he is right. Some work genuinely does not carry its own headline
behaviour, and pretending otherwise invents goals that are worse than a bucket.
Two homes already exist for it and neither is a new goal:

- **A milestone under the goal it serves.** Small cleanups at the end of a
  goal are a state of that goal, not a separate outcome. "Right now, the rough
  edges are gone" parses as true or false, which is the milestone naming test
  from the section above. That is where end-of-goal tidying belongs.
- **`proposals.jsonl`.** His own rule for what earns a row: a discovery that
  outlives its goal is a proposal, not a task. That is the sweep D3b's UNFILED
  band feeds.

So the UNFILED band is a holding pen, not a home. A row sits there visibly
until it is filed under a real goal or swept to proposals. If it can be neither,
it was never work.

**What would change my mind**, stated so this is falsifiable rather than a
preference: if after one full pass the UNFILED band is still non-empty and every
row in it resists both homes, the bucket is real and the model is missing a
level. Check it on the band's own contents, not by argument.

# /tasks redesign: the model, ruled 2026-09-04

Status: the model is ruled, the renderer is not built. One question stays open at
the bottom. Nothing here is implemented yet.

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

## Open, needs the owner

Is goal, milestone, task a fixed three levels, or may a goal hold tasks directly
when it has no meaningful stages? Everything above is written assuming milestones
are always present; the answer changes the renderer's grouping and the containment
rule's arity.

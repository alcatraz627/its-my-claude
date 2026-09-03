---
brief: Every agent hands the owner a `/goal <text>` paste line whenever it starts something, before the work, not after. The line is bare on its own line so selecting it copies clean. Every clause must be one the agent can finish alone, because an armed goal is a Stop condition and a clause whose actor is the owner blocks every stop until he disarms it by hand.
triggers:
  - topic:goal
  - topic:starting-work
  - phrase:"arm a goal"
  - phrase:"what are you working on"
  - tool:goal.sh
related:
  - rules/communication.md
  - rules/owner-decisions-go-through-a-wizard.md
  - features/context-retention.md
tier: 1
category: rules
updated: 2026-08-30
stale_after_days: 180
---

# Give the owner a goal statement to arm, whenever you start something

Owner instruction, 2026-08-30, verbatim: "Add a rule so that every agent gives
me a goal statement to arm whenever starting something."

So: when you begin a piece of work, hand him the line that arms it. Not a
summary of what you intend, and not a question about whether to proceed. One
pasteable command he can accept or ignore.

## The shape

Print it bare, on its own line, with no rail character, no bullet and no
surrounding backtick-free prose on the same line, so that selecting it copies
clean text:

```
/goal <the goal, one line>
```

`bash ~/.claude/scripts/goal/goal.sh armline` emits exactly this from the
stored goal, and `goal.sh box` wraps it in the 🎯 surface the owner has said
he likes. Prefer those over hand-typing the line.

## When it fires

- Starting a task, a plan, a build, an investigation, a review.
- Resuming one after `/clear` or `/compact` (the `/catchup` skill already does
  this; this rule is the general case that skill was a special case of).
- Being handed new work mid-session, including by another agent.

It does not fire on a one-line answer, a lookup, or a continuation of work
whose goal is already armed and unchanged.

## A few short statements, each true or false on its own

Write a small number of short declarative sentences. Each one names a concrete
state: an environment, an artifact, a check, a threshold. A reader should be able
to take any single sentence and say whether it currently holds.

The owner's own goals never carry a ticket number, a filename, or a count.
Measured across 42 goal records on 2026-09-01, his are 0% enumerative and the
agent's are 25%. His best one reads:

> A nontechnical teammate gets one real JEGS workbook through the console alone:
> upload, preview, run, read the results, export. No step needs me.

Two registers fail, in opposite directions.

**A queue wearing a goal's punctuation.** "Fix all 14 findings (H1..L5), then
continue REMAINING-WORK.md" is met the moment the boxes are ticked, whether or
not anything got better. Avoid it.

**One long behavioural sentence.** Over-correcting away from the checklist
produces flowing prose where the tangible parts blur together. Owner ruling
2026-09-04, verbatim: "Rephrase your goal as simpler statements about the goal,
not this prose. I think you're going too subjective into making the goal
behavioral, to the point of making the tangible parts blurry."

### Worked example

Before, from forge-console's walmart goal (gcc goal store, session `70ca5d40`,
set 2026-09-03). One paragraph, seven clauses, and no single sentence a reader
can check:

> Level 4 is closed in the runner's own suite. Every one of the nine checks is
> proven by a planted defect that turns its test red and is then restored, not by
> inspection. A caller key with no capability list is visible rather than silent.
> Keystore list and revoke are driven through the CLI. Punctured output is gone:
> every row reaches a terminal state carrying a reason a person can read, a
> decline's reason survives to the surface, and a job held for a configuration
> problem says so at the job level rather than only per row.

After. Same work, same outcomes, each line standing alone:

> The runner suite is green at head.
> All nine Level 4 checks are mutation-proven, not inspected.
> A caller key with no capability list shows up instead of failing silently.
> Keystore list and revoke both run from the CLI.
> Every row ends in a terminal state with a reason a person can read.
> A job held for a configuration problem says so at the job level.

Nothing was dropped. The second version is checkable line by line, and a reader
who knows the system can mark each one today.

### How many

Three to six lines is the usual range. One line is fine when the work is one
thing. Past six, the goal has become the queue this section warns about, and the
extra lines belong in the task list.

### Short is not the same as checkable

Length was never the real test, and an earlier version of this section implied it
was. Three agents audited on 2026-09-04 all shipped short statements that no
reader can mark true. Two shapes do it, and both look compliant because they fit
on one line.

**An unbounded quantifier.** "Every way stage 7 can fail shows an operator what
happened." "No comment in the files I own describes behaviour the code does not
have." A reader cannot confirm these, only fail to find a counterexample.
forge-integration's own words: an unbounded quantifier makes a short sentence
exactly as uncheckable as a long one. Bound it. Name the three failure modes, or
the two files, and the line becomes checkable without getting longer.

**A standing behaviour instead of a state.** "Every question another lane sends
is answered the turn it arrives." That is true over a window, never at a moment,
so nobody can mark it at the time the goal is read. Convert it to the artifact or
the threshold that would show it happened.

The test to apply to each line: could someone who is not me sit down right now,
look at one named thing, and say yes or no? If they would have to search an
unbounded set, or watch for a while, rewrite it.

### Do not arm your own goal

`goal.sh set` is the owner's move. Print the paste line and work under your
proposal as stated intent; a goal you armed yourself is a Stop condition you
wrote for yourself. One session on 2026-09-04 armed its own with `--by agent`,
and the goal it armed carried a clause whose actor was the owner, which is the
trap the actor constraint above exists to prevent. The only exception stays the
one `/catchup` owns: a checkpoint goal marked STILL VALID is re-armed without
asking, because a previous session already judged it.

**A re-armed goal inherits its old register.** That same auto-re-arm carried a
long prose goal forward intact from a checkpoint. When re-arming, read the goal
against this section first, and if it fails, put the rewrite to the owner as a
paste line rather than reviving the shape.

## Every clause must be one YOU can finish alone

This is the part that is easy to get wrong and expensive when you do. An armed
goal is a **Stop condition**: the harness holds the turn open until the goal
reads as met. A clause whose actor is the owner therefore blocks every stop
until he disarms it by hand. One session took six stop rounds this way
(vb-fable, 2026-08-19).

**The constraint is on the ACTOR, not on the specificity.** This is the misreading
that produces checklists: "finishable alone" gets read as "self-scorable", so the
goal shrinks to things the agent can tick off. It does not follow. The JEGS goal
above has no owner-actor clause at all, so it satisfies this rule completely
while being purely behavioural. Ask only whether a clause requires the OWNER to
act. A behavioural outcome the agent can walk itself is always allowed, and is
the preferred shape. Recorded as `mist-20260901-100441-54` (S3), whose cause line
reads: "A real rule supplied cover."

So split the work at the handover:

- The agent half goes in the goal. "Draft X and put it to the owner."
- The owner half goes in the reply, as a blocked-on line. Never "get X
  approved", never "have the owner ratify Y".

## Propose, do not arm

Writing the gcc store is the agent's move only when a previous session's
checkpoint marked a goal STILL VALID (see `/catchup`). A goal you are
proposing for new work is the owner's to accept: print the paste line and
carry on working under it as your stated intent. Do not call
`goal.sh set` unasked.

## Diagnostic signal

You are three tool calls into something new and the owner has not been given a
line to arm. Or you have written a goal clause whose subject is him.

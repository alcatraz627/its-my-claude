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

## The goal names an outcome a person can recognise, not a checklist

Write what becomes true for someone when the work lands. The owner's own goals
never carry a ticket number, a filename, or a count; measured across 42 goal
records on 2026-09-01, his are 0% enumerative and the agent's are 25%. His best
one reads:

> A nontechnical teammate gets one real JEGS workbook through the console alone:
> upload, preview, run, read the results, export. No step needs me.

That is the register. "Fix all 14 findings (H1..L5), then continue
REMAINING-WORK.md" is the register to avoid: it is a queue with a goal's
punctuation, and it is met the moment the boxes are ticked whether or not
anything got better.

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

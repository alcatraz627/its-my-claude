# The Pager-Holder: on-call reader

The person who opens the doc to act, with a customer escalation open in the
other tab. Takes the alert, routes it, runs the procedure, escalates to the
right human, confirms the line is clear. Internal, technically literate, has
admin access. Will not design the system or write code in the moment. If the
doc needs either to be runnable, it has failed.

**Headline test:** can I run this at 2am, and do I know when it worked and
whom to call when it did not?

## Tone

Brisk and procedural. "Where is the actual command?", "what does success look
like?", "who do I page if this misfires?" A crisp runbook gets one line of
credit and no polish suggestions.

## Looks at first, in order

1. Title and "when to use this": am I in the right doc for my symptom?
2. Prerequisites: access, role, tools, environment, before step 1
3. The numbered steps: exact commands, paths, button labels
4. Verification: how I know it worked, in observable terms
5. The failure branch: what to do when step N fails midway
6. Escalation: who, on what channel, with what context
7. Rollback: can I undo, is it safe to retry
8. The concept section, last, and only if a step failed and I must improvise

## Lets pass

Long background sections if a link skips to the steps, architecture diagrams,
design history, terms defined before a step depends on them, up to about five
lines of framing before the first heading.

## Flags

- "You may want to" or "consider": is it a step or not?
- Silent branches: "if X, do Y" with no "if not, skip to step 6"
- Prerequisites revealed mid-procedure
- Placeholders with no line saying where to find the value
- Commands in prose instead of code blocks, pseudo-code instead of literal
  commands
- Verification in author voice: "you should see things working"
- Happy path and edge path mixed in one numbered list
- "Just run this", aspirational tense ("it will fire every 5 minutes" when it
  fires every 15), `TODO` in a published runbook
- "Ping engineering" with no channel, owner or fallback
- A procedure that requires writing code. That is a mis-shelved doc.

## Earns trust

A symptoms list at the top, a concrete prerequisites block, copy-ready
commands with variables called out, an expected observable per step, a
failure branch per risky step, "safe to retry" or "do not re-run" stated, a
real example with realistic IDs, a recent last-verified date.

## Quick fix or rewrite

Quick fix: add prerequisites, an observable on a step, an escalation block, a
last-verified date, promote commands to code blocks, fix one stale label.

Rewrite: organized around how the system works rather than what the operator
does, no procedure at all, several symptoms crammed into one doc with no
routing, or no named surface to verify against.

## Done criteria

1. A new on-call engineer in hour one of a first shift can run it end to end
   without messaging the author
2. Prerequisites up front
3. Every action step has an expected observable
4. At least one failure branch per risky step, or an explicit "escalate, do
   not improvise"
5. Escalation names channel, owner and the context to attach
6. Rollback and retry safety stated per action
7. Status, owner and last-verified date present and current
8. Reachable from the alert, schedule or admin page that would surface it

## Not this reader's job

System design, new tooling, the rewrite itself. Name an ops gap (no rollback
exists) without designing the fix. Also note, when relevant, what to tell the
customer who wrote in.

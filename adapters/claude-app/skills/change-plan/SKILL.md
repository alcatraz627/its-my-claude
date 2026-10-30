---
name: change-plan
description: Plans a code change before writing it. Every clause carries a command, a file:line or a named artifact, and "no build" is a valid result. For backend, refactor, migration or script work.
---

# Change plan

A plan where every clause can be checked. Each problem, directive and promise
has a command, a `file:line` or a named artifact behind it. The plan stops
before implementation, and it is allowed to say there is nothing to do.

A planner that can never recommend doing nothing will find a reason for
whatever it was pointed at. A plan that never writes down current behavior
cannot check that the behavior survived. These two rules carry most of the
value here.

## Get the code

Plan against code you can read: pasted, uploaded, or fetched through a GitHub
connector. Read the project's own conventions first, such as its README,
contributing notes or decision records. They outrank anything general here.
If the code you need is not available, name the files and ask for them before
planning against a guess.

## 1. Decide whether there is work at all

At least one of these must hold, with evidence:

1. **Behavior is wrong or missing.** A failing check, a reproduction, or a
   capability someone needs. Record the command and its current output.
2. **A cost is paid repeatedly.** Duplication with a count, a manual step on a
   schedule, a measured slowness. Record the number.
3. **A constraint is violated.** The code contradicts a documented decision, a
   contract or a schema.

If none holds, the plan says `no build` and stops. When the request carries
several problems, give each its own verdict. Some may already be solved by a
change that landed since the request was written. Say which change closed them.

## 2. Name the class

Pick one. The class decides what the plan needs most.

| Class | What it is | What it needs most |
|---|---|---|
| Behavior | changes what the system does | parity ledger, reproduction first |
| Structure | same behavior, new shape (refactor, extraction, rename) | parity ledger is the whole job |
| Capability | something new | how the repo already does this, contract skeleton |
| Migration | moves data from one form to another | reversibility, a dry run on a sample |
| Removal | deletes a path or feature | every reader found, quarantine before delete |

When two seem to fit, it is usually two changes. Say so and plan the first.

## 3. Write down current behavior

For anything that already exists, write one paragraph first: what it does
today, who depends on it, and where that is visible as a `file:line` or a
command. Derive it by reading, not from memory, and say which parts you could
not establish. For new work, say "greenfield" rather than skipping this.

## 4. State each problem as a triple

| Field | Content |
|---|---|
| Observation | a `file:line` with a symbol name, or a command and its output. Never an adjective. |
| Cost | what breaks, who it reaches, how often |
| Check | the command or artifact whose result flips when this is done |

Not admissible: "the job runner is fragile."
Admissible: "`runner.py:88` (`run_job`) retries on any exception, so a
malformed payload retries forever and the queue stalls. Check: a malformed row
lands in the dead-letter table after one attempt."

Wishes go in a separate appendix the plan does not authorize. That appendix is
what stops a fix becoming a rewrite. Odd things with a plausible innocent
explanation go in a "watch" list, never among the problems.

## 5. Inherit before designing

Find how this codebase already solves the same shape. Search the whole tree,
because the earlier author put the answer where it was needed, not where it
belongs. One row per decision the change touches:

| Decision | How the repo does it | Evidence | Adopt or deviate | Reason if deviating |
|---|---|---|---|---|

Rows worth forcing: error handling, retries, logging, config reads, database
access and transactions, background work, validation, and test layout. An empty
search is a finding. It means the change sets precedent, so mark the row as new
precedent for the user to see.

## 6. The parity ledger

List what must still be true after the change. Every row gets a check that
would fail if that behavior were lost.

| Must still hold | Why it matters | Check that catches its loss |
|---|---|---|

Fill it from what exists: current tests, callers of anything you touch, the
documented contract, and comments that mark behavior as deliberate. A rebuild
that replaces working behavior with no record of the old version is the
failure this table prevents. For a Structure change, this ledger is the whole
plan.

## 7. Directives with checks

| ID | Directive | Check | Source |
|---|---|---|---|
| D1 | imperative statement | command or artifact whose result flips | problem or parity row |

A directive without a runnable check is a wish. Mark which directives come
from the parity ledger, so a reader can tell what the change adds from what it
must not break.

## 8. Skeleton and first running slice

The skeleton is the contract: signatures, data shapes, module boundaries, and
what calls what. Write it so a reviewer can argue with it before any code
exists.

The first running slice is the smallest end-to-end path that executes and can
be observed. Name the command that runs it and the output that proves it
worked. If it can run in the code sandbox, run it there. Otherwise give the
user the command and say what a pass and a fail look like.

Size both to the change. Reuse what the repo has, then the standard library,
then a dependency, and stop at the first that holds. Do not add a helper for a
caller that does not exist yet.

## 9. Emit, then stop

Title sections by the question they answer, not by the step names above. The
plan carries, in order: the work verdict with its evidence, the class, current
behavior, the problems, the parity ledger, the directives, the skeleton, the
first slice, then sequencing and what the change must not touch.

Offer the plan as an artifact when it is long, so it outlives the chat. Then
stop for the user's ruling. Questions the plan cannot settle go to
`decision-bundle`.

## Not for

- A one-line fix or a typo. Do it.
- Explaining how the code works today. That is `arch-qa`.
- Choosing between approaches you already understand. That is `council`.

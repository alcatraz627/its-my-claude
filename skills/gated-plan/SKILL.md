---
name: gated-plan
description: The planning process for owner-gated work, meaning anything that cannot correctly proceed until a human decides. Investigates until it can falsify its own proposal, plans with alternatives and an explicit recommendation, batches every open question into ONE decision-grade bundle the human answers in a single pass, records each ruling in the artifact it binds rather than in chat, then implements and reports. Use when work is blocked on a judgment only the owner can make, when questions are accumulating faster than answers, when a plan says "awaiting ruling", or when a previous deferral is about to be silently resolved by momentum. Not for work you are authorized to just do.
argument-hint: "[the gated work]"
user-invokable: true
---

## Brief

Runs owner-gated work end to end, where the hinge is a decision only a human
can make. Investigates until it can falsify its own proposal, plans with real
alternatives and a recommendation, batches every open question into one
decision-grade bundle answerable in a single pass, records each ruling in the
artifact it binds, then builds only what was ruled and reports item by item.
Composes with `/decision-wizard` as its answer surface and `/bloop` as its
build phase.

# gated-plan

The loop for work whose hinge is a human decision: **investigate, plan,
bundle, rule, bind, build, report.**

**The one rule everything else serves:** the owner's attention is the scarce
resource, so every question you hand them arrives already answered. Context,
options, and your recommendation, in one pass, so a ruling costs them one read
and one word.

That rule comes from a measured failure. Asking the owner to approve thirteen
hours of scope using shorthand labels from a document they had never seen is a
recorded S3 in this account, twice in one week (atone
`decision-request-without-decision-grade-context`). The questions were real.
The asking was worthless, because answering them required work the asker had
already done and did not share.

## When to use

- A plan or spec that says "awaiting owner ruling", "needs the owner", or "I am
  not resolving this here"
- Questions accumulating while work continues around them
- A design conflict between two authorities (a canon doc and a fresh ruling)
- Any scope the owner has not seen, before building it
- A deferral from an earlier session that a later message merely brushes
  against, which is not re-authorization

## When NOT to use

- Work you are authorized to just do. Do it.
- A single question with an obvious default. Pick it, say so, move.
- The build itself once ruled. That is `/bloop`, which this loop hands off to.
- A UI page renovation plan specifically. That is `/build-ui`, which is this
  loop's plan phase specialized to one domain.
- Collecting the answers. That is `/decision-wizard`, this loop's phase-3
  surface, not a replacement for the loop.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for the whole run. Also read
`~/.claude/skills/gated-plan/runtime-notes.md` if it exists.

## Phase 1: investigate until you can falsify yourself

Investigation is finished when you have tried to kill your own proposal and
failed, not when you have gathered enough to write it.

1. **Read the destination before proposing anything for it.** Whatever tree,
   doc, module, or surface will receive the work: read what it already says.
   This routinely kills your own items. A kit-canon promotion list of eight
   lost four to "the canon already says this" and a fifth to a grep, before
   the proposal was ever sent.
2. **Grep every absence claim.** "There is no X", "nothing covers Y", "this is
   missing" are existence claims and need existence-disproving evidence
   (`rules/grep-scope-before-claiming-absence.md`). The claim that survives a
   full-tree grep is worth stating; the one that does not would have been a
   duplicate.
3. **Name the authorities and check them against each other.** A fresh verbal
   ruling can contradict a written canon. That contradiction is itself a
   decision for the bundle, not something to resolve by picking the one you
   heard most recently.
4. **Re-verify anything you are about to report as state.** Status decays
   faster than code: deploys land, peers commit, registries move. Re-read
   before asserting.

## Phase 2: plan with alternatives and a recommendation

Write the plan where the work will happen, not in chat. Each open choice gets
its real alternatives and your pick, with the reason.

**Exemplar first.** When the plan covers N similar items, build ONE completely,
put it in front of the reviewer, and hold the other N-1 until it comes back.
The exemplar earns corrections that would otherwise have been made N times. A
ten-document set that reviewed its first document caught the shape, the depth
ceiling, and a stale gap line before nine more inherited them.

**Say what stays unchanged, and make it a constraint.** Any claim that existing
behavior survives the change ("only threading needed", "the UI stays") binds
nobody until it becomes a verification task with a named check
(`rules/invariant-graduation.md`). Mixed framing between threading and
rebuilding gets resolved with the owner before implementation, never by
whichever reading has momentum.

## Phase 3: bundle the decisions

Not one question at a time, and not a list of question marks. One artifact,
every open decision, each carrying:

| Part           | What it must contain                                                                                         |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| Context        | enough that answering needs no other document open, including verbatim quotes of any conflicting authorities |
| Options        | the real alternatives, usually two or three, each with its consequence                                       |
| Recommendation | yours, first in the list, with the reason in one sentence                                                    |

Then say where the answer will land. A ruling with no destination becomes a
chat message nobody can find in a week.

Deliver it as an artifact with a stable path, link it from the project's status
board, and offer `/decision-wizard` as the surface when the count is high or
the items are per-item judgments. Keep asking cheap: batch at milestones rather
than interrupting, and halt only at genuinely hard gates.

**Cost the wait.** If some items block work and others do not, say which, so
the owner knows what a delayed answer stalls.

## Phase 4: bind the ruling

A ruling is not recorded until it lives in the artifact it governs.

1. **Write it into the binding doc**, in the owner's own words where the
   wording carries the constraint. A deviation clause quoted exactly ("only if
   the rule-breakage leads to a better and more consistent UX, with good
   reasoning") survives summarization; a paraphrase does not.
2. **Convert the resolved conflict into resolved text.** The spec that recorded
   "this needs the owner and I am not resolving it here" now records what was
   ruled and what it replaced. Leaving the conflict text in place invites the
   next reader to re-litigate a settled call.
3. **Stamp the bundle** with what each ruling was and where it landed, so the
   ask and the answer stay one artifact.
4. **Update the status board** so the next session sees the ruling without
   reading the bundle.
5. **Carry the un-ruled items forward explicitly.** Anything the owner did not
   answer stays open and named, never quietly adopted as a default.

## Phase 5: build, verify, report

Hand the build to `/bloop` when it warrants the gate, or do it inline when it
does not. Two rules specific to post-ruling work:

- **Build only what was ruled.** A ruling on four questions authorizes four
  answers, not the adjacent improvements you noticed while waiting.
- **Report against the ruling, item by item.** The owner's memory of what they
  approved is the spec you are measured against, so show each ruling and what
  it produced.

## Anti-patterns

- **The naked question.** "Should we do A or B?" with no context, no
  consequence, no recommendation. The S3 this skill exists to prevent.
- **The drip.** Five questions across five messages instead of one bundle.
- **Momentum as authorization.** A deferred item that a later message brushes
  against is still deferred (`rules/communication.md`).
- **The unbound ruling.** Answered in chat, recorded nowhere, gone by the next
  session.
- **Building past the ruling.** Answering four questions and shipping seven
  changes.
- **Investigation that only confirms.** If nothing in your plan died during
  phase 1, you were collecting support, not investigating.

## Post-run

Prepend a short note to `~/.claude/skills/gated-plan/runtime-notes.md` (purpose
plus two to four insights) when a run surfaced something reusable: a bundle
format that got a faster ruling, a binding location that kept a constraint
alive, a deferral that decayed anyway.

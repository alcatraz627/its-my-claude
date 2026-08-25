# Trial 01: what a stranger did with the board, and what it cost them

A sonnet agent that had never seen this app was asked to plan a product and
track it here. It planned "Chime", a personal alarms and scheduling app: a
vision, a PRD, a sprint plan over four milestones, and a changelog simulating
two weeks of plan churn. Then it put the whole thing on the board.

It was told not to read this app's source or docs. `kanban.sh` with no
arguments, its own help, and the board in a browser were its entire manual.
That constraint is the experiment: everything below is what the tool teaches a
competent stranger by itself.

Its own feedback is at `design/TRIAL-01-FEEDBACK.md`, unedited. The audit
tool is `test/board-usage-audit.py`, written before its board was read.

---

## The homework, measured

25 cards of its own, on top of the 14 feature-demo cards it was told to leave
alone (and did).

| Check | Result | Read |
|---|---|---|
| Titles | 12/25 over 56 chars, **12 carry a brief** | It found `brief` unprompted and used it on exactly the long ones |
| Tags | 25/25 tagged, 3 per card, kinds `milestone` `priority` `area` | Coherent and restrained; no card over-tagged |
| Kinds unused | `class` `effort` `risk` `tier` | Four of seven never touched |
| Goals | **25/25 carry one**, and they are reasons | "Every other engine feature depends on this shape being right first" |
| Milestones | 6, partitioning **25/25 cards** | Nothing unplaced |
| `after` | **22/25 declare a predecessor** | It read the dependency model and used it properly |
| Verify | 9/25 graded, 7 executed 2 reasoned, 2 need a human | Used where it had something to claim |
| Docs linked | 8/25 | |
| Lanes | backlog 14 · active 2 · blocked 1 · done 7 · **stale 1** | Distributed, not parked |
| Notes | **0** | |
| Decisions | 3 recorded | |
| Views | 5 named | |

**This is better board usage than most sessions manage**, including mine. Goals
on every card, a milestone partition with nothing left out, and 22 dependency
chains are not what a first-time user usually produces. Three things stand out.

**It used `stale` deliberately and explained why.** When the plan cut "Focus
mode integration", it moved the card to `stale` rather than dropping it,
because "the historical record of a genuine cut survives, rather than
disappearing the way a manual drop does". That is the lane's intent, arrived at
without being told.

**It mapped the PRD's open questions onto `verify --needs-human`**, which is a
use nobody designed and it is right: a question that blocks a card is a card
the agent cannot close alone.

**It never wrote a note.** Zero of 25. Correctly, as it explains: notes are the
owner-to-agent channel and no owner was present. But it means the single most
load-bearing surface in the app went unexercised by this trial.

---

## Where the tool actually failed it

Four findings, in its words, with my verification.

### 1. A milestone is a tag, and a sprint plan needs an object
Its sharpest finding. Milestones are the backbone of its plan: they have an
order, a goal sentence, and a done state. The board gives only
`tag milestone:m2`, a string with no ordering, no goal of its own, and no way
to say M1 is closed. So it expressed "M1 shipped" by moving seven cards to
`done` one at a time, and the one-line goal it wrote for each milestone lives
only in `sprint-plan.md`, unreachable from the board.

**I agree, and it is the strongest argument yet for a `milestone` kind rather
than a tag kind.** The registry exists precisely to make that cheap.

### 2. A plan change is not a first-class thing
`plan-changes.md` records four kinds of change with reasoning. The board has no
shape for "this is a change to the plan and here is what it touched". It could
build views for "P0 open" and "needs a decision" but not for "what changed
since last week", because a card records no dated, annotated fact that it was
affected by a change. It approximated with tags and a linked doc.

**Notable because the board's whole premise is mirroring plans that move.**

### 3. A split task cannot say what it split from
When one card became two, `after` captured the dependency but not the sibling
relationship. Dependency and "these were one thing" are different claims and
only the first exists. It faked the rest with a shared `area:` tag.

### 4. A cross-cutting decision has nowhere to live
Two of the PRD's four open questions block no single card; they touch several a
little each. **It represented them nowhere rather than force-fit them.** So the
board is missing two real open questions and looks complete.

This one is now half-fixed by accident: `kanban.sh decide add` landed today and
is exactly a board-level decision owned by no card. The trial did not have it
when it hit the problem, and it found `decide` afterwards, using it three times.

---

## What I fixed while reading this

**`plan list` was showing another board's plans as if they were yours.** The
trial reported the mild version, that `plan` is missing from the help and bare
`plan` returns "what reads like an unrelated cross-project decision listing".
Verified standing in its project: bare `plan` listed **eight plans belonging to
`-claude-244ec6`** with nothing marking them foreign. A first-time user is
handed another project's documents and cannot tell.

Fixed: `plan list` scopes to the board you are in, says so when empty, and
points at `--all`. `plan` and `decide` are both in the bare help now, which is
where the trial looked and found nothing. It only discovered `plan` at all by
typing a command the sidebar suggested.

---

## Its ranked asks, and my verdict

| # | Ask | Verdict |
|---|---|---|
| 1 | Milestone as a real object | **Agreed, queue it.** A kind, not a tag. Registry makes it cheap. |
| 2 | Make `after` navigable, not just countable | **Agreed, small.** Clicking `after 1` should show which card, the way a tag does. |
| 3 | `add --json` | **Agreed, trivial.** Matches `show` and `status`; it had to regex prose out of stdout to script a batch. |
| 4 | Explain a harvest miss | **Agreed.** Zero cards from a scanned file reports identically to "nothing changed". It had to diff two files to work out why. |
| 5 | Document `plan`, fix its scoping | **Done today.** |
| 6 | Batch `tag` | **Agreed, trivial.** `after` already takes many ids. |

Nothing here is a redesign. Five are an afternoon; the first is a real build
and it is the one worth doing.

---

## What the trial did not test

Stated plainly, because a trial that hides its blind spots is worse than none.

- **Notes, the owner-to-agent channel.** Zero used. No owner was present.
- **Asks, drafts, `classify`, `selected`.** Same reason: nothing arrived
  mid-stream to sort.
- **The multi-agent case.** One agent, one board. The app exists for one human
  against many agents, and this trial had one of each.
- **Living with it.** It built a board in one sitting. Every finding is about
  first contact, and none is about the board on day thirty.

The next trial should have an owner in it, because the untested surfaces are
the ones the app is actually for.

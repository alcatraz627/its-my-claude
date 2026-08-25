# Ideation 01, scoped: what is actually worth building

The cut of `IDEATION-01.md`, made 2026-08-25 at the owner's instruction. The
ideation is a good document and most of it should not be built. That is not a
criticism of it; ideation that only proposes affordable things is not ideation.

**The bar, in the owner's words:** *"it's about the benefit and code change and
testing and feedback is a detriment for a personal project"*. So every unit
below is judged on four things, and cost counts against it four times:

| Axis | The question |
|---|---|
| Benefit | Does it move the exchange cost, or does it move a feeling |
| Churn | How much working code is rewritten rather than added to |
| Testing | Can it be verified by running one thing, or does it need a fixture |
| Reversal | If it is wrong, is backing out a revert or a migration |

A personal project has no users to amortise churn across. Rewriting something
that works is pure cost here, which is why the largest single item in the
ideation is pruned below rather than scheduled.

---

## The goals the ideation lays out

It never numbers them, so these are derived from its own §1 and carried through
its sections. Every unit below is tagged with one.

- **G1 · Front door.** One place that says what is owed to the owner right now,
  so finding the work is not itself work.
- **G2 · Land while hot.** An answer's value decays with the asking session's
  context. Spend the owner's minutes where context still exists.
- **G3 · Evidence per glance.** Half the traffic is verification, not
  communication. A claim cheap to check deletes an exchange outright.
- **G4 · Closure.** A ruling should report what it caused, not only what was
  said.
- **G5 · Quiet by default.** The app should own three moments in the day and be
  absent from the rest.
- **G6 · Honest about itself.** Including about its own numbers, and about the
  difference between empty and broken.

---

## Phase 0 · Do now. Cheap, and each one stands alone.

Nothing here needs anything else here. Each is a day or less and each is a
revert rather than a migration if it turns out wrong.

### P0.1 · Answer-while-hot ordering · G2 · from §4.2 · **BUILT 2026-08-25**
The taxonomy has liveness (`livePeers`) and pendingness (decisions, asks) and
never joins them. Derive a reachability on every owed item: reaches a live
session, or waits for the next one. Sort hot above old-and-cold.
**Benefit high, churn near zero.** One read-time join, no new storage, no
schema. It is the only item in the whole document that converts minutes the
owner already spends into better outcomes without asking for more of them.
Ship the honest version the ideation itself insists on: "seen alive 4m ago",
never a bare "live", because the charter already records a 21-hour-dead
session reading as live.

**Built.** `seenAgoByAlias()` reads `last_seen` per alias (never the `status`
column, which lies), `reachOf()` classifies hot inside 30 minutes, and a
decision carries `reach: {state, seenAgo}`. `kanban.sh decide add` records who
raised it. Pending sorts before ruled, and hot before cold within pending. The
board row gets a green dot and a tooltip that says "gcc-kanban was seen 16m
ago, so an answer still reaches it" or "has gone cold; answering costs it a
re-brief". Verified by seeding one decision from a live alias and one from an
invented one: hot, cold, and unknown for a decision with no raiser.

### P0.2 · Provenance weight on card faces · G3 · from §4.5
A harvested-and-untouched card, a manual card, and a card the owner has
touched are three different claims on attention wearing one face. The data
already knows (`via`, `source`, notes).
**Benefit high, churn zero.** It is a density rule in CSS. The `.claude`
board's 140-card Active lane becomes legible without deleting anything, and
the board stops implying the owner is 140 items behind when they are nine.
Nothing is hidden; weight is not existence, so the tombstone and override laws
are untouched.

### P0.3 · Split charter law 11 · G6 · from §5.1
Today: a control that cannot act is hidden, not greyed. The ideation is right
that this conflates two cases. Irrelevant stays hidden. **Unavailable becomes
visible, quiet, with a tooltip saying why and when it returns.**
**Benefit real, churn near zero.** It is a charter amendment plus tooltips.
It also converges with the owner's own §5.2 ruling the same day: a thing that
vanishes is indistinguishable from a thing that broke. Two independent routes
to one principle is the strongest signal in the document.

### P0.4 · Reconcile the sessions doc conflict · G6 · from §5.4
`CHAT-HISTORY.md:69` rules a hub Sessions tab out. The 2026-08-25 D1b ruling
brings one in. `REMAINING-WORK.md` notes the delta; the plan doc still carries
the old sentence.
**Benefit: prevents building the wrong thing. Churn: one paragraph.** Whoever
builds `#14` reads one of the two first and there is a coin flip in it.

### P0.5 · `kanban.sh ask` for the human · G1 · the cheap slice of §4.11
The ask is deliberately the cheapest write in the system and still costs a page
visit. The ideation's global-hotkey capture is out-of-app and out of scope; a
CLI verb the owner can type from any terminal is one verb.
**Benefit real, churn one verb.** Right now a text file beats the app for
capture, which means thoughts leak out of the system that exists to hold them.

---

## Phase 1 · Do next. Each earns its cost, none is a rewrite.

### P1.1 · The owed item, derived, WITHOUT the queue UI · G1 · the cut half of §4.1
The ideation wants a queue as the front door. That is Phase 2. What is worth
having now is the thing underneath it: one aggregator over the kind registry's
own adapters that answers "what awaits the owner, since when, blocking what".
Serve it at `/api/owed` and read it with `kanban.sh owed`.
**Why the cut:** the derivation is the reusable half and costs one aggregator.
The queue UI is the expensive half, and it is expensive for a reason the
ideation understates, see P2.1. Building the derivation first means the hub's
existing tiers, the navbar count, the nudge and the session-start line all read
one number instead of four partial ones, which is most of the benefit for a
fraction of the cost.

### P1.2 · Delivery receipts, the mechanical leg only · G4 · from §4.3
Notes have `ack`. Answers do not, so nobody knows whether an answer was ever
read. Record answered, then read-by-an-agent, using the ack pattern verbatim.
An answer no agent has read after a day re-enters the owed list.
**Scoped down:** the ideation's third state, acted-with-a-reference, is
agent-reported and therefore a claim, which means law 1 rendering and a whole
trust surface. Do the first two states, which are mechanical and true. Leave
the third with §4.9, both in Phase 2.

### P1.3 · Defer with a horizon · G1 · from §4.4
`deferredAt` exists and means "not now" forever. A deferral that names its
horizon leaves the list and comes back at it.
**Benefit: it is the thing that stops P1.1 silting up and dying the inbox
death. Churn: one optional field, one rule, one dropdown.** Do it with P1.1 or
not at all; a list that only accumulates is worse than no list.

### P1.4 · Name the day model · G5 · the free half of §4.7
The ideation's own line is the useful part: naming the model matters more than
any of its three pieces, because it gives every future "should this notify"
question a rule. Write the three moments into the charter: morning is the owed
list, deep work is one number on the menu bar and nothing else, evening is the
delta digest.
**Benefit: every future notification decision has an answer. Churn: a charter
section.** The pieces (beacon, interrupt flag, digest) stay unscheduled.

---

## Phase 2 · Real work, and only once something proves it is needed.

### P2.1 · The queue as front door · G1 · §2.1, Direction A
The ideation's own top pick. "Every row answerable in place" means an inline
answer control per kind. **Two exist today**, not one: the decision page, and
the card-bound ask that `askOf()` renders in the board's drawer
(`lib.ts:106`, used in `board.html` and `server.ts`). So the queue's cost is
lower than a first read suggests, and correspondingly §4.8's merge argument is
stronger than a first read suggests, because those two are the same entity
already implemented twice.
**Verdict: after P1.1 has run for a while.** If the owed list gets read daily
and the friction is "I have to go somewhere to answer", the queue is earned by
evidence. If it does not get read, the queue would not have been either.

### P2.2 · Lane aggregation at scale · G3 · §4.6
Grouped mode when a lane passes its soft limit.
**Verdict: hold, because P0.2 attacks the same pain for free.** If provenance
weight makes the 140-card lane legible, this is not needed. Re-ask after P0.2
has been lived with, not before.

### P2.3 · Closure line on rulings · G4 · §4.9
Rides entirely on the acted-with-reference state deferred out of P1.2.

### P2.4 · The load meter · G6 · §4.10
One quiet line: exchanges this week, median hours a decision waited, asks never
sorted. Genuinely valuable, since an app whose thesis is a number should be
able to say the number.
**Verdict: after P1.1**, which is what would make the data exist. Cheap then,
impossible now.

### P2.5 · Kind tabs fold at N · G6 · §5.3
The strip grows a tab per noun forever and collides with the one-bar ruling at
a knowable width. The ideation is right and it is not today's problem: five
kinds fit. **Record the rule now, build the fold when sessions makes it six.**

---

## Pruned

### X.1 · Unify the two Decision primitives · §4.8
The ideation's second-ranked pick, and the one I most disagree with.

Its argument is real: the card-bound ask and the decision page are the same
entity at N=1 and N=many, and merging gets more expensive over time. Its own
cost line is honest: two answer stores merge, the byte-compatible answer-string
contract must survive verbatim, and the CLI loses a verb family.

**Pruned anyway, on the owner's bar.** Both implementations work. A merge
produces no behaviour the owner can see, rewrites two working state machines,
and its whole payoff is a cost avoided in a future that requires P2.1 to
arrive. That is churn plus testing plus zero feedback, which is three of the
four axes against and the fourth neutral. The honest counter to "in six months
this is a migration nobody schedules" is that in six months it may not need
scheduling, because the queue that would have forced it may never be built.

**Where the ideation has the better of me:** I first wrote that only one inline
answer control existed, which would have made the queue expensive and the merge
optional. Checking the code, two exist (`lib.ts:106` and the decision page), so
the duplication §4.8 names is already real rather than prospective. That is a
genuine point against pruning. It does not flip the verdict on a personal
project's bar, because duplication that costs nothing today still buys nothing
today, but it does mean this should be the FIRST thing reconsidered the moment
P2.1 is on the table, rather than a nice-to-have then.

Revisit only as a prerequisite of P2.1, and if P2.1 is never earned, this is
correctly never done.

### X.2 · Retire or auto-hide the empty Inbox lane · §5.2
**Owner ruled 2026-08-25:** *"I wouldn't even know if its supposed to be there
/ or if it is broken, it will disappear. Let's keep it."* Recorded in charter
§12. My own suggestion to hide it when empty is refused by the same ruling and
is also pruned. The proposal was a NORMATIVE challenge costing sync, the CLI
and every per-lane pref; the ruling ends it.

### X.3 · Directions B and C as builds · §2.2, §2.3
The room-and-strip and the correspondence are good framings and neither is a
build order. Their useful content already lands inside P0.2 (weight), P1.1
(what is owed) and P2.1 (the front door). Kept as reading, not scheduled.

### X.4 · Global capture hotkey · §4.11
Mostly out-of-app code, a system-wide hotkey and a summoned composer. P0.5
takes the slice that is one CLI verb and leaves the rest.

---

## The order, if you only follow one list

1. P0.1 answer-while-hot, P0.2 provenance weight, P0.3 law 11, P0.4 the doc
   conflict, P0.5 `ask` from the CLI. Five small things, no dependencies.
2. P1.1 the owed derivation, with P1.3 defer-with-horizon in the same change,
   because a list that only grows is worse than no list. Then P1.2 receipts,
   P1.4 the day model.
3. Stop. Live with it. P2 is earned by evidence from P1, or it is not earned.

**What this cut deliberately gives up:** the front door. That is the
ideation's central idea and the thing it argues hardest for, and it is the
right call to defer, because P1.1 delivers most of its value and all of its
data at a fraction of its cost. If the owed list gets read every morning, the
queue is obviously next and will build itself against real usage rather than
against a guess.

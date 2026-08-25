# Ideation 01: one person's attention, many agents

Written 2026-08-25 against `design/HANDOFF.md` and `design/SYSTEM.md`, the live
app at :5106 (hub, the 231-card `.claude` board, the drawer, the asks view,
drafts, and the answered `kanban-six-calls` decision page, all looked at in the
browser), `UI-CHARTER.md`, `FEEDBACK-CLASSES.md`, `REMAINING-WORK.md`,
`CHAT-HISTORY.md`, `UNIFIED-SURFACES.md`, `SEARCH-DESIGN.md`, `ANSWER-PATH.md`,
`NAV-UNIFICATION.md`, and `kinds.js`. Ideation only; nothing here edits anything.

---

## 1. What this app actually is

It is not a kanban board with extras. It is an asynchronous exchange system
between one human and many agents, with a state mirror attached. Every surface
carries traffic in one of two directions: agent to owner (a decision page, a
needs-you card, a claim on a card face, a preview) or owner to agent (an ask, a
note, an answer, a ruling on a plan, a pulled draft). The board is the shared
table both sides read; the CLI is the agent's chair at it. The scarce resource
is the owner's attention, and the unit of work is an exchange: something one
side owes the other. The number a design must move is the cost of an exchange
times the number of exchanges, and the latency asymmetry underneath it: agents
answer in seconds and wait in hours, the owner answers in hours and waits in
seconds.

The app's best invention already exists and is confined to one kind. The
decision page's contract, everything pre-answered, untouched means agreed, only
deviations serialize, is the cheapest known form of the owner saying N things.
That pattern is the app's genome and almost nothing else has inherited it yet.
An ask, a needs-you card, a stale mirror, a gone root all still cost a visit, a
read, and a composed reply.

Two more things the owner's framing implies but does not say. First, the nav is
organized by artifact kind (boards, asks, drafts, decisions, previews) while
the owner arrives with one of three questions: what needs me, where does X
stand, what did we say. Kinds are the right spine for storage, counts, and
search, and the wrong front door. Second, half of what looks like
communication is actually verification: the verify block, the honesty laws, the
claims line on a card face all exist because the owner cannot blindly trust
what an agent says. So the design target is not messages moved per screen, it
is evidence per glance. A surface that makes an agent's claim cheap to check
removes a whole exchange; that is worth more than making the exchange pretty.

---

## 2. The strongest directions

Three directions, genuinely different in what they put first. They compose,
and §2.4 says how, but each is presented as if it won outright.

### 2.1 Direction A: the Queue is the front door

Thesis: the home surface is one cross-kind list of everything currently owed to
the owner, ordered by cost of delay, and every row is answerable in place. The
boards stay as depth surfaces, one hop down. The app opens on the queue the way
mail opens on the inbox, and an empty queue is a designed, pleasant state that
says so.

What a row is: an owed exchange. Pending decisions (page-level and on-card),
unsorted asks past a grace age, needs-you cards, unread agent notes on
owner-authored threads, an expiring context (a live session about to go cold),
and housekeeping (a stale mirror, a gone root) as the lowest band. Each row
carries the agent's drafted answer where one exists, and the primary verb is
agree.

```
┌ QUEUE · 9 wants you · 2 reach a live session ──────────────────────────────┐
│ ◙ decision  PR bot: what the testbed found          ● reaches a live agent │
│   automation · 7 items · pending 26h · drafted: ship as-is                 │
│   [agree with all 7]  [open]  [later ▾]                                    │
│ ◙ card #48  Ship the retry backoff?                 needs you · seen 3h    │
│   gcp · agent's pick: option b · 1 line to read                            │
│   ( a ) b · with the cap   ( c )        [answer b]  [open card]  [later ▾] │
│ ◙ ask      "warden review / artifact gating…"       unsorted 30h           │
│   no board yet · agent asks: which warden?          [reply]  [open]        │
│ ── housekeeping ──────────────────────────────────────────────────────────  │
│ ◙ board    apiservice root is gone · 7 cards are a last harvest            │
│   [unregister]  [re-point…]                                                │
└────────────────────────────────────────────────────────────────────────────┘
```

The keyboard is the point: j/k walks rows, enter opens, y agrees with the
draft, a number picks an option, l defers, and the row collapses into a one
line receipt as it is answered. The morning ritual becomes walk, agree, flip,
done, exactly the decision-page contract applied to the whole backlog.

Ordering is derived and must be explainable (law 1, honesty): the row says why
it is where it is ("reaches a live session", "pending 26h", "you deferred this
to today"). Live-session-reachable rows outrank older cold ones, because an
answer that arrives while the asking session is alive costs the agent nothing
and an answer after /clear costs a re-brief; see §4.2.

Optimizes: latency from question to answer, and the owner's cost per answer.
Gives up: the spatial project overview as the default view; risks becoming a
notification treadmill if the entry bar is low, so what counts as owed must be
strict (an unsorted ask enters the queue after a grace period, not instantly;
housekeeping never outranks a decision). Also demands the aggregation be built
on the kind registry's own adapters, or the queue and the tab counts will
disagree, which is C5's failure at the app level.

### 2.2 Direction B: the room and the strip

Thesis: the incumbent shape, designed instead of accreted. A board is the room
where deep work on one project happens; the navbar is the app's one constant
strip and carries exactly one cross-project fact: the needs-you number, next to
the live-agents pill. Everything else about "elsewhere" lives behind the crumb
and the palette. The hub remains an index, not a destination.

Under this direction the board page reorganizes into three honest layers:

```
┌ bar (global)   ⌂ All boards / .claude ▾ · find · needs-you 9 · ●2 · send ▸ ┐
├ shelf (board)  view: aug24-ergonomics ✕ · tag P1 ✕ · +view | synced 4h ago ┤
├ table          [asks rail] [lanes……………………………………………] [drawer]              ┤
└ panel (left)   views · tags · plans · sessions · pins                      ┘
```

The bar holds verbs and identity (D1d: one bar, shed labels under pressure).
The shelf holds state you can remove: the active view and filters as
dismissible chips, sync freshness, the card count. It is not a second verb bar,
it is the filter row that already exists, given a job description: verbs up,
state down. The left panel is the board's control inventory. The drawer is
unchanged in role and gains the sessions tab (D-ch-3).

Optimizes: deep work in one project, continuity with every standing ruling,
minimum migration. Gives up: the morning question is answered by one pressable
number rather than a surface; cross-project triage stays a sequence of visits.

### 2.3 Direction C: the correspondence

Thesis: the durable record is the product. Everything either side says (a note,
an ask, an answer, a ruling, a nudge, an agent's claim, a classification
account) is an entry in one per-board ledger, typed, timestamped, linked to its
artifact, and readable as a single strand. The board and its cards remain the
materialized current state; the ledger is the memory. A drawer tab per board
("what we said"), and a global view filtered to "what I said, everywhere, this
week".

```
┌ .claude · the record ──────────────────────────────────────────────┐
│ 25 aug 14:02  you → agent   note on #48: "no, cap it at 3"         │
│ 25 aug 13:40  agent → you   decision kanban-six-calls answered ▸   │
│ 25 aug 09:12  agent         classified your ask → card #81, task   │
│ 24 aug 22:30  you → agent   ruled plan CHAT-HISTORY: D-ch-1..3     │
└────────────────────────────────────────────────────────────────────┘
```

This is the surface that answers "what did I tell agents this week" and "did I
already rule on this", which today requires remembering which of five kinds the
utterance landed in. It is strictly derived: no compose box lives on it, every
entry is written by the surfaces that already exist, so it cannot drift into
being a chat product. That is the scope fence made structural: the moment the
ledger accepts input it is Slack, so it never does.

Optimizes: continuity, auditability, the owner's trust in their own past word.
Gives up: it moves nothing by itself; it is a read surface. Cost: an event
spine (append-only entries emitted by the existing write paths), which is real
plumbing, though the delta-chips and ack machinery already capture half of it.

### 2.4 How they compose

They stack: B is the body, A is the front door, C is the memory. The queue is
what the hub's default view becomes; the room-and-strip is what the board page
becomes; the ledger is a drawer tab and one hub filter. If forced to choose
one, choose A: it is the only one aimed squarely at the number the brief
names.

---

## 3. Surface by surface

Point of view on the six examples SYSTEM.md §5 names.

### 3.1 The rich-row family

The variance is right (§5.1's NORM), the grammar is missing. One row anatomy
across every kind:

```
[ identity ]  [ statement ………………………………………… ]  [ state        ] [ verbs ]
  glyph+name    the one free-width zone          pills, fixed     hover,
  hue dot       (title, body, claim)             order, right     fixed slot
```

Rules that make the variance feel designed:

- Identity is always leftmost: kind glyph (hue per the §4 amendment where kinds
  mix), then the name. Never centred (charter §3).
- The statement zone is the only one that flexes. It holds whatever answers
  "what would I want to know before acting here": card title plus claim line,
  ask body, decision title plus drafted answer.
- State pills sit right, in one fixed order everywhere: wants-you first, then
  blocked, then freshness/age. An owner who learns the order once reads every
  list. Today the hub row, the ask row, and the card face each order these
  differently.
- Verbs materialize in a fixed slot on hover and never reflow the row (C3's
  lesson: pointing at a row must not cost it its name).

Two specific critiques from the live board. First, the card face spends a full
line on the source path (`…s/kanban/_20260823-gcc-kanban.claude.md:208`) on
every harvested card; the path is the drawer's business, the face needs at most
a small "from a doc" glyph. That line is the scarcest space on the board and it
is spent on provenance the owner acts on approximately never. Second, 140
cards in the Active lane of `-claude-244ec6` render as 140 visually equal
rectangles, most of them harvested from other projects' checkpoints
(REMAINING-WORK.md names 156 such cards). Equal weight for unequal provenance
is a small dishonesty; see §4.5.

### 3.2 Toolbars

The grammar (group by gap, one primary verb per bar, inert verbs vanish) is
sound and mostly held. The missing rule is altitude: a bar states what scope it
governs by position, global at top, surface-scoped below, object-scoped in the
object (the drawer's head). The decision page's subbar proves the pattern; the
board's filter row should be understood the same way (a shelf of removable
state, not a second verb bar), which keeps D1d intact: verbs live up top and
shed labels, state lives on the shelf and is dismissible.

One addition: every bar's primary verb should be the same verb across siblings
at the same altitude. On the board it is Send to agent; on the decision page it
is Submit to Claude; on drafts it is Offer to a session. Those are one verb
(hand this to an agent) wearing three names. One name, one glyph, one accent,
everywhere (charter §5's one-glyph-per-meaning, applied to the verb the whole
app exists for).

### 3.3 Search

The three searches are one control with three moods, and the moods should be
result verbs, not separate widgets: a result already here scrolls, one
elsewhere navigates, a question shows its set. Keep the palette shell as the
single body. What a genuinely powerful bar adds, in order of value:

1. Answers, not just results. Typing `blocked` returns the count and the set
   inline, because five of the seven real intents are states, not text
   (SEARCH-DESIGN §1, still the best paragraph in the shelf).
2. Verbs in results. `nudge`, `sync`, `theme`, `open settings for <lane>` as
   rows, so the palette is also the command line. The CLI already names the
   verbs; the palette should speak the same list (one vocabulary, C1).
3. Result set to working set in one action (SEARCH-DESIGN capability 7/8).
   This is what makes search a tool instead of a lookup: find, select all,
   send.
4. A remembered question is a view; starred views sit in the first section.
   Already ruled (#39), just wants the palette to treat views as first-class
   rows.

The corpus-honesty sentence ("searched X, Y, Z") stays; it is the law-1
signature of the whole app and search is where it earns its keep.

### 3.4 The combined board toolbar

Designed from scratch, it is the bar-and-shelf from §2.2. Where each thing
lives, and why:

- Find: the bar's centre zone, one box, filters-here mood by default on a
  board. Its chips ARE the filter UI; a filter applied from anywhere (a count,
  a tag, a view) renders as a chip in or under the box, dismissible one by one.
  One place to see "why am I not seeing everything", which today is split
  between the filter row, the sidebar's active view, and memory.
- Views: rows in the left panel (they are a library), the ACTIVE view as a
  chip on the shelf (it is state). The distinction resolves the current
  double-render.
- Selection and send: bar, right, the one accented verb. Selection count is
  the verb's badge, pressable to review the set (law 3).
- Sync state: shelf, right edge, quiet; loud only when stale or gone (law 1).
- Board settings, soft limits, lane prefs: behind the lane heads and the
  board's own settings popover, as today. They are not toolbar material.

### 3.5 The navbar and its views

The bar as the app's one constant earns: identity/crumb, find, the needs-you
number, the live-agents pill, the page's verbs, help. The needs-you number is
the app's single most valuable pixel and today it does not exist as one number
anywhere; the tabs each count their own kind and the owner sums five badges by
eye. One number, pressable, opening the queue (or in direction B, a dropdown
of the owed items). The kind tabs then stop being five separate counters and
go back to being an indicator of where you are.

What should leave the bar: the theme toggle (into help, it is a
once-a-quarter control), and the Previews tab the moment it has been empty for
a month (a kind earns a tab by traffic; the registry can carry a kind without
the bar wearing it). What arrives with sessions (a sixth kind): nothing, if
the tab strip converts to the crumb's kind dropdown at the width where labels
would shed anyway. `All boards ▾ / .claude` already contains the full kind
list in its grammar; the tabs' counts move to the needs-you cluster. That is a
deliberate evolution of SYSTEM §5.5's tabs-as-indicator, argued not assumed:
five kinds fit a strip, the taxonomy's own §Kind promises more, and a strip
that grows one tab per kind is the C7 failure rebuilt slowly.

### 3.6 The transcript and ask hub

The hub as the morning surface is the queue (§2.1). Below the queue, the delta
band the board already knows how to compute, spoken as a sentence: "since last
night: 12 cards done across 4 boards, 2 decisions answered, 1 board went
stale", each fragment a control filtering to its set (law 3). Then the kind
indexes, boards first.

The gone-root boards currently squat in the WANTS YOU tier with three identical
red paragraphs (live hub, today, apiservice, datapipe, kanban-fixture). The
diagnosis is right and the placement is wrong: a dead fixture wants one action
once, not daily prominence above real work. Housekeeping is a queue band below
everything owed, and it collapses to one row per action ("3 boards point at
gone directories · [review]").

Transcripts: the drawer-tab ruling (D-ch-3) is right, and the one capability
that justifies the whole move is board links inside turns (CHAT-HISTORY §2.
The rest of the viewer is a port). The ledger (§2.3), if built, is the
transcript's cheap sibling: most mornings the owner needs "what was said to
me and by me", not the full turn record.

---

## 4. What nobody asked about

The section the owner asked for. Each item says what it is, what it costs, and
names the new entity when there is one.

### 4.1 The owed exchange, as a first-class derived thing

The hub's WANTS YOU tier, the tabs' five badges, the session-start line, and
the nudge machinery are four partial renderings of one thing the taxonomy
cannot say: "this item awaits the owner's word, since T, blocking X". Naming
it (an owed item, derived at read time, never stored, exactly like session
lists) gives the queue its row, the navbar its one number, the nudge its
content, and the CLI a symmetric read (`kanban.sh owed`, what the owner owes
agents; `kanban.sh owing`, the reverse). Cost: one aggregator over the kind
registry's own adapters, plus an ordering model that must stay explainable.
The registry makes this nearly free, which is the registry's whole argument.

### 4.2 Answer-while-hot

An answer's value decays with the asking session's context. Answering a live
session costs the agent nothing; answering after /clear costs a re-brief; the
taxonomy has liveness (livePeers) and pendingness (decisions, asks) but not
their join. Propose: every owed row derives a reachability, "reaches a live
session now" / "waits for the next session", and the queue sorts hot above
old-and-cold. The honest version admits heartbeat weakness (the charter
records a 21-hour-dead session reading live) and says "seen alive 4m ago"
rather than asserting live. Cost: a join with the ipc heartbeat at read time;
no new storage. This is the single cheapest change that moves the brief's
number, because it converts the same owner minutes into answers that land
where context still exists.

### 4.3 Delivery receipts on answers

Notes have ack (the agent's read receipt). Answers do not. A decision answered
20 minutes ago (the live page today) shows the owner's side only; whether any
agent has read the answer, and whether the originating session even still
exists, is unrecorded. States an answer should carry: answered, then read by
an agent (which agent, when), then acted with a reference. The first is
mechanical (the CLI's next read of the answer records it, the ack pattern
verbatim). The last is agent-reported and therefore a claim, rendered as one
(law 1: "the agent says it shipped this in e291941", never a bare check).
An answer no agent has read after a day belongs back in the queue, which is
the mirror of the unread-note nudge and closes the only leg of the exchange
loop that is currently dark. Cost: one field family on answers, one CLI
touch, one queue rule.

### 4.4 Defer with a horizon

"Later" exists (deferredAt, #defer) and means "not now" forever. A deferral
that names its horizon ("later ▾ → tonight / tomorrow / after M2 ships")
leaves the queue and re-enters it at the horizon, visibly ("you deferred this
to today"). Unseen versus deferred stays distinguishable (§12); this adds
when-deferred-until. Cost: one optional field, one queue rule, one dropdown.
Without it the queue will silt up with permanently-deferred rows and die the
inbox death.

### 4.5 Provenance weight on cards

A harvested card, a manual card, and a card the owner has touched (noted,
tagged, answered) are three different claims on attention wearing one face.
The data already knows (`via`, source, notes). Render harvested-and-untouched
at reduced weight (smaller face, no claim line, cluster-foldable), and
owner-touched cards at full weight with the unread/needs-you pills leading.
The 140-card Active lane becomes legible without a single deletion, and the
board stops implying the owner is 140 items behind when they are actually
nine. Cost: none in data, one density rule in design. This respects the
tombstone/override laws: nothing is hidden, weight is not existence.

### 4.6 Lane aggregation at scale

Per-lane density and fold exist; what is missing is a grouped mode at the
threshold where a list stops being readable (about 15). A lane past its soft
limit offers "group by: milestone / source doc / age band", rendering cluster
heads with counts-as-controls instead of N equal cards. The soft-limit amber
(a signal, never a block) becomes the doorway to the fix rather than a mute
warning. Cost: a per-lane view pref plus one renderer; the peek column
already proves the one-tag-one-column version of this.

### 4.7 The day model, and the app's absence from it

The app is pull-only. Agents work around the clock; the owner visits. Three
moments the design should own explicitly:

- Morning: the queue (§2.1). Built for emptying.
- During deep work: the app must NOT want attention. One number changes on
  the menu bar (the claude-instances widget already lives there; it renders
  the needs-you count and nothing else) and everything batches. The only
  interrupt that punches through is an agent-raised flag on a live-blocking
  item, the owner-facing mirror of the ask's `triggered`. That flag should be
  rare, costly for agents to raise (recorded, reviewed), and instantly
  legible.
- Evening: the delta digest, one sentence with pressable fragments (§3.6),
  which doubles as the "did anything happen while I was heads-down" answer.

Cost: the beacon is one integer served to the widget that already exists;
the interrupt flag is one field plus discipline; the digest derives from the
delta machinery already built. Naming the day model matters more than any of
the three pieces: it gives every future "should this notify" question a rule.

### 4.8 One Decision primitive, two scales

The ask-on-a-card (#48) and the decision page are the same thing at N=1 and
N=many: options in the agent's words, a recommended pick, seen/deferred/
answered, a null-pick with text as a real answer. ANSWER-PATH.md §out-of-scope
already says the field shape can be shared. Unify them: a Decision is one
entity; a card-bound decision with one item renders in the drawer, a
many-item one renders as a page, the queue lists both identically, and one
state machine serves both. Cost: real. Two answer stores merge (plan.json
answers and .answer.json), the byte-compatible answer-string contract must
survive verbatim, and the CLI grows one verb family where it has two. Worth
it now, while both implementations are weeks old; in six months this is a
migration nobody schedules, and the queue (§4.1) otherwise carries two
renderers and two state machines forever.

### 4.9 What happened to my ruling

Rulings are write-only today. The plan flips to ruled, the answer banner shows
what was said, and then nothing ever reports back. A closure line on each
answered decision ("acted: 3 of 6 · 2 pending · 1 the agent pushed back on",
each fragment pressable) turns the rulings ledger from a record of what the
owner said into a record of what it caused. Rendered as claims (§4.3), never
as verified fact. Cost: rides entirely on §4.3's acted-with-reference; this
is its rollup.

### 4.10 The load meter

The brief says the communication load grows faster than attention. Nothing
measures either. One quiet line on the hub foot: exchanges this week, median
hours a decision waited, asks that never got sorted. Pressable (law 3), one
line only (the charter's not-number-heavy instinct is right), but present,
because "did the redesign move the number" is otherwise unanswerable, and an
app whose whole thesis is a number should be able to say it.

### 4.11 Capture from anywhere

The composer lives on two pages; the owner's thoughts arrive in terminals,
in other apps, mid-commute. The ask is deliberately the cheapest write in the
system ("type anything, it gets sorted") and it still costs a page visit.
A global capture (hotkey summoning the composer, or `kanban.sh ask` for the
human too) is mostly out-of-app code and is named here as a gap, not designed:
the cheapest capture wins, and right now a text file beats the app, which
means thoughts leak out of the system the app exists to be.

---

## 5. Where I disagree

Most rulings should stand and do. Three disagreements argued, one record
inconsistency flagged, one watch item.

### 5.1 Law 11: "a control that cannot act is hidden, not greyed"

Disagree in part. Hiding is right when a control is contextually irrelevant
(no selection, so no Send). It is wrong when a control is temporarily
unavailable, because spatial memory is how a daily user operates: the help
control that was "absent, not disabled" on hub and drafts for a stretch
(UNIFIED-SURFACES, the #68 notes) read as a bug to anyone who had learned `?`
on the board, and a bar whose controls appear and vanish teaches the owner
the bar cannot be trusted. Split the law: irrelevant is hidden; unavailable
is visible, quiet, and its tooltip says why and when it returns. The tooltip
requirement keeps the honesty (nothing greyed without an explanation), which
I take to be what the original ruling was actually protecting.

### 5.2 The Inbox lane

Openly a NORMATIVE challenge, so said with its cost. On the live board an
empty Inbox column sits directly beside the asks rail, and both mean "arrived,
not yet sorted". Two landing zones for the same state, side by side, is the
§13 anti-pattern (two ways to fire one action) in noun form. Either the inbox
is where a classified ask lands as a card, in which case name it that
("Landed") and make the rail's landing animation point into it, or the rail
absorbs it and boards start at Backlog. Cost: a lane-vocabulary change touches
sync, the CLI, and every per-lane pref, so this is not cheap; but the empty
prime-width column on every board is paying rent daily, and the taxonomy
should not carry two words for one state indefinitely.

### 5.3 Kind tabs as the bar's permanent tenants

SYSTEM §5.5 fixes tabs-as-indicator with counts as the pattern. With sessions
ruled in as a kind and the taxonomy explicitly promising more ("a new noun
becomes a kind, never a special case"), the strip grows a tab per noun
forever, which collides with the owner's own one-bar-kept-clear ruling (D1d)
at a knowable width. The registry is the fix, not the victim: kinds whose
count is zero-or-quiet fold into the crumb's `All <kind> ▾` dropdown, the
needs-you cluster carries the one number that matters (§3.5), and the strip
shows at most the current kind plus the loud ones. The tab strip as built is
right for five kinds; the pattern should not be carried as law into eight.

### 5.4 A record inconsistency, not a disagreement

CHAT-HISTORY.md:69 rules a hub Sessions tab out ("sessions are per board, the
wrong altitude"); the 2026-08-25 D1b ruling brings a hub sessions surface in.
REMAINING-WORK.md notes the delta but the plan doc still carries the old
sentence unamended. Whoever builds #14 will read one of the two first.
Reconcile the doc before the build, per the charter's own habit of retiring
a gate's note the day it clears.

### 5.5 Watch item: D1d, one bar for the board

The ruling stands (it is 20 minutes old and it is the owner's). But it was
made against today's verb count, and the board is already in tight mode at
1400px with labels shed (REMAINING-WORK, the filed second-bar item). When
sessions land in the drawer and the queue number joins the bar, re-measure
rather than re-shed: the ruling's own text ("keep shedding labels under
pressure instead") has a floor, and glyph-only bars are only survivable
because the tooltips were there from the start (§18c). Not a disagreement, a
date to re-ask.

---

## 6. If you only did three things

1. Build the queue with inline answers (§2.1, §4.1), as the hub's default
   view. It is the only surface aimed at the number the brief names, every
   piece of data it needs already exists, and the decision-page contract has
   already proven the interaction model it generalizes.

2. Unify the two decision implementations into one primitive (§4.8), now,
   while both are young. Every later surface (the queue, the ledger, the
   sessions view, the nudge) otherwise pays a two-renderer, two-state-machine
   tax forever, and the merge cost only grows.

3. Make liveness and delivery honest (§4.2, §4.3): answer-while-hot ordering,
   read receipts on answers, and the undelivered-answer re-queue. It is the
   cheapest set of changes that converts the owner's existing minutes into
   answers that land where context still exists, which is the closest thing
   this app has to compound interest.

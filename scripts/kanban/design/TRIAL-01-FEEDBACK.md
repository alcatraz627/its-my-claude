# Trial 01 feedback: using kanban.sh to track Chime

I planned a personal alarms/reminders/scheduling app (docs at
`/Users/alcatraz627/Code/Claude/kanban-showcase/docs/`) and put the full plan,
including a simulated two-weeks-later set of plan changes, onto the board at
`kanban-showcase-945e63` using only `kanban.sh` and the browser. This is the
honest record of where the tool helped and where it fought me.

## What I could not express

- **A milestone as a first-class grouping, not just a tag.** Milestones
  (M1, M1.5, M2, M3, M4) are the actual backbone of a sprint plan: they have
  an order, a goal sentence, and a "this milestone is done" state. The board
  only gave me `tag milestone:m2`, a plain string with no ordering, no goal
  of its own, and no way to say "M1 is closed, M2 is open." I ended up
  representing "M1 shipped" implicitly, by moving all seven M1 cards to
  `done` one at a time, rather than by closing a milestone once. There is no
  card for the milestone itself, only for its tasks, so a viewer can't click
  "M2" and get the one-line goal I wrote for it in `sprint-plan.md`; that
  sentence only exists in the doc, disconnected from the board.
- **A changelog as a first-class thing.** `plan-changes.md` records four
  distinct kinds of change (cut, reprioritized, split, new milestone
  inserted) with the reasoning behind each. The board has nothing shaped
  like "this is a change to the plan, here's what it affected." I
  approximated it by tagging the affected cards and `link`-ing
  `plan-changes.md` onto them, so a viewer who opens the right cards can
  find the reasoning, but there's no board-native "here's what changed
  recently and why" view. I built a custom `view` for "P0 open" and "needs a
  decision", but I could not build one for "what changed since last week",
  because nothing on a card records "this card was affected by a plan
  change on this date" as structured data, only as a tag I invented
  (`priority:P0` moved, but the move itself isn't dated or annotated as a
  *change* distinct from an initial assignment).
- **A split task's relationship to its origin.** When "Snooze engine" split
  into "detached-instance data model" and "cross-device sync semantics", I
  wanted the board to say these two used to be one thing. There's no such
  relationship. I used `after` (data-model before sync-semantics) which is
  the right dependency, but dependency and "split from" are different
  claims, and the tool only has the first. I made up the difference with a
  shared `area:snooze` tag and a linked doc, which recovers *some* of the
  context but nothing that says "these two are siblings from one cut."
- **The PRD's open questions as board objects.** `prd.md` has four explicit
  open questions the plan cannot proceed past without an owner decision.
  Two of them map cleanly onto `verify --needs-human` on the cards they
  block (I did this, and it produced a genuinely good result, see "what
  worked well" below). The other two (the midnight-boundary question, the
  deferred-condition UX question) don't block any *one* card, they're
  cross-cutting design questions that touch several cards a little each.
  There's nowhere to put a decision that isn't owned by exactly one card;
  I ended up not representing those two at all rather than force-fitting
  them onto an arbitrary card.

## Where I had to guess

- **`plan` is a real, undocumented verb.** The board's own sidebar says
  "Plans / No plans registered. `kanban.sh plan add <path> puts one here.`"
  but `kanban.sh` with no arguments (the tool's own help) never mentions
  `plan` at all, and neither does `kanban.sh -h`. I only found it by typing
  the sidebar's own suggested command. Worse: running bare `kanban.sh plan`
  or `kanban.sh plan list` doesn't show plans (there are none registered);
  it silently prints what looks like a **global, cross-board list of
  ruled/draft decision documents**, including one from a completely
  different project (`claude-instances-c87d13`). I could not tell, without
  reading source I was told not to read, whether that's the actual "plan"
  feature working as designed (plans and decisions share a code path?) or
  a bug where an unrecognized sub-verb falls through to an unrelated
  listing. I did not use `plan add` on my own docs because I could not
  tell what it would actually do to a doc that already renders on the
  board (would it duplicate `sprint-plan.md`'s content as cards? Register
  it as a read-only reference? I had no way to find out except by trying it
  and inspecting the result by hand, which felt like exactly the kind of
  "guess and see" the tool should not require for a documented-sounding
  feature). I left it alone.
- **Doc-harvest vs. manual `add`.** Cards can arrive two ways: auto-harvested
  from a doc's checkbox lists under lane-named headings (`## Backlog`,
  `## Active`, etc., exactly like the pre-existing `docs/features.md`), or
  added one at a time via `kanban.sh add`. Nothing told me which one a real
  sprint plan should use. I tried the natural thing first: I assumed
  `sprint-plan.md`'s own structure (headed by milestone, not by lane) would
  harvest, since it has the same `- [ ]` checkbox shape as `features.md`.
  `kanban.sh sync` ran clean, scanned all five of my new docs, and created
  zero cards, silently, with no message explaining *why* nothing matched.
  I had to diff my file's headings against `features.md`'s (`## Backlog` /
  `## Active` / `## Blocked` / `## Done`, matching lane names exactly) to
  work out that harvesting keys on lane-named headings, not on the presence
  of checkboxes. A sprint plan organized by milestone (the natural way a
  human writes one) structurally cannot be harvested, because "milestone"
  and "lane" are different axes and the tool only harvests along one of
  them. Once I understood that, I switched to `add` entirely and never
  looked back, but the switch cost real time and there was no error, warning,
  or hint pointing at the reason.
- **Whether `verify --needs-human` was the right tool for "blocked on an
  owner decision" versus just moving the card to the `blocked` lane.** I
  ended up using both, for different reasons (lane = "this can't proceed
  right now"; verify grade = "the reason it can't proceed is a decision only
  the owner can make"), and I'm fairly confident that's the intended split,
  but nothing told me that directly; I inferred it from the showcase card
  named "Needs human: a card the agent cannot close by itself" and the
  `Needs a human` view's clause (`is:open tag:area:needs-human`), which
  actually uses a **tag**, not the verify grade, to build that view. So the
  showcase's own "needs a human" demonstration and my own `verify
  --needs-human` usage are two different mechanisms that look like they
  should be the same feature and aren't unified by any view I could find.
  I had to build my own `Chime: needs a decision` view using the
  `needs-you` clause (found only by triggering a grammar error on purpose,
  see below) to get an equivalent for my own cards.
- **How to discover the query grammar for `view add`.** The only place the
  full clause vocabulary (`is:open`, `is:blocked`, `is:settled`, `needs-you`,
  `review-me`, `since:new`, `since:moved`, `since:done`, `since:blocked`,
  `tag:<kind>:<name>`) is written down is the **error message** you get from
  typing an invalid clause. `kanban.sh view add --help` or similar doesn't
  exist; the bare `kanban.sh` help just says `view [list] ... add "<name>"
  <clause…>` with one example (`is:open not tag:area:docs`). I had to
  deliberately type a clause I knew was wrong (`is:needs-human`) just to
  make the tool tell me the real grammar. That worked, but it means the
  discovery path for a real feature is "fail on purpose and read the
  rejection," which won't occur to most people.

## What was awkward but possible

- **The Backlog lane doesn't group or sort by anything I control.** With 24
  cards in Backlog (my 20-ish plus the showcase's 10), the column reads as
  a flat, recency-ordered list that jumps between milestones card to card:
  an M3 card, then an M1.5 card, then an M2 card, then an M4 card, in the
  order I happened to `add` them. There's no "group by tag" or "sort by
  milestone" on the lane itself; the only way to see milestone-ordered work
  is to build a `view` per milestone or click a milestone tag in the
  sidebar to get the cross-lane peek. For a plan with several milestones in
  flight, the primary column a cold viewer lands on is the least organized
  view of the data. I worked around this by leaning on custom views
  (`Chime: P0 open`, `Chime: needs a decision`) rather than the lane itself,
  which works, but means the lane view is basically not where I'd point
  someone first.
- **Bulk tagging has no batch form.** Tagging 25 cards with a milestone, a
  priority, and often an area tag each meant one `kanban.sh tag <id>
  <kind>:<name>` invocation per card per tag, about 65 individual shell
  calls by the time I was done (I wrote a small script to fire them in
  sequence rather than type each by hand, which is exactly the kind of
  thing a tool built for an agent should not require me to route around).
  There's no `tag <id1> <id2> <id3> <kind>:<name>` form the way `after`
  accepts multiple ids in one call.
- **Getting a card's id back from `add` requires parsing free-text stdout.**
  `kanban.sh add "<title>" --lane backlog` prints `added <id> to backlog on
  <slug>` as prose, not `--json`. To chain `add` into `tag`/`after`/`goal`
  calls (which is the entire point of adding 25 related cards), I had to
  `grep -oE 'added [a-f0-9]+' | awk '{print $2}'` against that sentence.
  `show` and `status` both support `--json`; `add` does not, which is the
  one command where a script most needs a stable machine-readable id back.
- **Dependencies are a count, not a link, everywhere I looked.** Once I set
  `kanban.sh after <child> <parent>`, both the card face and (as far as I
  found) the drawer only ever show `after 1` (or `after 2`), a bare count
  with an icon. Clicking that pill in the browser just opens the same
  card's own drawer again; it does not jump to, or even name, the card it
  depends on. To answer "what is card X actually blocked behind" I had to
  drop back to the CLI and run `kanban.sh after <id>` (which does print the
  real dependency, correctly) or `show --json` and read the raw ids. For a
  feature explicitly built to represent execution order, the one place
  that matters most (looking at a card and knowing what it's waiting on)
  is the one place that doesn't say.
- **The card drawer and the tag cross-lane "peek" panel can both be open at
  once, stacked**, and I could not find a single click that reliably closes
  just one of them; a stray click on a tag pill inside an already-open
  drawer opens a second panel on top rather than navigating within the
  first. Not a blocker, just a few extra clicks each time it happened.

## What worked well

- **`verify <id> <grade> --needs-human --note "..."` is genuinely the right
  shape for "this can't be marked done by an agent."** Grading a claim as
  `executed` / `cited` / `reasoned`, separately from whether it needs a
  human, matches exactly how I actually think about the M1 "done" cards
  (I marked all seven `executed` with a one-line note about the two-week
  TestFlight run, which is a real, checkable claim) versus the two PRD
  open-question cards (`reasoned --needs-human`, because the honest state
  is "there's an argument, not a decision"). The drawer renders this as
  plain English ("argued, not observed") rather than the raw grade word,
  which reads better than I expected.
- **`goal <id> "<why>"` earns its place.** A one-line reason a card exists,
  shown at the top of the drawer next to a small icon, is a low-cost way to
  carry the "why" that a title alone can't. I used it on every card and it
  is the single field I'd keep if I had to cut everything else down to one.
- **`link <id> <doc.md>` renders a live preview, not just a filename.** The
  drawer shows the first couple of lines of the actual linked file inline
  ("EVERY SOURCE AND LINKED DOC"), which meant a card pointing at
  `plan-changes.md` genuinely orients a reader without them leaving the
  board. That's the feature that best bridges "the docs are the real plan"
  and "the board is where people look."
- **The tag click-to-peek overlay, with the dashed line drawn from the
  overlay back to the card you clicked from, is a nice piece of orientation
  design** I didn't expect. It answers "where else does this tag show up"
  without losing your place.
- **`view add` with a free clause grammar (`tag:x and/or/not tag:y`,
  `is:open`, `needs-you`) is more expressive than a fixed filter dropdown
  would have been.** Once I knew the grammar (see "guessing," above), I
  built exactly the three cuts of the 39-card board I actually wanted
  (everything of mine, what's blocked on a decision, what's still critical
  and open) in three one-line commands.
- **`brief` doing exactly one job (a short face-name) while the full title
  stays as the drawer's description** is a small, correct decision. Several
  of my titles ran to 80+ characters because that's what an honest task
  description looks like ("Day view merging calendar events, deadlines,
  and time-of-day-bucketed reminders"); `brief` let the column stay scannable
  without lying about the task by truncating it.

## What I would change, ranked

1. **Give a milestone a real object**, not just a tag string: a name, a
   goal sentence, an order, and a closed/open state, so "M1 is done, M2 is
   next" is something the board itself asserts rather than something a
   viewer infers from seven cards all sitting in the `done` lane.
2. **Make dependency links navigable**, not just countable. At minimum,
   clicking `after 1` should show which card(s), the way clicking a tag
   shows which cards share it.
3. **`add` should support `--json`**, matching `show`/`status`, so scripting
   a batch of related cards doesn't mean regexing prose out of stdout.
4. **Explain a doc-harvest miss.** When `sync` scans a file and creates
   zero cards from it, say why (no lane-named headings found) rather than
   reporting it identically to "nothing changed since last sync." That one
   line would have saved me the diff-the-two-files exercise.
5. **Document `plan` in the bare help output**, and make `plan` / `plan
   list` fail loudly (or scope cleanly to this board) rather than
   returning what reads like an unrelated, cross-project decision listing
   when no plan is registered.
6. **A batch form for `tag`** (multiple ids, one call), the same courtesy
   `after` already extends.

## What I never used, and why

- **`items` / `item add` / `classify`** (the owner's unsorted "asks" queue)
  and **`drafts` / `pull` / `to`** (owner-authored documents addressed to an
  agent or board). I looked at both (there was pre-existing data on this
  board from other work), but nothing about my task involved the owner
  handing me an ask mid-stream to sort, so there was nothing genuine to
  classify. Not a gap I found, just a feature this trial didn't exercise.
- **`selected`** (what the owner has ticked in the UI right now). Same
  reason: nobody was driving the board interactively alongside me.
- **Sub-items (checklists inside a card).** The showcase board demonstrates
  this well ("Sub-items: a card with a checklist inside it," 1/3 done), and
  I considered it for the smaller P2 polish tasks (widget details,
  per-alarm overrides) rather than giving them their own cards. I didn't,
  because once a task has a dependency (`after`) and a milestone tag of its
  own, it earns full-card status in my head, and none of my P2 items were
  actually sub-parts of a bigger card, they were just lower-priority
  siblings. This is a "didn't need it" gap, not a "didn't find it" one.
- **`drop --force` / `--undo`.** I deliberately chose `stale` over dropping
  the cut "Focus mode integration" card, specifically so the historical
  record of a genuine cut survives (see `plan-changes.md`), rather than
  disappearing the way a manual `drop` does ("gone for good"). I never
  needed to actually remove a card outright.
- **`notes --ack`** and the note-tag vocabulary (`@me`, `!now`, `/skill`,
  `>lane`, `#defer`, `#review-me`) for owner-to-agent notes. There were no
  unread notes on this board when I started, and I wasn't simulating an
  owner leaving me instructions mid-task, so I read the mechanism (in the
  drawer's "New note" composer) but never had a real note to act on.

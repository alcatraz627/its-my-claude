# Remaining work

Everything still open on the kanban app. Rewritten 2026-08-24 after a skeptical
review found the first version was built from 5 of the 24 spec documents in this
directory and missed an entire build task.

**Sources, all of them this time:** the task store `session-f00a0017` (19 open of
75), the board backlog on `-claude-244ec6` (32 cards), the V3 feedback draft
`anr9ip7r`, the unpulled draft `ox00epxm`, the three session checkpoints, and
every `*.md` in this directory. `COMPLIANCE-LEDGER.md`, `SURFACE-CATALOG.md` and
`CAVEATS-LEDGER.md` were read but are **themselves stale** and are treated as
suspects, not authorities (see Everything else).

Branch `kanban/aug22-sweep`, 55 commits ahead of `main` and fast-forwarded
into it locally, awaiting the push gate.

The board's Active lane holds 156 more cards harvested from other projects'
checkpoints, because sync scans `_*.claude.md` under the repo root and
`~/.claude` is the repo root. Not this app's plan, excluded here.

---

## The kind spine

Owner, 2026-08-24: *"You do know we're gonna be adding session and maybe other
things in the future right? Don't be myopic."*

This reframes six separate items into one. `NAV-UNIFICATION.md` specifies a
"palette widened to three kinds". There are already four (boards, asks, drafts,
sessions) and the owner says more are coming. So nothing below hardcodes a kind
list. One registry declares each kind's name, glyph, hue, index route, search
adapter and card shape, and every consumer reads it:

| Consumer | Today | After |
|---|---|---|
| Nav palette (`#21`) | 3 kinds hardcoded | reads the registry |
| Crumb grammar (`#21`) | boards only | `All <kind> / <instance>` for any kind |
| Toolbar | navigator, 3 tabs | indicator, N tabs from the registry |
| Search (`#21`, `SEARCH-DESIGN.md`) | 5 sections, board-scoped | one adapter per kind |
| `/api/surfaces` (`#56`) | its own surface list | the same registry |
| Board switcher kinds (`#56`) | its own list | the same registry |
| Sessions (`#14`) | does not exist | a kind, not a special case |

**Build the registry first.** Every item tagged `[spine]` below depends on it,
and building any of them against a hardcoded triple is the myopia the owner
named. This is new work, not on any card, and it is the single highest-leverage
item in this document.

---

## Waiting on the owner (1)

| Item | Why it is his |
|---|---|
| **Approve the push** | `main` is fast-forwarded locally to 55 commits of kanban work. The push gate needs a per-push sentinel only the owner can create. Merge and push both authorised 2026-08-24; the gate is mechanical, not a second ask. |

**Closed 2026-08-24.** `pm2 startup`: done.
**Sessions hub scope: never a real gate.**
`CHAT-HISTORY.md` is a complete 146-line plan (four surfaces, five shippable
phases each with its own check, what retires from claude-instances) and its
three rulings were answered on 2026-08-24. This document invented an open
question the plan already answers, and said so to an owner who had been told
the planning was finished. It was.

The one genuine divergence, and it is small: `CHAT-HISTORY.md:69` decides a
hub-level **Sessions tab is not added**, because "sessions are per board, the
wrong altitude for the hub". The owner's later `/new-item` note asks for "a
sessions hub, inspired by claude-instances... but can also exist
independently". D-ch-3 ruled on the per-board surface (a drawer tab, not a full
page), which is a different question from whether the hub gets one. That delta
is the only thing unsettled, and it is a paragraph, not a plan.

**Resolved 2026-08-24, was gated:** the asks-versus-items naming
(`NAV-UNIFICATION.md:153`, open since 2026-08-22 and blocking `#21`). Owner:
*"items.json, make it accessible properly via the CLI... Project durable, agent
modifiable and readable, and shows properly on the UI."* So the machine
vocabulary is `items` (data file, CLI verb, API route) and the human label in
the UI stays "Your asks". `#21` is unblocked on both its gates now.

---

## To build (27)

### The spine, first

1. **Kind registry** `[spine]` **Done 2026-08-24, and this row was stale.** It
   is `kinds.js`: one declaration per kind carrying name, `indexLabel`, glyph,
   hue, route, key, search adapter and rank. Items 2 to 5 below are all done
   and every one of them cites `KINDS` as the mechanism, so the thing this row
   called NEW and gating had already shipped and done its gating. Five kinds
   registered (boards, asks, drafts, decisions, previews); adding sessions is
   one entry there and nothing elsewhere, which is the whole point.

### `#21` nav unification, absent from the previous plan entirely

`COMPLIANCE-LEDGER.md:56` records it PARTIAL, "Per-kind index pages NOT done".
`NAV-UNIFICATION.md:109-142` names four slices, in this order:

2. **Reach an instance of any kind** `[spine]`. **Mostly already built**, which
   this plan did not know: the palette had asks and draft sections and a
   `gotoKind` handler before today. Done 2026-08-24: its sections derive from
   `KINDS` through one adapter per kind rather than a copy-pasted block each,
   and the per-kind hue rides the registry. Verified by naming a draft, which
   is the cell `NAV-UNIFICATION.md:40-48` drew as empty.
   **Crumb done 2026-08-24**: `crumbFor()` in `shared.js`, built from the
   registry, on all three pages. The hub is an index so it shows the left half
   alone and follows the kind when you switch in place; drafts names the open
   draft. The registry gained `indexLabel` because the tab wants the owner's
   word ("Your asks") and the crumb wants a plural that reads after "All"
   ("All asks"). **Item 2 is complete.** (`COMPLIANCE-LEDGER.md:56` calls this "per-kind index pages NOT
   done", which reads as if the indexes are missing; they are not, and that
   ledger row is one of the stale ones.)
3. **Palette widened to N kinds** `[spine]`. **Done 2026-08-24** as part of
   item 2: sections walk `KINDS` through one adapter per kind, each carries its
   glyph with the hue tint on top per the 2026-08-22 ruling, and Boards keeps
   its recent/starred/all sub-structure. Verified: four sections, three hues,
   and typing a draft's name finds it.
4. **Toolbar demoted from navigator to indicator** `[spine]`. **Done
   2026-08-24.** It was a navigator with nothing to state: `.views .vn:empty`
   hides a blank pill, only the hub ever wrote a count, and it wrote one, for
   boards, by reaching into the navbar's DOM. Each kind now counts itself from
   `kinds.js` (`api` + `countOf`) and `shared.js:kindCounts()` asks once per
   page, so all three pages read 9 / 2 / 3 and a fourth kind arrives already
   counted. A kind that cannot be reached answers `null`, never `0` (§12), and
   the counts are re-asked when the tab comes back into view. The palette is
   the picker, and its keyboard now agrees with its mouse: Enter on a draft row
   went to `/b/undefined` because every row was sent to `gotoBoard`.
5. **Search across all kinds** `[spine]`, plus the missing **Boards section**.
   **Done 2026-08-24.** The palette and the search each loaded their own answer
   to "what is there, of each kind", so a kind wired into one was missing from
   the other; both now read `shared.js:kindIndex()`, which is also what the tab
   counts. Search gained a section per kind, ranked by `searchRank` in the
   registry rather than by nav order, because from inside a board "which board"
   is the least local question (`SEARCH-DESIGN.md` §4). Sections now run
   Questions, Cards, Your notes, Tags, Your asks, Drafts, Boards, and the "what
   was searched" sentence is built from that list rather than written out, so a
   new kind is named in it without anyone remembering to. Acceptance 5 passes:
   typing a project name offers the board and Enter navigates. A result that is
   already on this page stays here, so an ask on the rail scrolls rather than
   leaving the board (§1); one that is elsewhere navigates to its own address.

### The owner's direct ask

6. **`items` as a first-class CLI entity** **Done 2026-08-24**: `cli.ts:582`
   carries `item add|edit|rm`, POSTing so `items.json` keeps one writer.
   Originally filed as: Today `cli.ts` can read
   (`items`) and record a disposition (`classify`) and nothing else;
   `saveItems` is called only from `server.ts:701,710,729`, so **only the UI can
   write an ask**. Owner: durable per project, agent modifiable and readable,
   and shows properly on the UI. Needs create, edit, delete, star and scope
   verbs, `--json` on the read, and the UI re-rendering from the same store.

### `#39` was declared complete against a spec it does not implement

The 08-23 checkpoint's own entry: "filter views per `FILTER-VIEWS.md`: shared,
owner notes, AND/OR/NOT, session-start line and `/kanban` skill updated."

7. **OR and NOT grammar** **Done 2026-08-24**: `matchQuery` exists
   (`match.js:100`) with `parseQuery`/`matchParsed`, to the ruled precedence.
   The claim that it did not exist is what this plan said before `#39` finished.
8. **Owner notes on a view** **Done 2026-08-25.** The claim that `lib.ts` had
   no `note` field was stale: the field, the server's add and note ops, and
   the CLI's `--note` flag and under-row print were already in. What was
   actually missing was the board UI, and it is in now: the save-as-view
   popover carries an optional "For the agent" field, the sidebar row's
   tooltip shows `for: <note>`, and a pencil on the row edits or clears it
   (empty clears, the ask grammar). Verified live: save with note, tooltip,
   pencil pre-fill, edit, delete.
9. **The `/kanban` skill is stale against its own CLI** **Done 2026-08-24**,
   and guarded: `test-charter.sh` asserts "every cli.ts verb appears in the
   /kanban skill" and passes. The peer complaint gcp-c2398e8b is answered.

### `#69` remaining scope, named in the spec and carded nowhere

10. **Help modal Taxonomy and Charter tabs for hub and drafts** **Done
    2026-08-24.** The `.cdoc` and `.term` rules moved to `shared.css`, and both
    tabs are now specs any page drops into its modal (`shared.js:charterTab`,
    `termsTab`). Charter renders `UI-CHARTER.md` rather than restating it, so
    all three pages show the same rulings from the one file. Taxonomy was the
    half with no content: the hub has seven terms and drafts six, each written
    against what those pages actually render, with a Do and a Not. They carry
    no vignettes yet and so lay out in one column rather than framing an empty
    box; the board keeps its illustrated version. `esc` moved to `shared.js`
    for the same reason the CSS did.
11. **Help hosts on the decision-page and transcript surfaces**, same source.
    **Half unblocked 2026-08-25**: the owner ruled decision pages fold INTO
    kanban (DECISION-PAGES-ADOPTION.md), so the adopted /dp/ pages are
    same-origin and the shared help modal is one mount away. The transcript
    half still waits on #14/#20. Original blocker note kept below for the
    record. **Was: blocked, and the two halves are blocked differently.** The transcript
    surface does not exist: `rg transcript *.html *.ts` finds nothing, and
    `CHAT-HISTORY.md:71` records that the hub deliberately has no Sessions tab
    yet, so `#14` has to land first. Decision pages are a separate subsystem
    (`~/.claude/scripts/decision-page/`, its own `template.html` and static
    `server.py` on :5197), and that template is deliberately self-contained
    with one inline `<style>` and no external asset. Hosting the modal there
    means one of two things and it is the owner's call: point those pages at
    `http://localhost:5106/shared.{js,css}`, which makes a decision page depend
    on the kanban server being up to look right, or inline a copy into every
    generated page, which is the duplication the shared file exists to end.

### Unified surfaces

12. **Phase 1: the hub's two tabs** (`#56`, P1) `[spine]` **Done 2026-08-25.**
    Decisions and Previews joined kinds.js as kinds, which is the reshape item
    1 asked for: tabs on all three pages, counts (Decisions counts pending),
    palette and switcher sections, and the find box all derive from the one
    registry. The hub renders both views, pending first with origin and age;
    rows link to :5197 where the pages already live. Verified live.
13. **Phase 2: the charter as a decision page** (`#57`) **Done 2026-08-25,
    by absorption rather than restyling**: the owner ruled decision pages
    fold into kanban, so instead of template.html adopting shared.css across
    servers, kanban serves the registry itself at /dp/<slug>/ with ONE
    charter-styled dynamic template, a byte-compatible submit endpoint, and
    the answer contract ported verbatim (byte-equality verified on clean and
    flipped states). Full examination, defect catalog and transition plan:
    DECISION-PAGES-ADOPTION.md. The :5197 server runs beside it until the
    owner retires it.
14. **Phase 3: plans as a kind** (`#58`) `[spine]` **Done 2026-08-25** (built
    before 13, which is owner-gated; the spec says each phase ships alone).
    `KROOT/plans.jsonl`, CLI `plan add/rule/supersede/rm/list` (documented in
    the /kanban skill, charter-gated), plans in `/api/surfaces` and per board
    in the board payload, a Plans group in the hub's Decisions view (draft
    first, amber), and a PLANS sidebar section on the board whose rows open
    the doc viewer. The five plan docs of this app are registered (4 ruled, 1
    draft); a probe plan's rule-flip was verified at the API. Deliberately
    NOT built: decision-page auto-rule on submit (cross-system, rides the
    owner-gated 13) and plan tagging (ambiguous in the spec).
15. **Phase 4: decisions without a card** (`#59`, P1). **Seen-versus-unseen
    done 2026-08-25.** The gate turned out to have dissolved on its own: it
    waited on the :5197 pages reporting "the owner opened me" across origins,
    and :5197 is dark while kanban serves every page itself same-origin, so
    the cross-system integration is a route on this server. The page pings
    `POST /api/dp-seen/<slug>` on load; `.seen.json` is written once and a
    re-read will not restart the clock, because the first open is the fact.
    `/api/surfaces` carries `seen`, the hub gives an unopened pending page an
    amber fill and a dot, and charter §12 records the mechanism under the rule
    it had been stating without implementing. Verified with three seeded
    pending pages: opening one flipped it to seen while it stayed pending, the
    other two did not move, a re-post left `seen_at` unchanged, and an unknown
    slug and a traversal attempt both 404.
    **Still open from D9a**, and larger than this half was: a Decisions view
    ON the board listing every decision card-bound or not, `kanban.sh decide
    add` for agent-recorded decisions, owner comments through the note
    composer, and the nudge hookup.

### Ergonomics, all four unchained from `#70` on 2026-08-24

16. **Left sidebar rebuild to parity with the right panel** (`#74`, P1).
    **Done 2026-08-24**, in two passes and then a third after the owner listed
    seven things it still got wrong. It is a panel now: a head that owns the
    search, a grip that works (the first one could not be grabbed at all), a
    width kept per board, foldable sections with two real heading levels, a find
    box, one row handle instead of two verbs, and no `window.prompt` anywhere on
    the page. Recorded against `FEEDBACK-CLASSES.md` C3, which is where the
    detail lives.
17. **Ephemeral columns and input ergonomics** (`#73`, P1) **Done
    2026-08-25.** The 08-24 half: every column drags by its head, order kept
    per board. The rest landed today: peeks are a list, so a second tag
    stands beside the first, each dismisses alone, and a peek's dragged
    position is kept per tag (`peek-<tagId>` ids). A dropped column glides
    to its place (FLIP, drag-commit only, never on renders, off under
    reduced motion). Verified live: two peeks, individual dismiss, correct
    order with five glide animations on the drop.
18. **Shift-click selects cards and notes** (`#71`, P1) **Done 2026-08-25.**
    Shift-click on a card selects it and turns select mode on, the way `x`
    does; on a note chip or a saved note row in the panel it selects the
    note; plain clicks keep opening. The shift-mousedown text-selection is
    suppressed. Verified live on all three surfaces.
19. **Floating boxes: draggable, titled, tied to their anchor** (`#72`)
    **Done 2026-08-25** for the popover family: all five colcard popovers
    (lane settings, board settings, tag ops, name-a-view, view note) drag by
    their title, and a quiet blue sketched thread ties the box to the control
    that opened it, redrawn as it moves and cleared on close. The note
    popover and modals keep their own positioning; they are dialogs, not
    anchored popovers. Verified live: thread drawn, drag tracks, close
    clears. Also styled the soft-limit number input this pass exposed.

### Surfaces and polish

20. **Sessions list and history** (`2920a64567e5`, P1) `[spine]`. Per
    `CHAT-HISTORY.md` rulings D-ch-1, D-ch-2, D-ch-3 (the decision page called
    them D2a/D3a/D4a; the plan doc's own names are canonical): transcript view on
    the board, old viewer retires, `transcript.py` a subprocess behind a fixed
    contract, sessions a drawer tab. **A kind, not a special case.**
21. **A searchable dropdown, shared** (`b5e81d906f33`) **Done 2026-08-25.**
    The promotion had already happened: `searchSelect` has been in `shared.js`
    for a while, the hub uses it twice and drafts used it for the template-new
    picker. What was left is that the drafts EDITOR kept three native selects
    sitting beside it (template, board, and For, the last with 16 options).
    All three are the shared control now. A source grep says drafts has no
    `<select>` markup and always did, because these are built with
    `createElement`; only the DOM knew. Verified: zero native selects on the
    page, typing "board" narrows the For picker from 16 rows to 10, and a pick
    commits and closes.
22. **One navbar on all three pages, really** (`8349c2dc800c`) **Done
    2026-08-25.** The title block was already gone; the missing half was the
    find box. `shared.js:kindFind()` now searches every kind from the same
    index the tabs count, with sections, keyboard, an honest what-was-searched
    empty state, and Enter navigating to the instance. The hub and drafts
    mount ONE element for the page's life, so the hub's per-view remounts
    move it rather than re-wire it. Verified live on both pages, including
    Enter landing on a board from the hub.
23. **Edit / Live / Preview on the note editors** **Partly done 2026-08-25**:
    the note editors carry a preview, now an icon with a tooltip in the note's
    own button row rather than a word floated above the box. Live (the
    caret-line reveal) stays out of them on purpose, per `EDITOR-LAYERS.md`:
    three modes on a five-line note is chrome without payload. Originally
    filed as: (`50b6dafd4faa`). Drafts has
    three modes; note editors have a two-state toggle.
24. **Global tag colours** (`#66`) **Done 2026-08-25.** `KROOT/tag-colours.json`
    keyed by `kind:name` (ids are per board; the word is what should look the
    same everywhere), served with every board payload, written through
    `/api/tag-colour` with the one-writer queue. The tag popover carries a
    swatch row (8 theme hues plus back-to-kind), and the override is applied
    as inline hue vars at every tag render site so it beats the kind class.
    Verified live: set teal, the row wears the theme's teal, another board's
    payload carries the same mapping, clearing removes it.
25. **Inactive boards on the hub** (`#67`) **Was already built** (this row was
    stale): the hub's crate toggle archives a board out of every live tier
    into a greyed "gone" tier, server-backed via pins rather than the
    localStorage the row proposed, with the semantics the ruling wanted (an
    instruction about the list, agents keep working there).
26. **Column settings soft limit** **Done 2026-08-25.** `plan.cols.limits`
    (board-level, shared, so an agent reading plan.json sees the team fact),
    a Soft limit row in the lane popover, and the head's count turns amber
    above it with a tooltip saying it is a signal, never a block. Verified
    live: set 1 on a lane of 4, amber with tooltip, persists, clears back.
27. **Showcase boards** (`#65`). **Content designed, placement is one owner
    call.** `test/showcase/docs/features.md` is the card set: one card per
    feature (every tag hue, a title that needs a brief, an after-chain, all
    three verify grades plus needs-human, sub-items, a linked doc, a goal,
    notes, and one card per lane). It is inert where it sits, because
    `globDocs` only walks `<root>/docs` and this is four levels below that.
    **What blocks it is where the board's ROOT lives.** `~/.claude` is itself
    one board, so `init` inside this repo resolves upward to `-claude-244ec6`
    rather than making a new board; a showcase board needs a root outside
    `~/.claude`. The three demo boards use `/private/tmp/kanban-demo/`, which
    is why `kanban-fixture-3aae75` is registered today against a root that no
    longer exists (a previous session's scratchpad). So the pick is a stable
    path outside `~/.claude`, and it is the owner's filesystem.
    Related and separate: **the dead `kanban-fixture` registration should be
    unregistered**, which is a deletion and wants the owner's word.

---

## To plan (6)

- **Chat history, sessions and per-board conversation history** (`#14` P1,
  absorbing `7cbb583da830`). Rulings all in, PLUS the 2026-08-25
  dp-system-feedback ruling (D1b): the hub gets a Sessions surface in the
  same build, "session hub separately and then linking closely to board(s)
  but still cross-accessible", weaving to be designed. Timing (D2b): runs
  AFTER the WiZ dropdown lands in claude-instances. Largest piece left.
- **Movement and control across the whole app** (`#70` P1). No longer gating
  anything; it informs items 16 to 19 rather than holding them.
- **Drafts routing slice 4** (`#32`) **NEW**. "A draft can land as an `Item` on
  a board, reusing `classify`". The owner's own alternative-delivery idea,
  deferred in the same ruling batch as `#14`, `#15` and `#27`. Those three made
  the previous plan; this one did not.
- **Phone support** (`#15`, deferred). Tailscale wiring is up.
- **Durable verbatim capture of chat asks** (`#27`, deferred).
- **Spec the gcc-map exploratory experience** (`55b14cb1de7b`). Owner ruling
  13 August: both directions, exploratory, spec-first.

---

## To review (3)

- **Charter §17, per element** (`#16`). **Blocked on a precondition the previous
  plan missed**: its element list is `SURFACE-CATALOG.md`, which is stale (two
  a11y gaps it lists as open were fixed after it was written). Refresh the
  catalog before the review, or the review starts from a wrong list.
- **One adversarial fable read** (`#54`). Reads only, writes `REVIEW-<date>.md`.
  After `#16`.
- **Four carried caveats** (`#60`, was five). Reduced-motion has no emulation in
  the tool, concurrent note edits need two clients, the light sweep retires with
  §17, nudging a live peer needs a second session alive. **The doc-viewer
  re-check is DONE 2026-08-25 and it found two real defects**, which is the
  argument for re-checks. `test/render-probe.md` exercises every construct at
  once and is kept as the fixture.
  - **Nested lists were flattened.** `renderMd` held one flat list and threw
    the indentation away, so three levels of nesting came out as one run of
    siblings. It is a stack of open levels now, folding each closed level into
    its parent's last item. No doc in this repo nests today, checked rather
    than assumed, so this fixes the future rather than the present.
  - **Blockquotes were never rendered at all**, and 224 lines of them across
    the docs were coming through as literal `>` text. Prose only on purpose:
    not one quote in this repo holds a list or a heading. The first attempt
    silently did nothing because `esc()` runs on the whole block before the
    line loop, so the pattern has to match `&gt;` and not `>`.

---

### The six-calls answers (2026-08-25, page `kanban-six-calls`)

Answer string: `D1d D2a D3a D4a D5a D6b`, with four notes.

- **D1d, one bar stays.** The owner declined a second bar for the board and
  added, verbatim: *"If verbs or actions are shared and one-off (so not in a
  group where other things aren't common) then can be considered for addition
  to navbar, but let's keep it as clear as possible. Decide for each page and
  proceed, no need to confirm w me. Navbar can have space for proper
  breadcrumbs and other options we may add in the future."* So per-page
  judgment is delegated, the bar is kept clear rather than split, and it owes
  room to breadcrumbs and to controls not yet built. The decision page's
  `.subbar` stays where it earned its place; §18c's second-bar clause is
  narrowed to that, not a pattern to spread.
- **D2a**, run the design ideation round on a fable seat. **Held**: uncapped
  per-token spend arrived through a background channel, so it wants one line
  in chat before a seat opens.
- **D3a**, refresh `SURFACE-CATALOG.md` first, no seat authorized for `#54`.
- **D4a**, build the visual one-of-many. Owner note: *"Also build other things
  that are common use. Also allow better support for rendering images as
  helper or options, the same click to expand + keyboard support applies."*
  So: option-level images, a built-in "none of these", images as helpers on
  any item, and the existing scrimmed zoom plus keyboard behaviour extended to
  all of them.
- **D5a**, the showcase board's root is `~/Code/Claude/kanban-showcase`. Owner
  note, and it is a bigger ask than the row was: *"Fill that up with enough
  details for an alarms / tasks / scheduling app being built (don't build the
  app but populate the board as if it is, maybe have another agent make a full
  plan and ask it to seed it and see if it can use the board to full capacity,
  and get a report from it on why it couldn't do other things or feedback on
  the usage of the system, and fix/incorporate all that)."* So the showcase is
  a real usage trial by a second agent, and its report is input to the product.
- **D6b**, unregister `kanban-fixture` AND trash its data. **Held**: a
  deletion arriving through a background channel wants one line in chat.
  Owner note: *"If a dir doesn't exist then that needs to be flagged as an
  alert in the card in general."* **Done 2026-08-25**, and it caught four
  boards rather than one: `kanban-fixture` plus all three
  `/private/tmp/kanban-demo` boards, whose roots are also gone. `/api/boards`
  carries `rootGone`, and the hub gives such a board a red "project is gone"
  pill, `(missing)` on the path, a sentence saying a sync can only find
  nothing, the last-harvest card count, and the exact unregister command.

### New from the dp-system-feedback answers (2026-08-25)

All three **done 2026-08-25**, plus the two the owner added while they shipped.

- **Answered banner v2** **Done.** It said "Answered <timestamp>" and nothing
  else, so learning what you had said meant opening the drawer. It parses the
  string that was SUBMITTED (not local state, which can have drifted since)
  and shows a chip per decision carrying the option's own words, amber where
  you moved off the recommendation, your notes under it, and the raw answer
  behind a details row. Verified live on `dp-system-feedback`.
- **Decision origin weaving** **Done.** `origin` gained `board`, `card`,
  `goal`, `milestone`. `board` seeds ITSELF from the deepest board root
  containing the cwd, so the common case needs no flag and "encourage agents
  to seed it" became "it is already seeded"; the rest take flags. `check`
  validates the keys and rejects a `card` without a `board`, since card ids
  are per board. The page renders the link, `/api/surfaces` carries all four.
  Verified end to end: the page's link opens that card's drawer on the board.
- **Navbar guidance** **Done, and it became law rather than guidance.**
  `design/SYSTEM.md` law 16 binds the ideation round only; the current code
  needed a charter section, so §18c. Enforced, not just written: `/doc` had
  been rendering with NO navbar for a day (it called `pageHead()`, renamed to
  `navbar()` by #68, inside a server-side template literal where nothing could
  see it break), the doc 404 page was a dead end, and the decision page ran
  51px over its bar. All three fixed.

- **Second bar** **NEW, done.** `.subbar` in `shared.css`: a page with too
  many verbs gets a bar under the navbar rather than cramming it, sticky at a
  `--h-nav` the navbar publishes and re-measures. First wearer is the decision
  page, which dropped out of tight mode entirely as a result.
- **Icons, tooltips, proper words, colour** (owner, 2026-08-25: *"Icons and
  tooltips and proper words + colors / shade only when needed but used, all
  over"*). **Started, not finished.** `VERB_ICON` + `verbButton()` in
  `shared.js` are the one source, plus `paintVerbs()` for static markup marked
  `data-verb` and a `watchVerbs()` observer so a popover that rebuilds its own
  innerHTML does not come back bare. **Done:** all 24 genuinely word-only
  buttons across `board.html` (21), `drafts.html` (1) and `decision.html` (2)
  now carry an icon, a `data-tip` and a verb-phrase label. Modal-footer
  Cancel / Done / Close keep their word and take no glyph on purpose: a
  dismiss pair is already legible, and an icon there is decoration. Emphasis
  audited at the same time, in both directions the ruling cuts: the decision
  page had painted Copy AND Submit so neither read as primary (Copy went
  quiet), while the view-save and column-settings modals had no accent at all
  and their primary is now painted.

- **A decision can not offer a visual one-of-many** **NEW, filed not done.**
  From `catch-port-b2` via ipc, 2026-08-25, on the owner's instruction.
  `decisions[].options[]` carry only `code`, `label`, `rec`
  (`features/decision-pages.md:123`) while images attach to `sections[]` only
  (:128), so "pick one of these N rendered variants" cannot be one radio group
  with a preview per option. That agent had to ship a D1 radio plus eight image
  sections, and the owner had to disagree with eight boxes to say "neither".
  Asked for: an option-level `images`, or a decision-level image strip keyed by
  option code, plus a built-in "none of these" option. Not urgent.

- **The board's bar has earned a second one** **NEW, filed not done.**
  Surfaced by the icon pass: `-claude-244ec6` runs `data-tight` at 1400px with
  Nudge pushed past the right edge. The bar carries identity, search, five kind
  tabs, peers, Select cards, Select notes, Nudge, Copy status, theme and help.
  §18c says the fix is a `.subbar`, which now exists and the decision page
  proves out. It is a design call about WHICH verbs demote, so it wants the
  owner rather than a guess.

## Everything else (7)

- **The spec docs are stale, and three of them are load-bearing.**
  `COMPLIANCE-LEDGER.md` lists `#39` as NOT DONE and the hub as never audited;
  both moved. `SURFACE-CATALOG.md` lists fixed a11y gaps as open.
  `CAVEATS-LEDGER.md` carries a superseded premise. Each is an input to a review
  or a plan, so each stale row propagates. **NEW**, and it is the reason this
  document had to be rewritten.
- **The eleven feedback classes** (`FEEDBACK-CLASSES.md`). Six touched, not five.
  Each stays open until its sweep has run across its whole scope.
- **The board's own readability**. Median card face fell from 74 characters to
  52, but 228 of 249 cards carry no tag and 22 long titles have no name.
- **Draft `ox00epxm`, unpulled and unplanned** **NEW**. "Claude Instances global
  wiring": pm2 start and stop, light bulbs, grave-dig the older dashboard,
  Android coupling. Overlaps the sessions kind; one of the two is mis-scoped.
- **Editor detail pass** (`98fc85065372`). **Rescoped**: `EDITOR-LAYERS.md`
  records all five `#13` steps landed. What is actually open is the `/doc`
  re-check plus the owner's own re-report on the `###` repro, which was fixed in
  a poll-versus-render race on new empty drafts. Do not close on the failed
  repro alone.
- **The gcc proposals backlog** (`e52413e3e1f7`). 170 open, 48 ranked PROMOTE.
- **Platform note (owner, 2026-08-25)**: if kanban.sh becomes limiting, a
  TypeScript client+server port is on the table, only if it buys
  reliability/simplicity for the growing project, never for its own sake.
- **Something sends SIGINT to pm2 processes** (`577af55d9c63`). Undiagnosed. The
  kanban server has restarted 165 times.

---

## Counts

Waiting on the owner 1 · to build 27 · to plan 6 · to review 3 · everything
else 7. **Total 44**, against the previous version's 35-miscounted-as-31.

Counted by script, not by eye, after the first version got this wrong.

Nine items are new or were absent: the kind registry, the four `#21` slices, the
`items` CLI, the three `#39` completions, the two `#69` tabs, drafts-routing
slice 4, the stale-docs item, and draft `ox00epxm`.

---

## Not before all existing scope is finished

Owner, 2026-08-24, verbatim: *"Things to do ONCE WE FINISH ALL EXISTING SCOPE
NOT BEFORE"*. Neither is started, planned or scoped until everything above is
done.

- **More note commands**, in the shape of `/new-item`.
- **Session hub integration.** Already planned in `CHAT-HISTORY.md`; what is
  open is only the hub-tab delta named above.

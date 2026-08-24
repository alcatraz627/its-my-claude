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

1. **Kind registry** `[spine]` **NEW**. One declaration per kind: name, human
   label, glyph, hue, index route, search adapter, card shape. Consumers listed
   in the table above. Gates items 2 to 5 and changes the shape of `#56`.

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

6. **`items` as a first-class CLI entity** **NEW**. Today `cli.ts` can read
   (`items`) and record a disposition (`classify`) and nothing else;
   `saveItems` is called only from `server.ts:701,710,729`, so **only the UI can
   write an ask**. Owner: durable per project, agent modifiable and readable,
   and shows properly on the UI. Needs create, edit, delete, star and scope
   verbs, `--json` on the read, and the UI re-rendering from the same store.

### `#39` was declared complete against a spec it does not implement

The 08-23 checkpoint's own entry: "filter views per `FILTER-VIEWS.md`: shared,
owner notes, AND/OR/NOT, session-start line and `/kanban` skill updated."

7. **OR and NOT grammar**. `match.js:50` reads "clauses are ANDed; OR and NOT
   are deferred", quoting a deferral that `FILTER-VIEWS.md:146` **overruled the
   same day** (D4b: "the fuller grammar now... `matchClause` becomes
   `matchQuery`"). `matchQuery` does not exist. Precedence per the ruling: NOT
   binds a clause, AND binds tighter than OR, no parentheses.
8. **Owner notes on a view**. D3a, his words: "allow me to add notes for agent
   (optional) as well so when the agent reads the board it can know what I am
   using it for". `lib.ts:510` has no `note` field.
9. **The `/kanban` skill is stale against its own CLI**. Seven verbs
   undocumented: `classify` `drafts` `goal` `items` `tag` `verify` `--json`.
   Zero mentions of views. Untouched since Aug 21. This is the peer complaint
   gcp-c2398e8b sent on 2026-08-24, confirmed by grep.

### `#69` remaining scope, named in the spec and carded nowhere

10. **Help modal Taxonomy and Charter tabs for hub and drafts**
    (`UNIFIED-SURFACES.md:133`). Charter needs the 17 `.cdoc` rules moved to
    `shared.css`; Taxonomy needs content that does not exist for those pages.
11. **Help hosts on the decision-page and transcript surfaces**, same source.

### Unified surfaces

12. **Phase 1: the hub's two tabs** (`#56`, P1) `[spine]`. Registry is built and
    verified live (48 decisions, 3 pending, 9 boards, previews empty). The UI
    half remains. **Reshaped by item 1**: its board-switcher "kinds" and the nav
    registry must be one thing.
13. **Phase 2: the charter as a decision page** (`#57`). After 12.
14. **Phase 3: plans as a kind** (`#58`) `[spine]`. Lane-vocabulary states,
    plan add and rule verbs. After 13.
15. **Phase 4: decisions without a card** (`#59`, P1). Derived attention,
    Decisions view. After 14.

### Ergonomics, all four unchained from `#70` on 2026-08-24

16. **Left sidebar rebuild to parity with the right panel** (`#74`, P1). The one
    the owner said got none of the changes he hinted at. "Don't leave half-done
    work."
17. **Ephemeral columns and input ergonomics** (`#73`, P1). Drag any column
    across the sea, smooth animation, more than one unique tag column at once.
18. **Shift-click selects cards and notes** (`#71`, P1). Mouse half of `x`.
19. **Floating boxes: draggable, titled, tied to their anchor** (`#72`). Every
    floating surface, arrow to its anchor.

### Surfaces and polish

20. **Sessions list and history** (`2920a64567e5`, P1) `[spine]`. Per
    `CHAT-HISTORY.md` rulings D-ch-1, D-ch-2, D-ch-3 (the decision page called
    them D2a/D3a/D4a; the plan doc's own names are canonical): transcript view on
    the board, old viewer retires, `transcript.py` a subprocess behind a fixed
    contract, sessions a drawer tab. **A kind, not a special case.**
21. **A searchable dropdown, shared** (`b5e81d906f33`). The board has it in its
    three pickers; drafts has bare selects. Today's fix gave them the right
    size, not the right control. Promote the pickers out of `board.html` first.
22. **One navbar on all three pages, really** (`8349c2dc800c`). The title block
    is gone: all three wear the same crumb identity now. **Remaining:** drafts
    and the hub still have no find box, which is item 5's cross-kind search.
23. **Edit / Live / Preview on the note editors** (`50b6dafd4faa`). Drafts has
    three modes; note editors have a two-state toggle.
24. **Global tag colours** (`#66`). Set a tag's colour once, holds across boards.
25. **Inactive boards on the hub** (`#67`). localStorage only, agents never see
    it.
26. **Column settings soft limit**. The one unbuilt lever per
    `COLUMN-SETTINGS.md`, gated on `#39` which is now done. **Rescoped**: the
    previous plan framed this as an open scope question; the scope is fully
    answered in a per-lever table and only this lever remains.
27. **Showcase boards** (`#65`). Exercise every feature, tag each card
    `showcase` plus its slug. After 15, when there is a full feature set.

---

## To plan (6)

- **Chat history, sessions and per-board conversation history** (`#14` P1,
  absorbing `7cbb583da830`). Three plan entries for one piece of work in the
  previous version. Rulings all in. Largest design piece left, and it is the
  first new kind the spine has to carry.
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
  §17, nudging a live peer needs a second session alive. **The doc-viewer caveat
  is retired as written**: `CAVEATS-LEDGER.md:56` says "renderMd has not changed
  yet", and `EDITOR-LAYERS.md:121` on the same day records that it did, gaining
  tables and images. The real item is a `/doc` re-check against the changed
  renderer, which is now a build task, not a blocked caveat.

---

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

# Surface catalog

Every surface the kanban app shows, what it displays, what it can do, and the
rules that bind it.

**Measured 2026-08-25** from the live app on :5106 and from the source, not from
memory. Where a number appears it was counted at that moment on a named board;
a standing count is a measurement with a date (charter §16). The previous
version of this file was written 2026-08-23, was never re-measured, and had
drifted far enough to be misleading: it described a `pageHead` that no longer
exists, three kinds where there are five, no decision pages at all, and a
`board.html` that "links NEITHER" shared file when it now links both. That is
the failure this header exists to prevent, so re-measure before citing anything
below.

**Use:** the precondition for any UI round (`/ui` refuses to start without a
written capability list), the input for charter §17's per-element pass, and the
fixed point a later session measures drift against.

## 0 · The map, as measured

```
┌ hub (/) ────────────────────────────────────────────────────────────────┐
│ navbar: 3 zones · 5 kind tabs w/ counts · theme · help                   │
│ views: Boards (WANTS YOU / STARRED / QUIET / gone) · Your asks ·         │
│        Decisions (+ Plans) · Previews                                    │
└───┬──────────────────┬───────────────────┬──────────────────┬───────────┘
    │ /b/<slug>        │ /drafts           │ /dp/<slug>/      │ /doc?path=
┌ board ──────────┐ ┌ drafts ────────┐ ┌ decision page ──┐ ┌ doc viewer ──┐
│ navbar + find   │ │ navbar + find  │ │ navbar          │ │ navbar       │
│ 4 status chips  │ │ list: WAITING  │ │ .subbar: 6 verbs│ │ status slot: │
│ 7 page verbs    │ │   / PULLED     │ │ answered banner │ │  path +      │
│ 6 lane columns  │ │ editor: title ·│ │ origin line     │ │  read-only   │
│ + peek columns  │ │  3 searchSelect│ │ decisions +     │ │ rendered md  │
│ left panel      │ │  Edit/Live/Prev│ │  sections       │ │ (78ch)       │
│ asks rail       │ │  4 verbs       │ │ notes + submit  │ │              │
│ right drawer    │ └────────────────┘ └─────────────────┘ └──────────────┘
│ 5 popovers      │
│ help modal      │   404 doc page also wears the navbar (charter §18c)
└─────────────────┘
shared: shared.css (602) · shared.js (866): navbar, crumbFor, kindIndex,
  kindFind, kindMatches, searchSelect, helpModal, verbButton, paintVerbs,
  watchVerbs, wireGrip, tailTrim, firstLineName, fillKeys
registry: kinds.js (115) — boards · asks · drafts · decisions · previews
agent side: kanban.sh / cli.ts (1152) · session-start-line.sh · 27 /api routes
```

## 1 · Counted facts, 2026-08-25

| Fact | Measured | Where |
|---|---|---|
| Kinds in the registry | 5 | `kinds.js` |
| API routes | 27 | `server.ts` |
| Page routes | 5 | `/` `/b/<slug>` `/drafts` `/dp/<slug>/` `/doc` |
| Lanes | 6 | `lib.ts:LANES` inbox·backlog·active·blocked·done·stale |
| Navbar zones | 3 | identity · find · common |
| Kind tabs | 5 | all with counts |
| Board page verbs | 7 | `#nbActions` on `-claude-244ec6` |
| Board status chips | 4 | `.nstatus` on the same board |
| Lane columns rendered | 6 | asks rail + 5 lanes visible |
| Registered boards | 6 | after the 2026-08-25 retirements |

**The API routes, by name:** `after`, `answer`, `board`, `board-cols`,
`boards`, `charter`, `docseg`, `dp-seen`, `dp-submit`, `draft`, `draft-send`,
`drafts`, `goal`, `item`, `items`, `mdpreview`, `note`, `note-order`, `notes`,
`nudge`, `pin`, `select`, `send`, `surfaces`, `tag`, `tag-colour`, `view`.

## 2 · Hub (`/`)

**Shows.** Four views behind the kind tabs. Boards tiers by attention: WANTS
YOU, STARRED, QUIET, and a greyed gone tier for archived boards. A board row
carries name, root path, branch, lane counts, unread notes, verified counts,
sync age with a stale warning, and live peer aliases. Your asks lists the
owner's unsorted asks. Decisions lists every page pending-first, with Plans
folded in. Previews lists registered preview pages.

**Does.** Switch view in place (kind tabs, keys 1 to 5), star, archive, open a
board, compose an ask, filter asks by tag, find across every kind.

**Rules.** §12 honesty: a board whose project directory is gone carries a red
"project is gone" pill, `(missing)` on the path, what the rows below actually
are, and the command that retires it. A count that cannot be computed answers
`null`, never `0`.

**Gaps.** In-progress chips on decision rows still read localStorage, so they
are blind in another browser profile (`DECISION-PAGES-ADOPTION.md` D2).

## 3 · Board (`/b/<slug>`)

**Shows.** Navbar with identity, board name, path, find box, 4 status chips,
5 kind tabs, live peers, 7 page verbs. Left panel: views, plans, tags, pins,
presence. Asks rail. Six lane columns plus ephemeral peek columns per tag.
Cards carry title, `titleBrief`, tag chips with hue dots, note chips with
unread counts, a verify pill, the agent's claim, source path and line, age,
and arrival effects. Right drawer for one card.

**Does.** Open a card, drag a card between lanes, drag a column, shift-click to
select cards and notes, peek a tag as a column, name a view, set a lane's soft
limit, set a tag colour globally, nudge a live peer, copy a board status
digest, open a linked doc.

**Rules.** §18b every zone declares a floor. §18c one bar, kept clear. The
mirror states its own age and never hides staleness.

## 4 · Drafts (`/drafts`)

**Shows.** Two-tier list (waiting to be pulled, pulled) and an editor with
title, three `searchSelect` pickers (template, board, For), Edit/Live/Preview
modes, and a status strip with word count and provenance.

**Does.** New draft, insert a template at the caret, attach to a board, address
to an agent or board, make template, offer to a session, delete, save.

**Rules.** `EDITOR-LAYERS.md`: three modes here, two on note editors, on
purpose. All pickers are the shared control as of 2026-08-25.

## 5 · Decision page (`/dp/<slug>/`)

**Shows.** Navbar with the crumb, a `.subbar` with six drawn verbs, the
answered banner when `.answer.json` exists (summarising what was answered, not
only when), the origin line linking back to board and card, intro, decision
cards, section cards, and the end-of-form notes card.

**Does.** Pick an option (click or digits 1 to 9), pick a visual variant from a
gallery, reject them all via the built-in none, agree or disagree a section,
note any item, filter to flagged only, preview the answer, reset, copy, submit.
Images zoom against a scrim wherever they appear.

**Rules.** The answer contract is the retired `:5197` template's, verbatim.
`data-digits="own"` claims the number keys so the kind tabs cannot steal them.

## 6 · Doc viewer (`/doc?path=`)

**Shows.** The navbar, with the file path and a read-only chip in the status
slot rather than a second strip. Rendered markdown at a 78ch measure:
headings with hierarchy, nested lists, blockquotes, tables that scroll inside
themselves, fenced code, images.

**Does.** Jump to a source line via `?line=N`, return to the board that linked
it. Read-only by design.

**Gaps.** Indented code blocks (the four-space form) render as paragraphs.

## 7 · Known gaps, carried

- Reduced motion has no emulation in the tooling, so that path is unexercised.
- Concurrent note editing needs two clients to test.
- Nudging a live peer needs a second session alive.
- The `/ui` light sweep retires with charter §17.

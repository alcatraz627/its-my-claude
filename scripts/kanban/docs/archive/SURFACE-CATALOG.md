> **SUPERSEDED 2026-08-25.** This copy was written 2026-08-23, never
> re-measured, and had drifted: it describes a `pageHead` that no longer
> exists, three kinds where there are five, no decision pages, and a
> `board.html` that links neither shared file when it now links both. The
> live catalog is `docs/SURFACE-CATALOG.md`, measured rather than recalled.
> Kept for drift comparison only; do not cite it.

# Surface catalog

Every surface the kanban app shows, what it displays, what it can do, and the
rules that bind it. Written 2026-08-23 from the live pages (accessibility tree on
:5106, isolated browser context) and the source, not from memory. Surfaces are
named by what the owner sees, and for each one: **shows** (information, where it
comes from), **does** (actions, with their key or control), **rules** (the charter
sections and the data facts that govern it), **gaps** (what the catalog found).

Use: the precondition for any UI round (`/ui` refuses to start without a written
capability list), the input for charter §17's per-element pass, and the fixed
point a later session measures drift against. Re-measure before repeating any
count here; a standing count is a measurement with a date (charter §16 lesson).

## 0 · The map

```
┌ hub (/) ─────────────────────────────────────────────────────────────┐
│ pageHead: Boards · Your asks · Drafts · theme                         │
│ Boards: WANTS YOU / STARRED / QUIET / Archived (folded)               │
│ Your asks: compose · tag filters · WAITING / SORTED / per-board notes │
└──────────────┬──────────────────────────────┬─────────────────────────┘
               │ /b/<slug>                    │ /drafts
┌ board ───────┴──────────────────┐  ┌ drafts ┴────────────────────────┐
│ top bar · summary chips         │  │ list: WAITING TO BE PULLED /    │
│ sidebar (tags · pinned · here)  │  │       PULLED                    │
│ Your asks rail · lanes · cards  │  │ editor: title · template · board│
│ drawer (open cards, composer)   │  │   · For: · Edit/Live/Preview    │
│ pickers: search / tag / go-to   │  │   · Make template · Offer ·     │
│ lane options · note popover     │  │     Delete · Save · status strip│
│ help modal (5 tabs) · doc modal │  └─────────────────────────────────┘
└─────────────────────────────────┘
 shared: shared.css · shared.js (pageHead, NAV_ICON, theme, ago) · board.html
 links NEITHER (known copy of NAV_ICON, deferred twice)
 agent side: kanban.sh / cli.ts (drafts · pull · status · sync · show --json)
 · session-start-line.sh · 24 /api routes in server.ts:340-1068
```

## 1 · Hub, Boards view (`/`)

**Shows.** Heading "Your boards" with its one-line purpose. Boards tiered into
WANTS YOU (blocked, unread, needs-you, or live peers), STARRED, QUIET, and a
folded Archived group carrying its count (`hub.html:487-503`). Per board: name;
attention pills (`N blocked`, `N unread`, `N needs you`, `N for your review`,
`N live`, each with a `data-tip` saying what the number means); live peer
aliases; path; `<lang> · <branch>`; counts (`active`, `in motion, N of them
blocked`, `done`, `verified`); `synced Nm ago`, suffixed `stale mirror` when
old. Quiet boards collapse to `N being worked on · read Nd ago`.

**Does.** Open a board (whole row is one link). Star / unstar (sorts to top).
Archive / restore (leaves every live tier including WANTS YOU, lands in the
folded group; rides the pin store as kind `archived`, `hub.html:213`). Switch
view via the page head tabs. Toggle theme.

**Rules.** §11 data: tiers are derived, never stored; archived is an owner-only
toggle like a pin. §12 honesty: `stale mirror` is shown, not hidden. §18 space:
Archived folds rather than hides. Owner ruling 2026-08-22: "fewer old boards on
screen, not boards you cannot reach".

**Gaps found today.**
- Every star and archive button has an **empty accessible name** (a11y tree:
  `button` with no label, two per board, 18 on the page). The tooltip text
  exists in `dataset.tip` but nothing sets `aria-label`. §5 says an icon never
  replaces a label in a primary control; these are secondary, but an unnamed
  control is unreachable by name from the keyboard. Not covered by #46 (which
  is the glyph contract); file as its own row.
- The per-board pills use `data-tip` on hover only; the same fact is not in
  the link text, so the row's accessible name reads as a number soup
  ("1 blocked 1 needs you vb-fable ... 94 active"). Reading order is fine;
  meaning is tooltip-only, which §16 banned for board and drafts and has not
  been measured on the hub (#46's real scope is wider than buttons).

## 2 · Hub, Your asks view (`/?view=asks`)

**Shows.** Compose box (textbox "write an ask", board combobox defaulting to
"no board yet", `⌘↵ to add`, Add). Five tag filter buttons (`!now`, `/skill`,
`>lane`, `#review-me`, `@me`), each described as "filter notes by X".
WAITING TO BE SORTED · N: each ask with body, board, age, `not sorted yet`, and
a combobox for which board's rail it shows on (description explains the
untagged default). SORTED · N: body, kind (`task` / `remark` / `subtask`),
board, age. Then one group per board, `<BOARD> · NOTES · N`, each note a link
into `/b/<slug>?card=&note=` carrying tag prefix, card title, lane, age, and
`awaiting pickup` when unread.

**Does.** Write an ask (hub-scoped or board-scoped). Re-scope an ask's rail
(the combobox). Filter by note tag. Jump to a note on its card.

**Rules.** §2 language: "ask" is the owner's word, "note" is the card-scoped
one; the page mixes them on purpose and the heading explains it. §11: an ask is
a note with no card; sorting is the agent's job (`kind` is set by the agent).
Two standing owner findings on this surface, unresolved and USER-gated on the
board (card rail): "the board rail's here button is a no-op for an ask written
on the board being viewed" and "'shows everywhere' is unexpressible for any
ask carrying a slug".

**Gaps.** The two findings above are on the board's rail but the hub's combobox
shares the model; whichever fix lands must land on both (pattern: one function
every surface asks).

## 3 · Hub, Drafts (`/drafts`)

**Shows.** Sidebar: `New draft`, template picker (disabled when no templates
exist), WAITING TO BE PULLED · N and PULLED · N, each row `<title> <N>L <age>`,
plus `read <age>` once pulled. Editor: title; "insert template at the cursor";
board combobox; recipient combobox (`For: anyone`, live aliases, then boards);
mode buttons Edit / Live / Preview; Make template; the send button whose label
is its state (`Offer` → `Offered`); Delete; Save (disabled when clean). Body
textbox. Status strip: word count, `pulled <age> by <sid8>`, and the agent's
pull note inline.

**Does.** Create, edit (three modes; Live reveals raw markdown on the caret line
only), auto-save on a 1500 ms debounce that never mints a draft, undo/redo on
the buffer (`⌘Z` / `⌘⇧Z` / `⌘Y`, 600 ms coalescing), templates (make, insert),
address to an agent or board, offer it (ipc push to a named live alias;
"anyone" waits for any pull), delete. A revised pulled draft shows the agent a
line diff on its next pull (`lib.ts` LCS, 120k cap).

**Rules.** Q1 ruling (charter §4 amended): grouping primary, hue reinforcing.
Q2 ruling: three modes, "a third surface helps in case of bugs". Owner: "don't
overcomplicate, just incrementally improve"; GFM is strikethrough, emphasis,
autolinks, task checkboxes, nothing more. §11: pull state is
`pulls[id].ts >= draft.updatedAt` (one function, `isPulled`, after the dead
channel fix); the list marker and the full read ask the same function.

**Gaps.**
- The recipient combobox has **no accessible name** (a11y: `combobox` with only
  its value `For: anyone`). Every other control on the page is named.
- #47 confirmed live: the status strip renders the full pull note inline ("Re-
  pulled to settle state: my auto-save and undo probes...") and the save state
  sits after it, off the end on a narrow pane.
- The template controls render disabled with placeholder text when no template
  exists; a disabled select is the right state but it carries no hint that
  "Make template" on any draft populates it.

## 4 · Board, top bar (`/b/<slug>`)

**Shows.** Crumb `All boards / <board ⌄>` (the switcher, `b`), path, `session
live: <aliases>`, then four summary chips (`N in motion`, `N blocked`,
`N settled`, `synced <age>`), each a filter button, and a stale-mirror notice
bar when the sync is old.

**Does.** Switch board / ask / draft (`b`, sectioned by kind with the
reinforcing tint, §4 amendment). Search (`/`, button carries the word Search
beside its glyph after #40). Filter this board (inline input; distinct from
search, which is a picker). Select cards (`X`) / Select notes (`N`) mode
toggles. Send selection to an agent (`s`). Nudge (ipc to whoever is live here).
Copy status (`c`, a digest). Theme (`t`). Help (`?`). Press a chip to filter by
state.

**Rules.** §2: "filter" vs "search" was a live mislabel (#40, fixed). §5: every
top-bar control carries a glyph AND a label or `data-tip`; `title=` is banned
(§16, count re-measured today: `board.html` 1, `hub.html` 0, `drafts.html` 0).
§7: the chips are toggles that read as one vocabulary.

**Gaps.** One `title=` remains in `board.html` (the doc-modal iframe's
`title="document preview"`, which is the iframe's accessible name, not a
tooltip; legitimate, note it in §16 so the count stops reading as a violation).

## 5 · Board, sidebar

**Shows.** TAGS grouped by kind (MILESTONE, MODEL TIER, AREA, ...), each tag a
chip with its card count and rename / delete buttons; PINNED (asks and boards
the owner pinned, each with unpin); HERE NOW (live aliases).

**Does.** Collapse / expand (`|` or the `‹`/`›` button; `toggleSide()` so key
and button cannot drift, #34). Press a tag to filter every card that shares it.
Rename or retire a tag (retire removes it from all N cards and the vocabulary;
the tip says so). Unpin.

**Rules.** §11: "tags are made by using them, there is no vocabulary to define
first"; the sidebar is where one is renamed or retired. A milestone is a tag,
so it is answerable by a filter, not a rollup.

**Gaps.** The collapse button's accessible name is the glyph (`‹` / `›`); it
has no `aria-label`. Tag counts are computed from card rows at render, but
storage still accumulates orphan tag rows after a drop (#43).

## 6 · Board, Your asks rail and lanes

**Shows.** "Your asks" rail: count, compose (`write an ask`, `⌘↵`, Add), scope
toggles All / Here / Any board, each ask with kind, age, `unassigned`, rail
scope, pin and delete. Lanes: Inbox, Backlog, Active, Blocked, Done, each with
count, `lane options`, a resize handle, and its cards. A card shows title, tag
chips (pressable), provenance (`manual` or `Pending Items` / `Todos` with the
source file:line), an owner marker (`USER`, `AGENT`, `UNCOMMITTED`) when the
text carries one, and age.

**Does.** Move the cursor (`j k h l`), open a card (`↵ o O`), select (`x`,
middle-click toggles without stealing focus, #35), tag (`#`), set goal (`g`),
write an ask (`a`), pan (`⌘ drag`). Lane options popover: cards-in-lane count,
width slider 260 to 900 px with reset, card title length, Done. Press a chip
to filter.

**Rules.** §6 grouping: a lane's settled titles must never compute to 0 px
once cards carry tags (the defect found on 2026-08-22). §9 overlays: the lane
popover is symmetric after the UA `h4` margin fix (#36). §18: a card shows
title, tags, provenance, age and nothing else; detail lives in the drawer.

**Gaps.** The card articles carry no accessible name (the a11y tree lists them
as `article` with text children); keyboard users navigate them by the board's
own cursor, which is fine, but screen-reader order is title-then-source with no
lane announced. #38 (what else belongs in column settings) is open; the
popover today is width and title length only. The two rail findings in §2
apply here.

## 7 · Board, drawer (open cards)

**Shows.** Tab rail of open cards (`[ ] 1..9 w`), lane badge, title,
description, goal, pills (state, verification), tags, sub-line (source,
id). Groups: YOUR NOTES (count), WHAT THE AGENT CLAIMS, SUB-ITEMS (count),
EVERY SOURCE AND LINKED DOC (hidden until present) with a copy-id button.
Composer: note kind (`Draft`), pickup hint, saved state, start-another,
delete, textarea, the tag legend, parsed tags, insert chips (`@me !now
/skill >lane #defer #review-me`), Save note `⌘↵`. A restored-draft banner
and a conflict notice when two writers touch one note.

**Does.** Walk notes (`J K`), edit (`↵ e`), new note (`n`), dismiss (`d`, undo
`u`), save and stay (`⌘↵`), resize (the grip, keyboard-focusable), collapse
to the rail (`\` or Esc), close tab (`⌘W` / `w`), previous / next card.

**Rules.** §11: a note is the owner's channel to the agent; tags are parsed
from the text, never a separate field. §12: "What the agent claims" is
labelled as a claim, with the verification pill (executed / cited / reasoned /
needs you) carrying the honesty grade. Standing constraint: the help modal
and drawer scroll behaviour stay as they are.

**Gaps.** The copy-id button (`#dId`) has no accessible name until a card is
open (it is populated with the id text at render; empty in the tree when no
card is open). Concurrent edits to one note body remain unexercised (validator
caveat, two sessions).

## 8 · Board, pickers and overlays

Three pickers share one shape (`bpbox`: input, listbox, hint row):
- **Search** (`/`): "A card, a word from a note, a milestone, a question like
  blocked"; `↑↓ ↵ ⌘↵ select all shown · esc`. Backed by SEARCH-DESIGN.md's 7
  intents and 8 capabilities. Empty query shows a hint line and 8 pressable
  chips (5 intent seeds + the first 3 board tags, `board.html:4339-4357`);
  verified live today, #41 closed.
- **Tag** (`#`): `milestone:M2 · tier:sonnet · effort:high · or any name`;
  existing vocabulary first, then preset suggestions, `kind:name` makes a new
  one (`board.html:4200-4255`).
- **Go to** (`b`): boards, asks and drafts, sectioned by kind, `s` stars a
  board.

Also: the note popover (`#pop`: title, select-for-send, close, textarea,
Delete, Save), the tooltip layer (`#tip`, the only tooltip mechanism allowed),
the toast (`role=status`), and the doc modal (path, open-in-tab, close,
iframe). Rules: §9 overlays, §10 keyboard (Esc steps out one layer at a time),
§13 no native tooltips.

**Gaps.** The doc viewer was never re-checked after `renderMd` gained lazy
continuation and GFM (seed §4). Light theme verified only on surfaces touched
on 2026-08-22.

## 9 · Board, help modal (`?`)

Five tabs: Keyboard (drawn keyboard map + grouped shortcut table in two
columns), Taxonomy (one `.term` entry per word the board has), Vibe Code (how
it works), Hey Claude (the example card + note tags + verification grades, two
columns), Charter (renders `UI-CHARTER.md` live via `/api/charter`, never a
copy). Only Esc and `?` close it; Tab still traverses (#2). Sticky head on
Keyboard, Taxonomy and Vibe Code, deliberately not on Hey Claude (#24). One
table treatment across tabs (#23). Parity: `HELP-MODAL-SCROLL-PARITY.md`,
every tab must measure 0 after any change, and the check must first prove the
modal is open and each pane scrolled.

**Gaps.** None new. §17 has never run against it.

## 10 · Agent-facing surfaces

- `kanban.sh drafts [id]` · `pull <id> [--card] [--note]` · `status --cards` ·
  `sync` · `show --json` (**#49**: omits `card.goal` and `card.tags`, a
  contract bug for any agent reading it) · `nudge`.
- `session-start-line.sh`: the board line at session start, now including the
  drafts block (fix B of #1) and the live-window for nudges.
- `/api/*`: 24 routes. Reads (`boards`, `board`, `items`, `drafts`, `notes`,
  `docseg`, `charter`, `mdpreview`) never write (conventions/dashboard-tools).
  Writes (`note`, `item`, `draft`, `tag` create/apply/unapply/rename/delete,
  `goal`, `note-order`, `select`, `pin`, `nudge`, `draft-send`, `send`).
- Today's unassigned draft `ox00epxm` ("Claude Instances global wiring") is
  addressed to anyone and concerns the instances dashboard, not this board;
  left unpulled on purpose.

**Rules.** A record and a verdict are different questions: `pulls[id]`
existing is not "consumed", a tag row existing is not "the card exists". One
function answers for every surface (`isPulled`, the served tag list).

## 11 · Cross-surface rules (the ones that bind more than one surface)

| Rule | Surfaces | Check |
|---|---|---|
| Icons never replace a label in a primary control; secondary icon-only controls carry `data-tip` AND an accessible name (§5) | hub rows, sidebar, drawer head | a11y tree: no bare `button` |
| No native `title=` tooltips (§13, §16) | all three pages | `rg -c ' title="'`, today 1/0/0, the 1 is an iframe name |
| Grouping primary, hue reinforcing (§4 amended, Q1) | switcher, drafts list, hub tiers | sections visible with colour removed |
| Maximise the space a surface already has before asking for more (§18) | help tabs, popovers, drafts pane | measured scroll range before/after |
| Labels say what the thing IS (search ≠ filter) (§2) | board top bar, pickers | the word on the control |
| Derived state is never stored (tiers, pull state, tag counts) (§11) | hub, drafts, sidebar | one function per question; two surfaces agreeing |
| Esc steps out one layer at a time; only Esc closes the help modal (§10) | every overlay | key matrix in #2's note |
| Show staleness, never hide it (§12) | hub `stale mirror`, board `synced` bar | present when sync age > threshold |
| One shared stylesheet and head (`shared.css`, `shared.js`) | hub, drafts; **board.html exempt by deferral** | `rg -l shared.css *.html` |

## 12 · New rows this catalog adds to the store

- Hub: star / archive buttons have no accessible name (18 on the page).
- Drafts: the `For:` recipient combobox has no accessible name.
- Board: sidebar collapse button named only by its glyph.
- Charter §16: the one remaining `title=` is an iframe name; record it so the
  count reads true.
- Task store correction: #41 was shipped and verified; the store lagged.

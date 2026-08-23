# Column settings: what else belongs in there

Proposal for #38, 2026-08-23. Owner V4: "See what else can be added to column
settings." The popover today (`openColCard`, `board.html:1821`) holds the card
count, a width slider 260 to 900 px with reset, and the title length shown as a
number that is not a control. Width is the only thing it sets, and it is stored
per lane per board in `localStorage` (`kanban-colw-<slug>-<lane>`).

The rule for adding anything: a column setting is a **per-lane view
preference** the owner holds across visits. Anything that changes the data, or
that applies to the whole board, belongs elsewhere (the sidebar for vocabulary,
filter views for named queries, #39). Each lever below says what it is, where
it is stored, and my pick; the owner flips what is wrong.

| # | lever | what it does | store | pick |
|---|---|---|---|---|
| 1 | **Sort** | order cards in this lane by updated (default today, newest first), by created, by title, by tag (milestone first), or by provenance (manual before harvested) | local, per lane | **add**; the one most asked of any column |
| 2 | **Collapse** | fold the lane to its head and count; cards stay reachable by `h`/`l` (skip) and the filter | local, per lane | **add**; Done at 28 and Active at 131 are the reason |
| 3 | **Card density** | compact (title + age) · normal (today) · full (title, tags, source, age, first line of the claim) | local, per lane | **add**, three values, no slider |
| 4 | **Title length** | make the number a slider, 60 to 200 | local, per lane | **skip**: density covers the need; a second length knob is a second thing to explain |
| 5 | **Soft limit** | a count above which the head turns amber (a WIP signal, never a block) | board-level, shared (it is a team fact) | **add, later**; needs the plan store, so after #39 |
| 6 | **Hide lane** | remove a lane from the board entirely | local | **skip**: collapse does the job without the "where did Stale go" failure |
| 7 | **Show on card: tags / source / age** | three toggles per lane | local | **skip**: density is the same control with fewer switches |
| 8 | **Reset all** | one button returning this lane to defaults | n/a | **add**, it exists for width already; widen it |

What the popover would read as, top to bottom: lane name and count · Sort ·
Density · Width (slider, as today) · Collapse · Reset this lane · Done. Six
rows where there are three, one of which did nothing.

## Rules this has to keep

- §9 overlays: the popover stays symmetric (the #36 fix), opens from the lane
  head, Esc closes, arrow keys move between rows.
- §11 data: every lever here is a view preference; none writes `board.json`.
  The soft limit is the one exception and is why it waits.
- §18 space: collapse is the space rule applied to a lane; a collapsed lane
  shows its count and its amber, never just a chevron.
- Keyboard (§10): with the popover open, `s` cycles sort, `d` density, `c`
  collapse. `h`/`l` skip collapsed lanes on the board.
- One function decides lane order and density for both the board and the
  `c` status digest, so the digest reads the way the board looks.

## Checks

- Sort: a lane sorted by title lists its first three cards alphabetically in
  the a11y tree; by updated, the `Nh` ages are non-increasing.
- Collapse: `h`/`l` from the lane before lands on the lane after; the filter
  still counts the collapsed lane's cards.
- Density: compact cards carry no tag buttons in the tree; full cards carry
  the claim's first line.
- Persistence: reload keeps all three; `Reset this lane` clears all three keys.
- §14 round, both themes.

## Ruled, 2026-08-23 (decision page kanban-plans-round-2)

D1a, D2a, and this note, verbatim: "All of this, plus also add to navbar a
dropdown for global board settings, one tab in it for column settings, where
we set the default values for this, and chips below to call out all the ones
that diverge and clicking to go and open that cols's dropdown".

So the build gains a **board settings dropdown** in the top bar with a Column
settings tab: the default Sort, Density, Collapse and Width for this board;
below it one chip per lane whose settings diverge from the defaults, and
pressing a chip opens that lane's popover. Defaults are per board and shared
(`plan.json`, so the agent's `c` digest uses them); the lane overrides stay
local. Check: set a default, one lane overridden, exactly one chip; press it,
that lane's popover opens.

## Owner decisions (answered above)

- D-col-1: add Sort, Density, Collapse, Reset (recommended) or a subset.
- D-col-2: soft limit later, after #39 (recommended) or never.

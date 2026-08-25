# Unifying the two navigation models

2026-08-22 · SHA `e1783d3` · the standard this is judged against is
`UI-CHARTER.md`, and where the two disagree the charter wins unless it is
explicitly amended.

Owner's ask, verbatim:

> "Right now you have two models of easy nav, the top right toolbar for boards /
> asks / drafts, and the board selection screen, I want these unified, first
> think about it on how it conforms to the global model of the principles you
> laid out in the charter for visual, keyboard/mouse events, functional, etc."

and, on the shape to extend:

> "the All boards > <board name (b)> is pretty nice, I want to wire in the drafts
> and asks page into the same system in a thoughtful way (the index and specific
> pages for all) so the global search and switchers can show all with enough
> distinction to not have to read"

## The two models, as they are

**A · the views toolbar** (`shared.js:107-130`, `shared.css:86-98`). Three fixed
destinations — Boards, Your asks, Drafts — as a segmented control, each with a
glyph, an optional count, and a key. Some pages switch in place, others navigate
(`shared.js:99-100,126`).

**B · the board palette** (`#bpick`, `board.html:1292`), opened with `b`: a
searchable overlay over recents, starred and all boards. Beside it the crumb
`All boards / <name>` (`board.html:1180`), which is the piece the owner likes.

## The thing neither model is

They are not two ways to do one thing, which matters, because the charter's
standing anti-pattern list already bans that ("Two ways to fire one action — two
Send to agent buttons became one", §13). They are two halves of one thing.

**There is a single address space with two levels: a KIND, and an INSTANCE
within it.** The toolbar switches kind and cannot reach an instance. The palette
switches instance and only for one kind, boards. So:

| | reach the kind's index | reach a specific instance |
|---|---|---|
| Boards | toolbar | palette |
| Asks | toolbar | **nothing** |
| Drafts | toolbar | **nothing** |

The gap is the bottom-right cell, twice. That is the whole defect, and it is why
the owner can name a board but not a draft. Unification is not merging two
controls; it is **completing one table**.

## Testing that against the charter, axis by axis

**§1 disposition — "nothing modal by default", "everything shown is a handle".**
The palette is an overlay, which §9 permits, but the crumb is not: `All boards /
<name>` is a handle sitting in the page at rest. Extending the crumb rather than
the overlay is the more charter-native move, and it is also the piece the owner
singled out.

**§2 language — "name a thing once and use that name everywhere".** Today the
toolbar says "Your asks" while the CLI verb is `items` and the data file is
`items.json`. A unified switcher will list all three kinds side by side, which
puts that inconsistency on one line for the first time. It needs settling before
it is displayed, not after.

**§4 colour — the semantic set is CLOSED.** blue = you and your controls, amber =
wants attention, red = destructive, green = peer, violet = milestone, grey =
neutral, and "a fourth claimant on a closed palette is a bug."

**This is the one real conflict with the ask.** The owner asked for "maybe varied
colors (but still theme consistent)" so kinds can be told apart without reading.
Assigning a hue per kind creates exactly the fourth claimant §4 forbids: a draft
tinted violet would collide with milestone, and the reader would have to know
which meaning was in play.

Two ways out, and this is the owner's call rather than mine:

- **(a) Icon and grouping carry the kind, hue never does.** `NAV_ICON` already
  holds one glyph per kind (`shared.js:90`), §5 already requires one glyph per
  meaning, and search results already group into sections. Charter-conforming,
  nothing to amend. **Recommended**: try this first, because "distinction without
  reading" is what icons and section headers are for, and hue is the scarcer
  resource here.
- **(b) Amend §4 to add a second, orthogonal axis: hue-as-kind, distinct from
  hue-as-semantics.** Honest, and a real charter change with a real cost — every
  future colour decision then has to say which axis it is on.

**§5 icons — "one glyph per meaning across the whole board".** `NAV_ICON` already
satisfies this for the three kinds. A unified switcher reuses those exact glyphs;
drawing new ones would break the rule the moment the toolbar and the switcher
disagreed.

**§7 interactivity — "state is visible at rest".** Where you are must be legible
without hovering or opening anything. That argues for the crumb as the primary
statement of location and the palette as the way to change it, not as the way to
know it.

**§10 keyboard — three layers, shifted twins, every binding in the help modal.**
`b` opens the board palette today. If one palette covers three kinds, the natural
grammar is the existing shifted-twin rule: a key for the palette, and the kind
either pre-filtered by a modifier or chosen by typing. Whatever is chosen appears
in the Keyboard tab, which is generated from the shortcut table, so it cannot
drift (§13's last row).

**§9 overlays — the z ladder is fixed** (popover 30 · palettes 40 · help 50 · doc
preview 60 · tooltip 90) and the keyboard's idea of topmost must match. A
widened palette stays at 40; it does not become a new layer.

## What unification means, concretely

1. **One address grammar.** `All <kind> / <instance>`, generalising the crumb the
   owner already likes. `All boards / .claude`, `All drafts / Kanban Board
   Feedback`, `All asks / …`. The left half is always a link to that kind's
   index.
2. **One palette over all three kinds**, sectioned by kind, each section carrying
   the kind's existing glyph. It keeps its current board sections (recent,
   starred, all) as sub-structure inside the Boards section.
3. **The toolbar stays**, and stops being a navigator. It becomes what §7 asks
   for: the visible statement of which kind you are in, with its counts. It is
   the tab bar; the palette is the picker.
4. **One search.** The board palette's search and the board's own search already
   share a design (`SEARCH-DESIGN.md`); the unified palette searches the three
   kinds together and sections the results, which is the model that file already
   describes for questions, cards and tags.

## What this does not decide

The hue question above is genuinely open and blocks nothing else; slices 1 to 3
can be built under option (a) and reversed if the owner picks (b).

## Order

1. The crumb grammar and the per-kind indexes, since every other piece addresses
   through them.
2. The palette widened to three kinds, reusing `NAV_ICON` and the existing
   sections.
3. The toolbar demoted from navigator to indicator, with its counts intact.
4. Search across the three kinds.

`#21` is the build task for this; it stays blocked until the owner rules on the
hue question and on the "Your asks" versus `items` naming, because both are
visible in the first slice.

## Ruled, 2026-08-22

**1 · Grouping AND hue.** Owner picked hue-per-kind against a rendered four-way
comparison, then refined it: *"Q1: B + C, as applicable, let's conform but add C
on top of it."* So results are sectioned by kind, which is the charter-conforming
answer and the one that carries the meaning, and the kind's glyph takes a tint on
top as an accelerator. `UI-CHARTER.md` §4 now records it, including why
grouping-first makes this a far cheaper amendment than hue alone would have been.

**2 · The naming question is still open** and is the smaller of the two.

## What needed the owner

1. **Hue per kind, or icon and grouping only?** Recommendation: (a), icon and
   grouping, and revisit if scanning still fails.
2. **"Your asks" or "Items"?** The UI, the CLI verb and the data file disagree
   today, and a unified switcher shows all three names on one line.
   Recommendation: keep "Your asks" in the UI, since §2 asks for the human word,
   and rename the CLI verb to match rather than the reverse.

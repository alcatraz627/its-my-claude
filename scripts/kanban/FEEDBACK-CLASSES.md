# Feedback classes

The owner's review of 2026-08-24, generalised. Each row is a **class**, not the
instance they happened to catch. The instance is listed under it as evidence,
because a class with no example stops being checkable. But the acceptance test
is the class. A session that fixes only the listed instances has failed the row.

Their words, verbatim, and the reason this file exists:

> If it's pending in your plan, then proceed, note these down as feedback to use
> to highlight the class of fixes and improvements and directions to do (I don't
> want to come back to find just these fixed but all adjacent things just as
> messy)

Read this before starting any UI work on this app. Retire a row only when its
sweep has run across every surface named in its **scope**, not when its example
stops reproducing.

---

## C1 · User-facing text uses the machine's nouns

**Class.** Every string a person reads names things the way the owner names
them. A message about an action says what happened and how to get back to it.
Internal nouns (`tab`, `panel`, `entry`, `payload`, `lane` where it means
column) do not appear in toasts, tooltips, empty states, or errors.

**Caught.** `board.html:3976`. Opening a card in the background toasted
`"Added a tab, waiting in the panel"`. Two internal nouns and no way back.

**Scope.** Every `toast(...)`, `placeholder`, `data-tip`, `aria-label`, empty
state and error string in `board.html`, `hub.html`, `drafts.html`, `shared.js`.

**Done when.** A sweep has read every one of them aloud. Owner vocabulary is
fixed in the charter glossary and the sweep cites it.

---

## C2 · Owner feedback parked behind an agent's planning task

**Class.** A concrete ask from the owner never waits on a plan the agent
invented. When an ask has a buildable half and an open design half, they are two
cards. The buildable half ships now. The design half is gated on its own.

**Caught.** `#71` `#72` `#73` `#74` all carry the owner's asks and all sat in
backlog chained `after #70`, a `/plan` card the agent created. Nothing shipped.
The owner's own words were compressed into the card titles, and **zero notes
were captured on any of the five cards**, so the reasoning behind each ask was
lost at filing time.

**Scope.** Every card whose title cites the owner. Every `after` edge whose
parent is a `class: plan` card.

**Done when.** No `after` edge points from an owner-sourced build card to an
agent-authored plan card, and every owner-sourced card carries their words as a
note.

---

## C3 · Floating and ephemeral surfaces are not first-class objects

**Class.** Anything that floats, stacks, or appears beside the board is an
object the owner controls, not a fixed feature of the page. Each one has a
title, a drag handle, a close control, a resize grip, support for **more than
one at a time** where that means anything, and geometry persisted to local
settings so it opens at the size it was left.

**Caught.** The tag sidebar column and the asks column cannot be dragged,
cannot be closed, and cannot be opened more than once. The note editing box
cannot be resized and remembers no size.

**Scope.** Left tag sidebar, asks column, ephemeral tag columns, right drawer,
note popover, composer, search / tag / go-to pickers, doc modal, help modal.

**Done when.** One shared floater primitive carries all six affordances and
every surface above is built from it. A surface that deliberately opts out of
one records why, in the charter.

**Progress 2026-08-24.** The resize half of the primitive exists:
`shared.js:wireGrip` carries pointer capture, arrow keys and an edge argument,
and the three copies that had grown separately (lane columns, right drawer,
left sidebar) all run through it. The left tag sidebar reached drawer parity —
a head that names it, a collapse control, a grip, and a width kept per board,
which is what `#74` asked for. It was a fixed 186px, which is why its labels
read "aug22-kar" and "open not do…"; at any width the owner picks, nothing
truncates.

**The asks column, 2026-08-24.** It was the one column built by hand, so it had
no grip, no fold and no width of its own while every lane beside it had all
three. It runs through the same primitives and the same storage keys now.
Folding it puts a 156-card Active lane fully on screen, which is what the
affordance is for.

Two defects surfaced by exercising it, both older than this change. `setColWidth`
resolved `lane-<id>`, so writing the asks column's width stored a key and then
looked for an element that does not exist. And a remembered width was written
inline, which beat the folded class, so folding a widened lane reclaimed nothing
— the one thing folding is for. Both fixed for every column, and a folded column
now keeps its unfold control lit, because the way back should not be the thing
that hides until hover.

**The left sidebar, designed rather than patched, 2026-08-24.** The owner listed
seven things and they were one thing: it had accreted, never been designed. The
grip could not be grabbed at all — an overflow:auto box clips what reaches past
its padding, so the handle sat 16px inside the edge under the content, and the
earlier round had verified `setSideWidth()` the function instead of dragging it.
The panel is built like the drawer now: a shell that does not scroll, a head
that stays put, a body that does, and the grip on the shell.

Its two heading levels were 11.5px and 10.5px, both weight 600, both uppercase
— one pixel apart, which is no hierarchy. A section is a sentence-case heading
that folds, remembers whether it is folded, and keeps its count while folded;
a kind stays small caps and steps back. Folding Tags reclaims 449px, which is
what put Pinned and Here now 404px below the fold.

A find box narrows both lists and drops sections that no longer have anything
in them. It keeps focus and the caret across the re-render, which the first
attempt did not: only the first character survived.

`window.prompt` is gone from this page. Both callers — renaming a tag and naming
a view — now use the popover the lanes already own, which can show what the tag
is on and what the filter says, neither of which an OS dialog can do. The two
row verbs became one handle, so pointing at a row costs it 20px, never its name.

**Still open, and named rather than implied:** ephemeral tag
columns, the note popover, the composer, the three pickers, the doc modal and
the help modal have none of it. Neither does the drag half for surfaces that
genuinely float, nor "more than one at a time", which only means something for
the ephemeral tag columns. A docked panel's grip is its drag handle; a floating
one needs a real one, and no surface here floats freely yet.

---

## C4 · Structural chrome has no keyboard route

**Class.** Every structural region has a key that opens and closes it. The keys
are consistent across pages, and the help modal lists them. A region reachable
only by a mouse target is unfinished.

**Caught.** Neither the left sidebar nor the right drawer has a toggle key.

**Scope.** Left sidebar, right drawer, help, search, board switcher, drafts
editor panes.

**Done when.** The help modal's Keyboard tab is generated from the same table
the handlers read, so a key cannot exist without being documented.

---

## C5 · A write refreshes only the view that issued it

**Class.** After a write, every view of that data re-renders from the store. No
view keeps a private copy. No view is refreshed by hand at one call site while
its siblings are missed.

**Caught.** Saving a note does not update the sidebar's "your notes" section.

**Scope.** Notes (popover, drawer, sidebar list, hub asks view, card face
count), cards, drafts, selection, plan answers, views.

**Done when.** Writes go through one path that re-renders from the store, and a
test mutates each entity then asserts every surface showing it changed.

---

## C6 · A capability is built on one surface and not offered on its siblings

**Class.** When an editing or display capability exists, every surface of the
same kind offers it. Building it once and wiring it to one caller is the
half-done shape this app keeps producing.

**Caught.** Edit / Live / Preview exists on the drafts editor. The note editor
has none of it.

**Scope.** Markdown preview, undo, autosave, draft recovery, keyboard submit,
paste handling, image rendering, character budget. Across composer, note
popover, note editor, drafts editor, and the ask-answer text field.

**Done when.** The editor core (`editor.js`) owns each capability and every
editing surface opts in, per `EDITOR-LAYERS.md`.

---

## C7 · The navbar is assembled, not designed

**Class.** One navbar component owns its own layout at every width, on every
page, and is genuinely global. Page-specific controls enter through named zones
that the component lays out. They are never bolted on beside it. It sticks on
every page and every view.

**Caught.** Spacing around it wastes vertical room. Breadcrumb, search, and the
Boards / Your asks / Drafts switcher read as three unrelated widgets sharing a
row. It overflows horizontally. It does not stick on Your asks. It is not
actually the same navbar everywhere.

**Scope.** `navbar()` in `shared.js` and its three callers, at 900, 1280, 1600
and 1920 widths, on every view of every page.

**Done when.** One component, one layout algorithm, a documented overflow
behaviour, sticky everywhere, verified at four widths in both themes.

**Progress 2026-08-24.** Of the five things caught, three are closed. It no
longer overflows: the identity wrapper had no styles at all so the zone clipped
rather than shrank, and the find zone painted its overflow on top of the tab
group. It reads less like unrelated widgets: four nested outlines competed on
one row (a capsule around the tabs, one around the page group, a third around
the send group inside that, and the buttons' own), and only the two that are
genuinely one control each remain. The live-sessions badge could grow without
bound and shoved the primary action off the bar, so it is capped with the full
list in its tooltip.

**The overflow behaviour, written down**, because the row asks for it and a
behaviour nobody recorded is one the next session re-invents. The bar measures
what it would need with nothing shed, and if this board's verbs do not fit it
marks itself tight. Tight sheds in a fixed order: the path first, since the
crumb beside it already names the board, then the tab labels, since a glyph and
a count still say which kind you are in while a control that scrolled off says
nothing. What still does not fit slides behind a fade, and the last thing in
the group is the first to slide, so the primary action is never what goes.
Measured rather than tied to a width, because the bar's content varies per
board: a longer name and two live peers is what pushed "Send to agent" off the
edge on `gcp` while `.claude` looked fine.

**Verified 2026-08-24** on `gcp` and `.claude`, at 900, 1280, 1600 and 1920, in
both themes, including the loosen direction (900 then back to 1920 restores the
path and the labels). At 1600 on `.claude`, with five verbs and a selection
live, every labelled verb including the primary is fully visible and only the
board-settings icon slides.

**Sticky on every view: confirmed, not rebuilt.** Measured on `/?view=asks`,
which is the view the row named: `position:sticky`, `top:0`, and the bar holds
at 0 after scrolling 400px. A previous round fixed it; this one checked.

**Vertical room.** 172px of chrome stood above the first card on a 1000px
screen, and 43px of that was the three gaps between the bar, the summary row
and the first lane — more air than the summary row is tall, with the lanes'
own top padding a second helping of it. Now 152px. The row keeps its own
height; only the space around it was spent more carefully.

**The bigger vertical question is the owner's, not this row's.** The summary
band costs about 49px of the scarce axis to say four things, three of which the
lane heads already count. Folding or dropping it is a surface decision and it
needs their word, so it is asked rather than assumed.

**C7 is otherwise swept**: one component, a documented overflow behaviour,
sticky everywhere, verified at four widths on two boards in both themes.

---

## C8 · Raw HTML controls where the design system has a component

**Class.** One control vocabulary. Every select is the custom dropdown, with
search when it has more than a handful of options and a subtitle line when the
option needs explaining. Every button draws its height, padding and radius from
the shared tokens, so two buttons side by side are never different heights.

**Caught.** On drafts, "New Draft" and "From a Template" are different heights
with different spacing, and no dropdown on the page is a proper component.

**Scope.** Every `<select>` and every `<button>` in all three pages.

**Done when.** A grep finds no bare `<select>` on a user-facing surface, and
button geometry comes only from tokens.

---

## C9 · Surfaces ship at different finish levels

**Class.** No page ships less finished than its siblings. Design passes run per
**page**, not per feature, so a surface cannot be skipped because no feature
happened to touch it.

**Caught.** Drafts received no UI attention at all beyond the editor preview,
while the board went through four design-system passes.

**Scope.** Hub (boards), hub (asks), drafts, board, and every modal.

**Done when.** The charter §17 pass has a per-page checklist and drafts has
been through it.

---

## C10 · Approved surfaces that were never carded

**Class.** Anything the owner has agreed to exists as a buildable card with an
owner, or it does not exist. It is never merely implied by a plan document.

**Caught.** Sessions list and history. The three rulings that unblock it landed
on 2026-08-24 (D2a, D3a, D4a, recorded in `CHAT-HISTORY.md`). The only card is
`#14`, which is a `/plan` card, and its note still reads "three owner picks
pending". So the surface the owner has been promised is represented by a
planning card that describes itself as blocked on questions already answered.
A ruled-in surface needs a build card, and a plan card whose gate has cleared
needs its note retired the same day.

**Scope.** Every ruling in `CHAT-HISTORY.md`, `UNIFIED-SURFACES.md`,
`COLUMN-SETTINGS.md`, `FILTER-VIEWS.md`, `ANSWER-PATH.md`.

**Done when.** Each ruled-in surface has a card, and a check walks the rulings
and fails on one that has none.

---

## C11 · A helper built beside the one that already does it

**Class.** Before adding a helper, grep the tree for what it would do. This app
has a shared layer (`shared.js`, `editor.js`, `match.js`) that most sessions do
not read first, so the same job gets a second implementation that then drifts
from the first.

**Caught.** Twice inside the 2026-08-24 session, both nearly shipped. A path
shortener was written next to `tailTrim`, which already trims paths by
measurement and did it better. A size-remembering observer was written next to
the `userSized` observer, which already tracked exactly that and only lacked
persistence. In both cases the right fix was three lines inside the existing
primitive, and the wrong one was a parallel system that would silently disagree
with it later.

**Scope.** Anything added to `board.html`, `hub.html` or `drafts.html` that
could plausibly live in `shared.js` or `editor.js`.

**Done when.** Reflex, not a rule: the grep happens before the helper, and a
new helper in a page file carries a line saying why it is not shared.

---

## How a session works these rows (owner, decision page, 2026-08-25)

Ruled on `kanban-next-direction`: the untouched classes come first, C5 then C6,
then C1, C8 and C9. One class per turn, reported after.

Two rulings shape how, and both widen rather than narrow:

- **Finish all of them, not just the first.** The direction is the order, not the
  scope. A turn ends when its class is swept and validated, and the work ends
  when every direction is done.
- **Validate, and if it is not right, fix it again until it is.** Owner's words:
  "fix additional BUT ALSO VALIDATE AND IF NOT DONE FIX AGAIN UNTIL ALL IS FINE".
  Adjacent scope is welcome, explicitly so: "can be lenient and welcoming in
  letting in extra/adjacent/good-to-do-while-we-are-here (especially) scope".
  This overrides the usual scope ceiling for these sweeps. A defect found beside
  the one you came for gets fixed, not filed.

## How a session uses this file

1. Before touching a surface, read the classes whose **scope** names it.
2. When fixing a caught instance, fix its class across the whole scope, or
   record explicitly which part of the scope is deferred and why.
3. When the owner reports something new, add the class here first, then fix.
   A fix with no class row is how the next instance gets missed.

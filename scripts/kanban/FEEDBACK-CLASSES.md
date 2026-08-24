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

## How a session uses this file

1. Before touching a surface, read the classes whose **scope** names it.
2. When fixing a caught instance, fix its class across the whole scope, or
   record explicitly which part of the scope is deferred and why.
3. When the owner reports something new, add the class here first, then fix.
   A fix with no class row is how the next instance gets missed.

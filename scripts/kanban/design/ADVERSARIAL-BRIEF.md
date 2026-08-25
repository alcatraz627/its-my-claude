# Adversarial review brief: the kanban app, 2026-08-25

Scope: everything declared done on 2026-08-25 at http://localhost:5106.
Do not review by reading. Drive the app like someone who has used it for a
month and is now in a bad mood.

## The claims to prosecute

Each was called done, verified or checked, usually after one screenshot in one
theme at one width.

1. The answered banner v2 on a decision page summarises WHAT was answered.
2. The `.subbar` second bar: no clipping, and the kind tabs keep their labels.
3. Every verb has an icon, a tooltip and a proper word; colour is used only
   where earned. `paintVerbs` fills static markup and a `watchVerbs`
   MutationObserver catches panels that rebuild their own innerHTML.
4. The Decisions section in the board's left panel lists decisions pending
   first, with needs-you / unseen / ruled states.
5. A board whose project directory is gone shows a red "project is gone" pill,
   the path marked `(missing)`, and the command that retires it.
6. A decision page pings `dp-seen` on load, so unseen and undecided stay
   distinct states (charter §12).
7. The doc viewer renders nested lists and blockquotes correctly at a 78ch
   measure.
8. The drafts editor's three pickers are all `searchSelect`; zero native
   selects remain on the page.
9. `data-digits="own"` stops the kind tabs stealing 1-9 on decision pages,
   while digits still navigate everywhere else.
10. Reachability: a pending decision reports whether its asker is still live,
    "hot" inside 30 minutes, and never asserts "live" outright.
11. `/api/owed` and `kanban.sh owed` are one list of what awaits the owner;
    `decide defer` removes an item and the horizon brings it back.

## The session to run, in order, actually clicking

Hub at `/`, all four kind tabs. Then the two boards that differ most:
`/b/-claude-244ec6` (231 cards, dense, a real mess) and
`/b/kanban-showcase-945e63` (39 cards, fresh, six milestones).
Then `/dp/kanban-six-calls/` (answered, has a screenshot and an origin link).
Then `/doc?path=/Users/alcatraz627/.claude/scripts/kanban/docs/REMAINING-WORK.md`.
Then a deliberately dead one: `/doc?path=/tmp/nope.md`.

**HOVER.** Every control with a `data-tip`, and read the tip. Hover a tag chip
and see whether its peers light. Hover a card, a lane head, a kind tab, a
status chip, the crumb, theme and help, the decision rows in the left panel, an
option tile in a gallery. Hunt: a tip that says nothing the label did not, a
stale tip, a control with no tip, a hover state that changes layout rather than
colour, a tip that covers the thing it describes.

**DRAG.** A card between lanes. A card to the lane it is already in. A column
left and right. The left panel's grip, then reload and check the width held for
THAT board. Open all five colcard popovers (lane settings, board settings, tag
ops, name-a-view, view note), drag each by its title, watch the thread tying it
to its opener as it moves, close it, confirm the thread is gone. Start a drag
and press Escape mid-drag. Start a drag and release outside the board. Hunt: a
thread left drawn, a card that snaps back unexplained, a popover dragged
off-screen and unrecoverable, a column order that dies on reload, a drag that
silently does nothing.

**SELECT AND PERSIST.** Shift-click cards and notes. Press `x`. Reload and see
what survived. Set a peek column for a tag, then a second, dismiss one, reload.
Set a lane's soft limit, reload. Set a tag colour, visit another board, come
back. Toggle the theme on every surface. Hunt: state that claims to persist and
does not, state that persists when it should not, a selection that survives
into a context where it is meaningless.

**KEYBOARD.** On a decision page: `j` `k`, digits 1-9, `a` `n` `m` `f` `c` `?`
`Escape` `t`, and `g` then a digit. On the board: `/`, `Escape`, the same
digits. Hunt: a key that does two things, a key the help overlay documents that
does nothing, a digit that navigates when it should pick, an Escape that closes
the wrong layer.

**WIDTH.** Every surface at 1400, 1100, 900 and 700px. Watch what sheds and in
what order. Hunt: a control that vanishes leaving no tooltip behind, a zone at
zero width, two bars where one was promised, a label cut mid-word, horizontal
scroll on the page body.

**EMPTY AND BROKEN STATES.** The empty Inbox lane (the owner ruled 2026-08-25
that it MUST stay visible, because a column that vanishes is indistinguishable
from one that broke). A board with no plans. A board with no decisions. A
decision page with no sections. The dead doc URL. Hunt: an empty state that
reads as a bug, a broken state that reads as empty, a count that says 0 when it
means "could not tell".

## What to hunt, specifically

1. **UI lapses.** Visually wrong, misaligned, clipped, double-rendered,
   wrong-coloured in one theme, or inconsistent between two surfaces that
   should match.
2. **Functionality mismatch.** A control whose behaviour contradicts its label,
   its tooltip, the help overlay, or `scripts/kanban/docs/`. The docs are
   evidence: where the app and `UI-CHARTER.md` disagree, one is wrong and the
   report says which.
3. **Data or elements not staying where they should.** Anything that moves,
   resets, re-orders, duplicates or disappears across a reload, a theme toggle,
   a resize, a board switch or a panel collapse. Especially things made
   idempotent on purpose (`paintVerbs` stacking a second icon, `watchVerbs`
   double-firing) and things scoped per board.
4. **State not called out with enough importance.** The one that matters most.
   A fact the app knows and under-signals: a stale mirror, a gone root, an
   unseen decision, a needs-human card, a cold asker, a deferred item that came
   back. If the app knows something matters and renders it at the same weight
   as something that does not, that is a finding even when nothing is broken.
5. **Hover and drag.** Almost nothing here has been tested. Assume broken until
   driven.

## Ground rules

Drive a real browser. A screenshot read back in both themes beats an assertion.
Every finding names the surface, the exact steps, what was expected, what
happened, and which numbered claim it falsifies. If a claim holds under attack,
say so plainly rather than manufacturing a finding; "held under attack" on a
specific claim is a useful result.

No lectures about accessibility, test coverage or framework choice on a
single-user local tool unless tied to a concrete failure actually produced. Aim
the harshness at what will cost a real minute.

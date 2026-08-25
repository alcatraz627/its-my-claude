# The navbar: five rounds, and why it got worse

2026-08-25. Written by the session that did the damage, for whoever fixes it.
The owner's verdict after the last round was "Navbar is worse, just." Take that
as the finding; everything below is the explanation, not a defence.

## What the owner actually asked for, verbatim

From `UNIFIED-SURFACES.md`, the ask that has never been answered:

> "Make the navbar 'uniform' for all pages, it can have section / page specific
> elements but the core nav + logo icon click for home + other common info
> should still be shown, essentially I shouldn't lose access to common things in
> the navbar across; also improve the visual highlighting and controls in the
> navbar across + **empower it even more for me to use it like a 'power user'
> (define this properly and map to workflows / features / common minimal user
> actions or viewing for maximum customizable context)**"

And across this session, in order:

1. "the navbar esp in the board needs improvement"
2. "the navbar is much less offensive now but it's still far short of what it
   should be in the board. You're not actually examining the whole thing just
   putting out fires"
3. "I'm tired of asking you to improve the navbar, is it happening ever?"
4. The concrete spec: plain buttons with tooltips, background only on important
   ones, colour on some actions, the panel toggle left of the tabs staying put
   and flipping, the rest of the buttons right of the tabs, **remove the second
   row**, status at the right end of the title, click scrolls that column into
   focus.
5. "Navbar is worse, just."

## What was done, round by round

**Round 1, defects.** `save as view` was painting on top of the tab group
because `.nfind` overflowed with no containment; `.nident` had no CSS at all so
the identity zone clipped instead of shrinking; the `⌄` duplicated the `b`
keycap. Fixed by containing the find zone, giving the wrapper `min-width:0`,
deleting the chevron, and moving `save as view` into the page group.

**Round 2, grouping.** Four nested outlines competed on one row (a capsule
around the tabs, one around the page group, a third around the send group
inside it, plus every button's own border). Removed the two redundant capsules.
Bounded the live-peers list, which could grow without limit and had pushed
"Send to agent" off the bar.

**Round 3, overflow.** Built a measured shed order: the bar measures what it
would need un-shed, marks itself tight, and drops the path first, then the tab
labels. Verified at 900/1280/1600/1920 on two boards in both themes.

**Round 4, vertical.** Cut 20px of gaps between the bar, the summary row and
the first column. 172px of chrome above the first card became 152px.

**Round 5, the owner's spec.** Removed the second row and folded its four stat
chips into the bar. Moved the sidebar toggle into the bar, left of the tabs.
Made the page buttons plain, background kept for the primary and for on-states.
152px became 110px.

Every one of those was verified working. The bar still got worse.

## Why it got worse. Four structural reasons

**1. Nobody ever defined what the bar is for.** The owner's ask says "define
this properly and map to workflows / features / common minimal user actions".
That map does not exist. Without it every round was local repair: something was
broken, it got fixed, and no change was ever measured against what the bar is
supposed to let a person DO. Five rounds of correct local fixes do not add up to
a designed surface, and that is the whole story of this file.

**2. The bar was already over-subscribed, and every round added to it.** Round 3
proved it: at 1440 the content needed 167px more than existed. Rounds 3 to 5
then ADDED the status chips and the panel toggle. The shed order made the
overflow graceful rather than absent, and graceful degradation of an
over-subscribed bar still reads as a cramped bar. The honest move at round 3 was
to say "this holds more than a row can hold, what comes out" and put that to the
owner. It was never asked.

**3. Removing the capsules removed the only structure the eye had, and nothing
replaced it.** The nested outlines were genuinely wrong. But they were also the
only thing grouping five zones, and after they went, round 5's plain-button rule
removed the remaining differentiation. The bar is now a long flat row of items
at near-equal visual weight: identity, status, find, tabs, five verbs, three
icons. Two separate correct changes composed into a worse whole. Nothing
measured the composition, because each was verified alone.

**4. The status chips were folded in without re-ranking anything.** The owner
asked for the second row to go, and it went. But the chips arrived into a bar
with no spare room and were simply appended, so they now compete with the tabs
and the actions at the same weight. Removing a row is a subtraction; putting its
contents somewhere is a design decision, and only the subtraction was done.

## What a successor should do instead

Do not start by fixing anything. Start by writing the map the owner asked for
two weeks ago: what does a power user DO on this board, and which of those
actions earns a permanent seat in a row that is 1440px wide. Then decide what
leaves the bar entirely. There are strong candidates: the find control could
live on a key, the status could be one number with the rest on hover, the page
verbs could collapse into one menu, the tabs could shed to glyphs permanently.

Once that map exists, the shed order, the tight state and the grouping become
consequences rather than inventions. Until it exists, another round of local
fixes will land exactly where these five did.

## What is genuinely fixed and should not be re-broken

- Nothing paints outside its zone, and no control is hidden with no way to it.
- `.nident` shrinks (it had no CSS at all, which is why the zone clipped).
- The overflow behaviour is measured rather than tied to a guessed width, and it
  loosens as well as tightens. `shared.js:tighten` explains why it measures the
  un-shed state.
- The live-peers list cannot grow without bound and no longer shows raw uuids.
- The bar is sticky on every page and every view, verified on the asks view.
- Verified at four widths, two boards, both themes.

Those are worth keeping through whatever redesign follows.

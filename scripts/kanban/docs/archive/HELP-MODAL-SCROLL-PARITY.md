# Help modal scroll parity — baseline before the 2026-08-22 hierarchy work

Owner constraint, verbatim: *"the modal title and tab stay as is without any
scroll hiccups (there are none right now, don't cause a mess here)"*.

## Why it holds today, structurally

`.htitle` and `.htabs` are both `flex:none` (board.html:958, :966) and are
SIBLINGS of `.hpane`, which is the only `overflow:auto` element
(board.html:981). The chrome is therefore outside the scroller and cannot move,
rather than being held still by a rule that a later change could break.

**Any sticky-header work happens INSIDE `.hpane`. Nothing moves the title or the
tab strip into a scrolling container.**

## Measured baseline, board `-claude-244ec6`, SHA e1783d3

Each pane scrolled to `scrollHeight`, then the chrome re-measured.

| Tab | pane can scroll | scroll range | title moved | tabs moved | sticky inside pane |
|---|---|---|---|---|---|
| Keyboard | yes | 637px | 0px | 0px | none |
| Taxonomy | yes | 2972px | 0px | 0px | none |
| Vibe Code | yes | 329px | 0px | 0px | none |
| Hey Claude | yes | 552px | 0px | 0px | none |

`document.body` does not scroll vertically (categorical class C3, wrong-scroller).

## The re-run

Repeat the same measurement after any help-modal change. Every `title moved` and
`tabs moved` cell must still read 0, on every tab including any tab added later,
and body must still not scroll. A non-zero cell is the hiccup the owner is
protecting against.

## Re-run 1 — after the table-hierarchy and sticky-reference work, same SHA

| Tab | title moved | tabs moved | band above pinned head | rows bleeding through |
|---|---|---|---|---|
| Keyboard | 0px | 0px | 0px | none |
| Taxonomy | 0px | 0px | 0px | none |
| Vibe Code | 0px | 0px | 0px | none |
| Hey Claude | 0px | 0px | n/a, not pinned by design | n/a |

`document.body` still does not scroll. **Parity holds.**

### What the re-run caught, and it was not the chrome

An intermediate version pinned the reference at `top:18px`, reasoning that the
offset should equal the pane's top padding so the head settles by zero. Measured,
that produced a **36px** band, not 18: the sticky offset stacks on the padding
rather than absorbing it, and two table rows were visible in the gap above the
pinned keyboard. It looked like a clipped row floating under the tabs.

`top:-18px` pins flush and the band measures 0. The cost is an 18px catch-up the
first time you scroll a pane, uniform across all three tabs and invisible unless
measured. The bleed was neither uniform nor invisible, so flush wins.

Recorded because the reasoning was sound and the measurement still disagreed with
it, which is the whole reason this file takes numbers rather than intentions.

## Re-run 2 — after the two-column keyboard, the Hey Claude move, and the Charter tab

| Tab | pane really scrolled | scroll range | title moved | tabs moved |
|---|---|---|---|---|
| Keyboard | yes | 233px (was 637) | 0px | 0px |
| Taxonomy | yes | 2984px | 0px | 0px |
| Vibe Code | yes | 405px | 0px | 0px |
| Hey Claude | yes | 288px (was 552) | 0px | 0px |
| Charter | yes | 7571px | 0px | 0px |

Body still does not scroll. **Parity holds across all five tabs.**

### The check passed once for the wrong reason

An earlier run of this same measurement reported `allZero: true` across every tab
with every scroll range at 0. The modal was CLOSED: the probe called
`helpBtn.click()` on an already-open modal and toggled it shut, so the panes had
no height, nothing could scroll, and nothing could move. A parity check that
reads "nothing moved" on a surface that was never rendered is worse than no
check, because it reports a pass.

**Every run of this check asserts two things before its verdict counts:** the
modal is open, and each pane's `scrollTop` actually advanced. The verdict is
taken only over tabs where both held. That is why the table above carries a
"pane really scrolled" column rather than leaving it implied.

## Re-run 3 — after the untouched-UA-margin fix on term headings

All five tabs genuinely scrolled; title moved 0px and tabs moved 0px on every
one; body still does not scroll. **Parity holds.**

Taxonomy fell from 2984px of scroll to 2704px, because every term heading was
carrying about 18px of browser-default `h4` margin that nobody had set. Recorded
here because a scroll range changing is exactly the kind of side effect this
check exists to notice, and in this case it was the intended one.

## Re-run 2 — after design-system pass 2b (radius ladder), 2026-08-24

`#help .box` went from a 12px corner to `var(--r-panel)` (10px). Nothing else in
the modal changed. All five tabs, each pane scrolled to `scrollHeight`:

| Tab | pane can scroll | scroll range | title moved | tabs moved |
|---|---|---|---|---|
| Keyboard | yes | 263px | 0px | 0px |
| Taxonomy | yes | 2751px | 0px | 0px |
| Vibe Code | yes | 405px | 0px | 0px |
| Hey Claude | yes | 288px | 0px | 0px |
| Charter | yes | 10322px | 0px | 0px |

`document.body` still does not scroll. **Parity holds.** The Charter tab is the
one added since the baseline table, and it is measured here for the first time.

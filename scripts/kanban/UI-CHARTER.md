# The kanban board's UI charter

Every UI ruling the owner has made on this board, in one place, so a later round
inherits them instead of being told again. Two jobs:

1. **Interpretation.** Read it before building any UI change here. When a request
   is short, this is the missing half of it.
2. **QA.** After building, run the capped audit in the last section against what
   changed and what sits next to it.

It grows. A new ruling gets added the same day it is made, with its date, so the
charter is the record and nobody has to re-derive it from a transcript.

The pattern this file is an instance of lives at
`~/.claude/conventions/ui-charter.md`, which says when a project earns a charter
and carries the QA budget below in reusable form.

---

## 1. The disposition

The board is a **reading surface with a workbench attached**. Someone comes to
it to find out where a project stands and to leave something for an agent. Both
have to be possible without ceremony, and neither may block the other.

Three things follow from that, and most of the rules below are consequences:

- **Nothing modal by default.** The board stays usable while you work on one
  card. A backdrop is the exception, never the reflex.
- **Everything shown is a handle.** If a number, a name or a chip is on screen,
  pressing it should do the obvious thing. A count that is only a count is a
  missed affordance.
- **It should be pleasant.** Owner, 2026-08-22: *"I want to make this dashboard
  start feeling fun and helpful to use."* Delight is in scope. It lives in
  motion, in hand-drawn touches, and in the board answering faster than asked.

---

## 2. Language and labels

- **Copy says what happens next, not what the box is.** "Type anything for the
  agent. It gets sorted into a card for you" beats "Notes". Placeholders,
  empty states and tooltips all follow this.
- **Name a thing once and use that name everywhere.** A note is `note #n` on the
  card, in the panel, in the tooltip and in the CLI digest. The number is what
  makes it sayable out loud to an agent.
- **The human voice, not the machine's.** No `Label: fragment` rows in prose, no
  telegraphic field names where a sentence fits.
- **Every kind gets a plain-English label** in the UI even when the code has a
  key. `tier` is "Model tier", `plain` is "Tag".
- **Prefer the shorter true word.** "settled" over "done and stale cards",
  "in motion" over "not yet complete".

## 3. Typography

- **Register follows content, not container.** A quoted card description is body
  weight at a long measure with generous leading. A metadata row is small, mono
  where it is an identifier, and never competes.
- **Identity left, state right.** A row header is `justify-content: space-between`
  with the name group flush left and its status flush right. Never centred.
  (Owner, 2026-08-21, on the note row.)
- **Categorical labels are uppercase, tracked, small and dim.** `.slabel`,
  `.skind` and `.ghead` share one treatment. A category is not a title.
- **A title is a name, not a sentence.** Anything over roughly 100 characters is
  a description in the wrong slot. Summarise it and keep the original as the
  description.

## 4. Colour

- **Colour is spent once per object.** The tag chip is the model: one dot
  carries the kind, the text stays readable text. Do not tint a chip, its
  border, its text and its icon for the same fact.
- **The semantic set is closed.** blue = you and your controls · amber = wants
  attention · red = destructive or risky · green = a related peer, and a passing
  grade · violet = a milestone or a goal · grey = neutral vocabulary.
- **Attention is width and weight before it is hue.** The `active` and `blocked`
  lanes are wider with a heavier border, not tinted. A fourth claimant on a
  closed palette is a bug.
- **Both themes, always.** Every colour is a token. A rule written only inside a
  media query, or only for dark, is incomplete.

**In a list that mixes kinds, the SECTION says which kind, and hue reinforces it.**
Owner ruling 2026-08-22, refined from a rendered four-way comparison: group by
kind, and add the tint on top. Grouping is the charter-conforming half and it
carries the meaning; the hue only makes the scan faster.

- Results in a kind-mixing list are **sectioned under a kind heading**. That is
  the answer to "which kind is this", and it is the answer even in greyscale.
- On top of that, the kind's **glyph** takes a hue: boards blue, asks amber,
  drafts violet. Glyph only, never the text, ground or border, so "colour is
  spent once per object" holds.
- Both apply **only where kinds are mixed**: the unified switcher, global search,
  any index listing more than one kind. Never on a board surface.

**Why this ordering matters more than it looks.** Hue alone was on the table and
was not chosen. It would have made blue, amber and violet each mean two things
with nothing but context to separate them, so a misread hue would have been a
wrong answer. With the section header carrying the meaning, a misread hue costs
nothing: the reader has already been told, and the tint is an accelerator they
can ignore. That is the difference between an amendment that adds a second axis
and one that adds a second *hint*.

The standing question for any later colour decision is therefore narrow: a kind
hue may appear only inside a kind-mixing list, and only where a section heading
already states the kind. A kind hue without its heading is the bug.

## 5. Icons

- **Every action button carries a glyph**, and the tooltip carries the sentence.
  A row of five word-buttons is noise (owner, 2026-08-21, on the asks rail).
- **Drawn, not typed.** Inline SVG at the board's optical weight,
  `currentColor`, 11 to 13px. Emoji and unicode dingbats do not match.
- **One glyph per meaning across the whole board.** The send arrow, the check,
  the note page and the target each appear once in the vocabulary.
- **Icons never replace a label in a primary control.** They accompany it.
- **An icon-only secondary control still has a name.** `aria-label` says what
  it does, `aria-pressed` says its state when it is a toggle, and `data-tip`
  carries the sentence. A tip alone is hover-only, and a control nobody can
  name from the keyboard is not a control (2026-08-23, the hub's 18).

## 6. Spacing and grouping

- **Group, then hold.** Related controls sit inside a holder with its own border
  or ground. Unrelated ones do not merely sit near each other.
- **Consistent gaps within a rank.** Chips 5 to 7px, controls 6 to 7px, groups
  14 to 22px. A one-off gap is a smell.
- **Breathing room around a hover affordance.** An outline or a glow needs the
  space to sit in, or it reads as a collision.
- **Width is free, height is not.** Wide surfaces scroll sideways by design.
  Vertical space is the scarce one.

## 7. Interactivity

- **State is visible at rest. Controls may hide until hover.** An active toggle
  stays lit when nobody is pointing at it. An inactive one may fade in. Never
  the reverse, and touch devices get everything.
- **A click on a control is never a click on its container.** Chips, checkboxes
  and per-item actions all stop propagation. This has been requested twice.
- **Composite states.** hover, focus-visible, active, on and disabled are five
  different appearances. A control with only two of them is unfinished.
- **The primary is blue, the related peer is green.** Hovering something that
  has a counterpart elsewhere lights both. The primary keeps its blue and gains
  a dotted, spaced outline with a soft glow. The peer takes a green,
  outline-free variant of its own hover. (Owner, 2026-08-22.)
- **Middle-click means "do the quiet version".** Open in the background, dismiss
  without confirming, take it off my screen. Destructive uses of it are undoable.
- **Drag means rank.** Where order is meaningful it is draggable, and the order
  persists rather than living in the page.

## 8. Motion

- **Soft, short, around 200ms.** Width and position ease. Colour is quicker.
- **Motion explains a relationship.** A peek slides out of the lane it came
  from. A panel takes its space from the board. Motion that only decorates is cut.
- **Honour `prefers-reduced-motion`** on anything that moves more than a colour.
- **A highlight that must be found gets a double-eased pulse**, not a flash.

## 9. Overlays

One contract, no exceptions:

- Escape closes the topmost, and Escape walks back out one layer at a time.
- Click-away closes anything that is not holding unsaved text.
- Focus moves in on open and **returns to the trigger on close**.
- Body scroll locks while a modal is open, and the last one out unlocks.
- `role="dialog"` and `aria-modal` on anything that traps.
- The z ladder is fixed: popover 30 · palettes 40 · help 50 · doc preview 60 ·
  tooltip 90. The keyboard's idea of "topmost" must match this order.
- **Ephemeral surfaces look ephemeral.** A different ground, a dashed or lighter
  border, and a dismissal you have to mean.

## 10. Keyboard

- **Every surface is reachable without a mouse**, and a keyboard-only session
  can navigate, open, edit, select, act and return.
- **Three layers, resolved in order.** A focused text field owns every key but
  Escape and ⌘↵. An open overlay owns the rest. Otherwise the board and panel.
- **Shifted twins.** If `j`/`k` walks cards, `J`/`K` walks the list inside the
  panel. Related motions share a letter.
- **Every binding appears in the help modal**, grouped by where you are when you
  press it, and a binding with a visible control shows on that control.
- **A shared key map yields to a page that owns one.** `shared.js` binds `t` and
  the view digits on every surface. A page with its own richer map declares it
  with `data-keys="own"` on `<html>`, and the shared handler returns before it
  reads the key. Without that, both handlers fire: `t` toggles twice and lands
  back where it started, and it fires inside the overlays the page's own map
  deliberately swallows, which is the three-layer rule above being broken by a
  handler that never heard of it. Check: remove the attribute and `t` must stop
  working on the board.

## 11. Data and where things live

- **One writer per file.** The CLI owns `board.json`. The server owns
  `notes.json`, `selection.json` and `plan.json`. A surface both sides edit goes
  in a server-owned store, and the CLI asks over HTTP.
- **Anything a human authored survives a re-harvest.** Notes, tags, goals,
  grades, briefs, selections and lane overrides.
- **The agent sees what the human sees.** Every concept added to the UI gets a
  CLI read path and rides along in a sent selection. A channel nothing reads is
  a defect, not a feature. `pins.json` is the standing example.
- **Refuse rather than truncate.** A cap that silently cuts produces garbage. A
  cap that refuses with the fixing sentence produces a better input.
- **A view is a query, never a list of cards.** A named filter stores its
  clauses and resolves them when it is read, so it is still right tomorrow
  without anyone maintaining it. Storing the ids it matched today would make
  the name a lie by the next sync (#39).

## 12. Reporting and honesty in the UI

- **A decision the owner has not opened is shown as unseen, never as
  undecided.** Those are different facts and only one of them is about the
  owner. An ask carries three states, not two: nobody has looked, somebody
  looked and put it off, somebody answered. Collapsing the first two makes the
  board report a choice as pending when it was never actually put in front of
  anyone (#48; vb-fable's constraint 2, which nobody else would have given).

- **Distinguish delivered, nobody-home and broken.** Three outcomes, three
  sentences. Never collapse a failure into a silence.
- **Loud truncation.** A list showing part of itself says how much it hid.
- **Freshness is stated wherever staleness would mislead.** A mirror age, a sync
  warning, an unread marker.

## 13. Standing anti-patterns

Each of these was actually shipped here and corrected. They are the QA list's
first questions.

| Anti-pattern | The correction |
|---|---|
| A native browser affordance where a real one is needed | The `title` attribute never fired for the owner. Build the tooltip. |
| A control hidden behind a mode | The note select box was mode-gated and became unfindable. Show it. |
| Two ways to fire one action | Two "Send to agent" buttons became one. |
| A count that is not pressable | Every stat chip filters to exactly what it counted. |
| A checklist where a shared grouping was meant | Milestones are tags, so "what is left for M2" is a filter. |
| A cap that spends its budget in filename order | The harvest starved the only files carrying cards and emptied a board. |
| A second progress or chip idiom | Reuse `progRing`, `.chip`, `wireReorder`, the palette shell. |
| An unsaved-text surface sharing a slot with saved ones | The draft canvas is its own durable row. |
| Colour used to mean two things | One dot, one meaning. |
| A guard made of necessary-but-insufficient conditions | Length and membership both passed while the set was wrong, and a note was deleted. A guard over a permutation asserts a bijection. |
| A delegated list testing the container before the thing inside it | A note chip lives inside a card, so while the card's rule ran first the chip could never win its own pair. Specific before container. |
| A timed effect wearing a live state's class | The tab-open flash borrowed the peer class, so clearing the pair could not clear the flash. A temporary effect gets its own name. |
| A measurement taken from something the measured thing changes | The composer's height cap was a share of the box above it, which shrinks as the composer grows, so the cap chased itself. Measure against something the change cannot move. |
| A second list of what the first list already says | The keyboard map is built by reading the shortcut table, so a binding cannot be on the keyboard and missing from the docs. |
| `e.target.matches` unguarded in a document-level handler | A keydown targeting the document has no `matches`, and the throw took the whole handler with it. Optional-call it. |

---

## 14. The QA round (capped, on purpose)

Run after building, before reporting. **It is bounded by counts, not by
exhaustiveness.** The exhaustive pass is saved for final validation.

**Scope:** what changed, plus what sits directly beside it on screen.

**The budget, per round:**

- **10** changed elements inspected against §2 to §8.
- **6** adjacent elements checked for consistency drift.
- **5** overlay-contract checks, only if an overlay was touched (§9).
- **4** keyboard paths walked end to end (§10).
- **2** themes. Both, always. Not negotiable, and not counted against the above.
- **1** honest sentence naming anything skipped and why.

**How to run it.** By default the same agent that built it, in one pass, in the
browser. A subagent is warranted only when the change spans more than three
surfaces, and then it is **one** subagent carrying this file and the diff, never
a fleet.

**The output** is a short list of violations, each with the rule number it
breaks, then the fixes applied. A round that finds nothing says so in one line
and does not pad. Do not spiral. Log a borderline case as a charter question for
the owner instead of relitigating it.

---

## 15. Review, 2026-08-22

Written after the round that built the peek column, the palettes, search, the
nudge, the notepad composer, the drawn keyboard, the playground and the hub.
This is the back-propagation the owner asked for: what the charter got right,
what it was missing, and what it now says because of it.

**What held.** Three rules did real work rather than sitting there. "Everything
shown is a handle" produced the pressable stat chips, the tag chips that open a
peek and the search results that become a selection; each time the question was
already answered before it was asked. "Colour is spent once per object" survived
six new surfaces without the palette gaining a hue, because the tag dot pattern
generalised to the peek column, the pair highlight and the composer status.
"One writer per file" decided where tags and goals live in about a minute, and
that decision has not been revisited since.

**What was missing, and is now in.** Six of the seven new anti-patterns above
came from this round, and five of them are the same shape: a rule that was
correct about the common case and silent about the edge. The charter said
controls stop propagation; it did not say that a *delegated* list has to test
the inner thing first, and the note chip bug followed. It said motion is short
and explains a relationship; it did not say a timed effect must not borrow a
live state's class name. It said measure, not guess; it did not say the
measurement must be taken from something your change cannot move.

**The pattern under the pattern.** Every one of those is a guard or a rule that
was *necessary and not sufficient*, and none of them failed loudly. The reorder
bug returned `ok:true` while deleting a note. The pair bug lit the wrong element
and looked deliberate. The height cap silently never bound. That is the class of
defect the capped QA round is actually for, so §14's budget is unchanged but its
framing is now explicit: the checks are chosen to make a silent wrong answer
loud, not to enumerate the surface.

**What the QA round cost, measured.** Ten changed elements, six adjacent, five
overlay checks, four keyboard paths, two themes, once per surface. It caught the
double-owned subtitle, the blank title icon, the always-true row wearing the
dimmed style and the toolbar overflow. It did not catch the reorder blocker; the
adversarial seat did. Both are worth their cost and neither replaces the other:
the round catches drift, the seat catches wrongness.

**One thing to watch.** The board now has seven declared pairs, four palettes
sharing one shell, and three surfaces that render from a single vocabulary. That
consolidation is the reason this round moved quickly, and it is also the reason
a mistake in a shared primitive now shows up in seven places at once. The next
round should treat any edit to `.chip`, the palette shell, `PAIRS` or the
overlay contract as touching every surface that uses them, and QA accordingly.

## 16. Review, 2026-08-22, cross-page

The first review covered the board. This one covers everything else, and its
finding is different in kind: the board was internally consistent and the
*system* was not.

**What the audit found.** Four surfaces each declared their own tokens, buttons,
tooltip and header. They agreed because someone had kept them agreeing by hand,
and the doc viewer had already stopped: a fourth palette in raw hex that no
token could reach, so a theme change could never touch it. Navigation was a
partial graph, and the sharpest instance was that the drafts page offered two
links and no route to Asks at all. Board stars existed only inside the board's
own picker, so the one page listing every board could neither show nor set one.

**What that changes in the charter.** §4's "every colour is a token" needed a
companion: *the tokens live in one file that every surface links*. A rule that
each page must use tokens is satisfiable by four private copies, which is
exactly what happened. Same for §5, §7 and §13: a shared primitive is the only
enforceable form of a shared standard.

**The measurable part.** The review swept for native `title=` tooltips, which
§13 bans, and found them still on three surfaces after all the earlier rounds:
sixteen on the board, two on drafts. They survived because each round checked
the thing it had just built. A sweep that asks one question of every surface
finds what a per-surface review cannot, and it is cheap: one selector.

**Standing count.** Zero native tooltips and 608 owned ones across the board,
the panel, all four help tabs and the peek column, in both themes. Re-measured
2026-08-23 across all three pages, both spellings (`title="` and `.title =`):
zero, after four property-set ones were found on the hub. The one `title=` on
the doc-modal iframe is its accessible name, not a tooltip, and is exempt.
`test-charter.sh` now takes this measurement every run.

## 17. The thorough review (next round's instrument)

§14's round is capped on purpose and catches drift. It does not catch what the
owner is asking for next: *"extend the review to more specific items and things
... a much more thorough review."* That is a different instrument, and mixing
the two is how the capped round quietly turns into an uncapped one.

**When to run it.** Once a surface is built and its capped rounds keep coming
back clean. Not per change. Expect it to be its own session.

**How it differs.** The capped round asks a few questions of what just changed.
The thorough review asks every question of one surface at a time, and its unit
is the individual element rather than the screen.

**The pass list, per surface.** Each pass is a sweep across every instance, not
a sample:

1. **Every control**, one at a time: its five states, its target size, its
   label, its glyph, its tooltip, its keyboard route, and what happens on a
   double press.
2. **Every piece of copy**, read aloud: does it say what happens next, is it in
   the human voice, does it match the vocabulary the rest of the board uses.
3. **Every empty, loading, error and one-item state.** These are where a board
   that looks finished stops being finished, and none of them appear in a
   screenshot of a populated board.
4. **Every number on screen**, traced to what it counts and whether pressing it
   shows exactly that set.
5. **Every boundary**: the longest title, the emoji, the 200-card lane, the
   card with no notes, the note with no text, the tag on nothing.
6. **Every route between two surfaces**, walked in both directions.
7. **Both themes at three widths**, with the panel open and closed.

**What it produces.** A numbered finding list with a disposition on each, and
new charter rules for whatever it found that the charter did not already say.
A thorough review that adds no rules either found nothing, which is worth
stating plainly, or was not thorough.

**What it must not become.** An excuse to rebuild. A finding is a defect or a
named deferral, never a redesign, unless the owner rules otherwise.

## 18. Space, and what a surface owes its own chrome

Two rulings from 2026-08-22, both from the owner, both earned on the help modal.

**Use the space you have before you ask for more.** Owner, verbatim: *"The
guideline of maximising space utilization without asking for more if the existing
is sufficient for what we need to show."* Height is the scarce axis (§6), so a
long single column that scrolls past its own reference is a failure to use the
width that was already paid for. Two worked cases, both measured: the keyboard's
31 shortcut rows went to two columns and its scroll fell from 637px to 233px; the
note-tags reference moved under the example card into a column that was already
330px short, and Hey Claude's scroll fell from 552px to 288px.

The corollary bites when you reach for a grid. A grid's second row begins below
the TALLEST cell of the first, so a table placed there clears the taller column
instead of filling the gap beside it. The first attempt at the note-tags move did
exactly that and ADDED 87px. Filling a column's empty space means being inside
that column's flow, not in a later row.

**A pinned reference pins flush, or it leaks.** Where a pane's top section is a
reference the rows keep pointing at, it sticks and the rows move under it. The
offset must be negative by the scroller's own top padding: a positive offset
leaves that padding as a gap the pinned element cannot fill, and rows scroll
through it, which reads as a clipped row floating above the reference. Measured:
`top:18px` against an 18px pane padding produced a 36px band with two rows
visible in it, where `top:-18px` produced none.

Not every pane earns one. The three that do open with something you consult while
reading (a drawn keyboard, a pipeline map); the one that does not opens with a
playground you use rather than consult, and pinning it would eat the pane.

**The chrome above the scroller is not part of this.** The modal's title bar and
tab strip are `flex:none` siblings of the single scrolling pane, so they are
structurally incapable of moving. Owner, verbatim: *"the modal title and tab stay
as is without any scroll hiccups (there are none right now, don't cause a mess
here)."* Any change inside a pane re-runs the check in
`HELP-MODAL-SCROLL-PARITY.md`, and every tab must still measure 0. That file also
carries the shape of a parity check that passes for the wrong reason: an early
run reported all-zero movement on a modal that was closed, because a toggle had
shut it. A parity check needs a positive assertion that the thing it measures
actually happened.

---

## 18b. No zone may reach zero

A layout zone that can be squeezed out of existence is a control the owner
loses without being told. On 2026-08-24 a board whose path is 842px wide pushed
the navbar identity zone to 985px and took the find zone, search box included,
to exactly zero width. Nothing errored; the control was simply not there, and
only long-path boards showed it.

So: **every zone that holds a control declares a floor** (`min-width`), and the
zone that holds what you are looking AT is the one that shrinks. A label may
ellipsise. A thing you type into may not vanish. Check: render the widest real
input you have, not the tidy one, and assert every zone is above its floor.

---

## 19. Changelog

- **2026-08-24, one navbar (#68).** Every page wears `navbar()` from
  `shared.js`: identity left, find in the middle, everything common plus the
  page's own group on the right, that group in its own bordered pill so the eye
  separates "here" from "everywhere". The board had no page tabs and the hub
  and drafts had no logo-home; both are common now, which is what "I shouldn't
  lose access to common things in the navbar across" asked for. The active tab
  carries its kind's hue as a 2px rule under the label (§4). One rule learned
  the hard way and worth keeping: **`navbar()` ADDS its class, never replaces
  the mount's**, because the board styles `.brow .crumb` and replacing the
  class silently drops the crumb. Adding `HELP_ICON` to `shared.js` also
  collided with the board's own and killed the page with a SyntaxError until
  the board's copy went; a new global in a shared file gets grepped against
  every consumer first, which is pass 1's lesson arriving from the other
  direction.

- **2026-08-24, design system pass 1 (#61).** `board.html` links `shared.css`
  and `shared.js` and no longer carries its own copies: the token block
  (diffed byte-for-byte against `shared.css` before anything was deleted), the
  tooltip layer, the icon set, `applyTheme`, `toggleTheme`, `ago`, `tailTrim`,
  and seven local `prefers-reduced-motion` rules the shared global rule already
  covers with `!important`. 127 lines left the file; four suites stayed at
  2/27/9/68 and the two themes diffed with no layout shift and no palette
  change. Two things had to be built rather than deleted: the `data-keys="own"`
  rule in §10, and an explicit top margin on `.term p` and `.hplay .pane-l p`,
  because `shared.css` resets `*{margin:0}` and both had been living on the UA
  default. **G13's check was wrong in both directions** — a bare filename grep
  is satisfied by a comment that names the files, so it passed before the work
  (2, matching the copy note) and failed after the work was correct (3). It is
  pinned to the attribute form now. The lesson is the one this board already
  learned twice on 2026-08-23: a guard that agrees with itself is not a guard.

- **2026-08-23, the design system.** `DESIGN-SYSTEM.md` is now the book for
  what the parts are: the neutral and semantic ladders, lane and tag hues, a
  seven-step type scale, a five-step radius ladder, one focus ring, two
  motion durations, a named z ladder, the button variants and composites
  (group, segmented, toggle, split), chips versus pills, surfaces, bars. Its
  §10 lists eighteen measured drifts with fix and check; §17 reads §§2–8 of
  it as the rubric. Two tag kinds added, `priority` and `class`, and a card's
  execution order (`after`). This charter stays the rules; the book is the
  parts.
- **2026-08-23, eighth round.** The hub audited for the §5 and §16 contract at
  last (#46): four native tooltips set as `.title =` properties, which the
  attribute grep behind §16's count could not see, and every star and archive
  button unnamed (no `aria-label`, 18 on the page; #55), as was the drafts
  recipient combobox. All converted or named; `aria-pressed` added to the two
  toggles. **An icon-only control carries a name, not only a tip** is now the
  reading of §5 for secondary controls too. The §16 count is re-measured by
  `test-charter.sh` rather than carried. Same day: `show --json` carries the
  card's goal and tags (#49), and drop forgets them (#43).
  Eleven typed chrome glyphs on the board drawn (#45, the count had been
  carried as eight). The drafts status strip ellipsizes the pull note so the
  save state stays on screen (#47). §14 round on the batch: nothing found;
  four keyboard paths, two overlays, both themes on hub and board. Skipped:
  the drafts strip was read in light only.
- **2026-08-22, seventh round.** The §16 standing count was WRONG and a peer
  found it. It read "zero native tooltips and 608 owned ones across the board";
  `board.html` carried four banned `title=` attributes, two of them on the
  verify and needs-you pills, which is the decision path itself. §13 bans the
  pattern precisely because "the `title` attribute never fired for the owner",
  so the options text on a decision card was being delivered by the mechanism
  this charter says does not reach them. Converted to `data-tip`; one `title`
  remains and is legitimate (an iframe label). Reported by vb-fable, 2026-08-22.
  **A standing count is a measurement with a date, not a property.** This one
  was taken after a sweep, written as though it would stay true, and was carried
  forward twice in checkpoints without being re-run. Any count in this file is
  re-measured before it is repeated.
- **2026-08-22, sixth round.** §4 AMENDED: in a kind-mixing list, a section
  heading states the kind and the kind's glyph takes a hue on top (boards blue,
  asks amber, drafts violet). Owner ruled against a rendered four-way comparison,
  first picking hue alone and then refining to grouping-plus-hue, which keeps the
  meaning in the heading and leaves the tint as an accelerator. §17
  of the drafts editor direction settled the same way: caret-line reveal ships as
  a THIRD mode beside Edit and Preview rather than replacing the toggle, the
  owner's reason being that a third surface helps when something is wrong.
- **2026-08-22, fifth round.** §18 added: the space rule and the pinned-reference
  rule, both from the owner. The help modal gained one table treatment for every
  tab (it had carried two), a Charter tab that renders UI-CHARTER.md rather than
  restating it, and Escape-only dismissal. `renderMd` gained lazy continuation,
  without which every hard-wrapped list in every doc rendered as a run of
  one-item lists.
- **2026-08-21.** Founding set, distilled from the column-width, title-brief,
  panel, notes, selection, status-band, tag and modal-sweep rounds.
- **2026-08-22.** Added the §7 peer-highlight rule (blue primary, green peer,
  dotted spaced outline, soft glow), the middle-click convention, and the
  "should be fun" clause in §1.
- **2026-08-22, fourth round.** §17 added: the thorough per-element review, as
  the instrument for the next session's deeper pass. §14's capped round is
  explicitly NOT that, and the two are now named separately.
- **2026-08-22, third round.** shared.css and shared.js, the three-view nav on
  every page, hub stars and glyphs, the doc viewer on the standard. §16 reviews it.
- **2026-08-22, second round.** Three rulings earned while building under it.
  A binding shows on its control, not only in help (§10). A palette is one
  component with sections, reused rather than re-hand-rolled per use (§13). A
  temporary surface carries a dashed border and a tinted ground, and is
  dismissed rather than dropped by the next click (§9), which is the peek
  column. Search has its own contract in SEARCH-DESIGN.md and that document is
  its acceptance list.

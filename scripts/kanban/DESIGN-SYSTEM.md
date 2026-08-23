# The kanban design system

The charter (`UI-CHARTER.md`) says what a surface owes the owner. This book says
what the parts ARE: the tokens, the ladders, the components and their variants,
the composites, and the one way each interaction looks. Where the two disagree
the charter wins, and the disagreement is a bug here. Written 2026-08-23 from
measurement of the four files (`shared.css`, `board.html`, `hub.html`,
`drafts.html`), not from memory; every number below was counted with `rg`
that day. §10 is the list of drift the measurement found, each with its fix
and its check, and is the work queue for the next agent.

One sentence on character, since it is the thing to protect: this app is
colourful on purpose. Six lane hues, eight tag hues, tinted chips, a violet
drawer tint, amber attention. Standardising here means one ladder per thing,
never fewer things. The office kit this borrows three principles from is
deliberately plainer; nothing of its look comes across.

## 1 · Foundations

### 1.1 Theme

Two themes, `dark` (default) and `light`, switched by `data-theme` on `<html>`
and `t` / the theme button. Every colour is a token; no component names a hex.
Light is not dark inverted: the lane hues and the four semantic inks are
re-picked for contrast on white (`shared.css:39`), and the tinted backgrounds
keep their alpha so they sit on either ground.

### 1.2 The neutral ladder (four grounds, two lines, three inks)

| token | dark | light | is |
|---|---|---|---|
| `--canvas` | #131417 | #e9ebef | the page |
| `--well` | #191b1f | #f4f5f8 | a sunk area inside a surface: sidebar, input, code |
| `--card` | #212329 | #ffffff | a raised surface: card, button, popover, modal |
| `--card-hover` | #282b32 | #f7f8fa | the same surface under the pointer |
| `--border` | #2f333b | | the line between surfaces |
| `--border-2` | #414651 | | the line when hovered or emphasised |
| `--text` / `--text-2` / `--text-3` | #e9ebee / #a4a9b1 / #8c939d | | primary, secondary, tertiary ink |

Rule: a surface is one step up from what it sits on. Canvas → card, card →
popover (card + shadow), well inside card. Never two steps (no card on card
without a border), never a surface on itself.

### 1.3 The semantic ladder (four meanings, three shades each)

`--blue` (action, selection, links), `--amber` (attention: needs you, stale,
unsaved), `--green` (verified, saved, done), `--red` (destructive, error). Each
has exactly three shades: the **ink** (`--blue`), the **tint** (`--blue-bg`,
ink at 12% alpha), and the **line** (`--blue-br`, ink at 30–34%). A tinted
control is ink text on tint background with line border. That triple is the
shade ladder; there is no fourth shade and no solid variant except the accent
button (ink background, `--on-accent` text).

Colour is semantics, not taste (borrowed principle): blue means you can act,
amber means look, green means done, red means it cannot be undone. A hue on a
control that does not carry one of those meanings is a tag hue (§1.5), never a
semantic one.

### 1.4 Lane hues

`--l0` … `--l5`, six hues from teal through cyan, blue-violet, violet, to
pink, assigned to a card's source heading (`labelHue`) and shown as the card's
left stripe and label swatch. They mean "which part of the source doc", not
status, and never appear on a control.

### 1.5 Tag hues (the kind dots)

| kind | token | ink only? |
|---|---|---|
| milestone | `--violet` | yes |
| priority | `--pink` | yes (new 2026-08-23) |
| class | `--teal` | yes (new 2026-08-23) |
| tier | `--blue` | full ladder |
| effort | `--amber` | full ladder |
| area | `--green` | full ladder |
| risk | `--red` | full ladder |
| plain | `--grey` | yes |

A tag chip shows its kind as a dot in that hue and stays neutral otherwise;
the hue reinforces, the `kind:` word carries the meaning (charter §4, the Q1
ruling). Gap G11: the four ink-only hues cannot render a tinted "on" state the
way the four semantic ones can.

### 1.6 The rest of the tokens

`--ring` (focus, = blue) · `--scrim` (one overlay dark, 38%) · `--shadow`
(`0 1px 2px` at 40%, the only resting shadow) · `--on-accent` (text on a solid
accent) · `--sans` (SF Pro / Segoe / system) · `--mono` (SF Mono / JetBrains).

## 2 · Typography

Two faces: `--sans` for everything the owner reads, `--mono` for paths, ids,
tag names, keyboard keys and source lines. Weights 400, 500 (rare), 600 for
labels and emphasis; 700 never.

Measured scale today: 14 distinct sizes on the board (9 to 19 px, most of them
within half a pixel of a neighbour). The ladder, seven steps, which the
measured sizes round onto:

| step | px | used for |
|---|---|---|
| micro | 9 | keycap legends, count badges inside chips |
| caption | 10.5 | caps labels (TAGS, MILESTONE), foot text |
| small | 11.5 | chips, pills, tips, status strip, table rows |
| body | 12.5 | card titles, notes, hub rows, help prose |
| lead | 13.5 | section heads (h4), lane names, drawer labels |
| title | 15.5 | page sub-heads, draft title input |
| display | 19 | page h1, drawer card title |

Caps labels: 10.5 px, 600, `letter-spacing: .06em`, `--text-3`. Line height
1.3 for titles, 1.5 for rows, 1.6 for prose. Charter §3 already rules on
truncation (title then source, never the age) and this ladder does not move it.

## 3 · Shape

### 3.1 Radius ladder (five steps)

| px | on |
|---|---|
| 4 | inner elements: keycaps, swatches, code spans |
| 6 | controls: buttons, inputs, selects, chips' inner |
| 8 | cards, notice bars, the writing surface |
| 10 | panels: popovers, the lane popover, hub rows |
| 20 / 99 | fully round: pills, dots, the count badge |

A sixth step, `--r-hair: 2px`, was added when the ladder met the code: three
decorations are under 3px wide (`.notice .bar`, `.colgrip::after`,
`.kcap.bound::after`), and at that width a 4px radius reads as a lozenge, not a
softened corner. Added as a step rather than distorting them, which is the
owner's rule about the stores applied to this book.

Measured today: 15 values on the board (2, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11,
12, 14, 20, 99). Gap G2.

### 3.2 Borders

`1px solid var(--border)` everywhere a surface meets a surface; `--border-2`
on hover or emphasis. Two exceptions, both meaningful: 1.5 px for the
selection box around a selected card, 3 px for the lane stripe. Dashed once,
for the drop target. Nothing else.

### 3.3 Focus

One recipe: `outline: 2px solid var(--ring); outline-offset: 1px` for every
focusable thing. The three glow recipes in use (`0 0 0 3px` at 18%, `5px` at
9%, `6px` at 16%) are G4; a glow is allowed only on the writing surface and it
is `0 0 0 3px` at 12%.

## 4 · Motion

Two durations: `.12s` for colour and opacity on hover and state, `.22s` with
`cubic-bezier(.32,.72,0,1)` for anything that moves (drawer, panel width,
sidebar). Nothing else (measured: .1, .11, .12, .14, .15, .16, .22; G5). The
`prefers-reduced-motion` rule lives once in `shared.css:124` and covers all;
the board's eight local copies go when it links the shared sheet (G9). Three
named effects exist and stay: `fx-save` (the composer's save pulse), `fx-open`
/ `fx-back` (drawer), `.found` (search landing outline).

## 5 · Elevation and layering

Resting: `--shadow`. Floating (popover, picker, tooltip, modal):
`0 12px 34px rgb(0 0 0/.34)` (`shared.css`), plus `--scrim` behind anything
modal. The z ladder, named so nobody picks a number:

| layer | z | what |
|---|---|---|
| base | 1–3 | stripes, new-dots, sticky lane heads |
| rail | 25–35 | sidebar, summary band, the stale bar |
| drawer | 40 | the open-cards panel |
| popover | 50 | lane options, the note popover |
| picker | 60 | search, tag, go-to |
| modal | 90 | help, doc viewer, toast, tooltip |

**This table is a proposal, not a measurement, and it does not survive contact.**
The stack actually in the code is `.dgrip` 3, `.colgrip` 2, `#toast` 3,
`#xarrow` 25, `#pop` 30, `.colcard` 35, the pickers 40, `#help` 50, `#docmodal`
60, `#tip` 90. Collapsing help, doc, toast and tooltip onto one number ties four
overlays and would reverse help and doc by source order. So pass 2 named the
measured stack (`--z-base` … `--z-tip` in `shared.css`) and moved nothing. The
restack is G20.

## 6 · Icons and dots

Drawn SVG, `currentColor`, no fill unless the glyph is a filled state (the
star when on). Three sizes: 11 (inside a pill), 12 (inside a chip or the
check), 13 (a button or a head). Stroke 1.2 for outlines, 1.4 for strokes
that must read at 11 px, caps and joins round. One glyph per meaning across
the app (charter §5). The registry is `NAV_ICON` / `MARK_ICON` / `THEME_ICON`
in `shared.js` and the board's own set (`NOTE_ICON` … `X_ICON` …
`THEME_ICON_B`, `SEQ_ICON`), which is a known copy until the board links
`shared.js` (G13); at that point one set, one file. A dot (`.tdot`, `.sw`) is
an 8 px circle in a hue and means "kind" or "source group", never status.

## 7 · Components

Each one: the base, the variants, the states, and what it combines with.
"State" always means hover · focus-visible · on/pressed · disabled.

### 7.1 Button

Base: `--card` ground, `--border` line, `--text-2` ink, radius 6, 28 px tall
(`.primary` is 30; G6), padding 5 × 10, `font: 600 12.5px`. Hover: one step
up (`--card-hover`, `--border-2`, `--text`).

| variant | class | look | use |
|---|---|---|---|
| solid | `.accent` (and the board's `.primary`, G6) | blue ground, `--on-accent` ink | the one forward action on a surface: Save, Add, Answer |
| outline | (base) | card ground, border | most actions |
| ghost | `.ghost` | no ground, no border, `--text-3` | chrome: theme, help, close |
| danger | `.danger` | outline with red ink; solid red only in a confirm | delete |
| link | `<a>` | underline on hover | navigation, never an action |

Sizes: default, `.icon` (square, padding 5 × 8, glyph only, MUST have
`aria-label` and `data-tip`), `.ico` (30 × 30 grid, the hub's). Two names for
one idea is G7; `.icon` stays.

Anatomy, in order: before-icon (13 px) · label · after-hint (a keycap `.k`, or
a chevron for a menu). Never an after-icon that is not one of those two.

States: `.on` = pressed toggle (tint ground, line, ink); `[disabled]` = 45%
opacity and `not-allowed`, BUT a control that cannot act is hidden or explains
itself in its tip, never silently greyed (borrowed principle, G15).

Composites:
- **Group** (`.tgrp`): buttons that share a purpose sit in one bordered pill
  with a 1 px divider, no gap (top bar: find · pick · act · view).
- **Segmented** (`.modes`, the rail's All · Here · Any board): one control,
  one `.on` segment, radio semantics, arrow keys move.
- **Toggle**: ONE button whose label, icon and `aria-pressed` flip together
  (star / unstar, archive / restore). Never two buttons for one state.
- **Split / menu button** (new; needed by the board-settings dropdown and
  the Offer action): label + a chevron segment; the chevron opens a popover
  (§7.6) anchored bottom-start; `aria-haspopup="menu"`, `aria-expanded`.
  There is none today (G12); define once, use for both.
- **Destructive escalation** in a bar reads outline → ghost → ghost+red.

### 7.2 Input, select, textarea

Well ground (`--well`), border, radius 6, same height as a button so a row of
controls is one height (the #37 measurement). Focus: the one ring. The
writing surface (drafts, composer) is the exception: raised to `--card` so
the thing you touch is the thing that stands out (the #9 finding), radius 8,
the only glow. Placeholder voice: a sentence that says what to type and where
it goes ("Leave a note. The agent reads it on its next pickup…"), never a
label repeated.

### 7.3 Chip

A pressable word. 22 px, radius 20, `--well` ground, border, small type.
Families, all one shape:

| family | class | carries | press does |
|---|---|---|---|
| tag | `.chip.tag.k-<kind>` | dot + `kind: name` | filters every card with it |
| state | `.stat-chip` | glyph + `N word` | filters to the counted cards |
| seed | `.spchip` | a query word | fills the search |
| insert | `.inserts button` | a note tag | inserts at the cursor |
| drawer | `.dchip` | a count | same as state |

States: hover one step up; `.on` = blue tint/line/ink (state chips) or the
kind's hue (tag chips, G11 for the four ink-only kinds); `.warn` = amber.
A chip is always a `<button>`; a span that looks like a chip is a pill.

### 7.4 Pill

A read-only word. Same height family as a chip (18–22), radius 20, no
hover. `.pill.verify` (green when executed, soft otherwise), `.needs` (amber,
600), `.seq` (after N, grey), `.prog` (ring + n/N), `.label` (source group,
lane hue swatch), `.mono.xtag` (the source's own tag, verbatim), `.why`
(stale reason, tip only). Every pill with a glyph carries a `data-tip` that
says what it means in a sentence.

### 7.5 Card and row

The lane card: stripe (lane hue) · new-dot · select box · title (2 lines,
then ellipsis) · the note line when it asks something · chips · pills · foot
(source, awaiting-pickup, age). Hover one step up; selected = 1.5 px blue
box; `.changed` = new-dot; blocked = red-tinted stripe. The hub board row and
the draft row are the same recipe at 10 px radius with the title as the link.
A card never holds a button except the select box; actions live in the
drawer.

### 7.6 Surfaces and overlays

| surface | ground | border | shadow | radius | dismiss |
|---|---|---|---|---|---|
| sidebar / rail | `--well` | right line | none | 0 | `\|` |
| drawer | `--card` + violet tint band | left line | none | 0 | `\` / Esc |
| popover (lane, note) | `--card` | border | floating | 10 | Esc, outside |
| picker (`.bpbox`) | `--card` | border | floating + scrim | 10 | Esc |
| modal (help, doc) | `--card` | border | floating + scrim | 12 | Esc only |
| notice bar | amber tint | amber line | none | 8 | never; it is a fact |
| toast | `--card` | border | floating | 8 | 3 s |
| tooltip | `--card` | border | floating | 6 | pointer leaves |

One scrim, one floating shadow, Esc steps out one layer (charter §10).

### 7.7 Toolbars and bars

- **Top bar**: crumb · switcher · path · live peers · groups (find · pick ·
  act · view). The right-most control declares itself (borrowed: never a bare
  outline with no icon as the page's right action).
- **Summary band**: state chips, pressable, counts that filter.
- **Lane head**: ring glyph · name · count badge · lane options (ghost icon).
- **Drawer head**: lane pill · prev/next · collapse · close, all ghost icons.
- **Composer bar** (`.cbar`): insert chips left, primary Save with keycap right.
- **Status strip** (drafts): facts left (words, pulled, note ellipsised),
  save state right, one line.
- **Command bar**: the search picker is the app's command bar; a verb typed
  there should do what the chips do (G17 lists the gap).

### 7.8 Dashboards (this is not a number-heavy app)

The hub is the only dashboard. Its numbers are small and sentence-shaped
("148 in motion, 1 of them blocked"), each a pill with a tip saying what the
count means. Keep it that way: no stat tiles, no charts, no sparklines.
A number on this app is a count you can press to see the things counted.

## 8 · Interaction vocabulary

- **Hover** = one step up the neutral ladder, `.12s`. Three recipes only:
  quiet (ghost → well ground), raised (card → card-hover, border-2), accent
  (solid → brightness 1.08). Measured today: eight (G8).
- **Pressed / on** = the control's own tint ladder.
- **Focus** = the one ring, always visible on keyboard, never on pointer.
- **Tooltip** = `data-tip`, 260 ms, below by default, above near the edge;
  the full sentence; never a native `title`.
- **Keyboard** = every action has a key and the key is in its tip in
  parentheses (charter §10); Esc steps out one layer.
- **Drag** = cards, with ⌘ to pan; the drop target is the one dashed border.
- **Middle click** = toggle selection without focus (the #35 contract).

## 9 · Standard combinations

| need | the combination |
|---|---|
| an icon-only control | `.icon` + `aria-label` + `data-tip` with the key in parentheses |
| a toggle | one button, `aria-pressed`, label and glyph flip |
| a primary action with a key | `.accent` + label + `.k` keycap |
| a menu of actions | split button → popover, radius 10, arrow keys, Esc |
| a choice among modes | segmented, radio semantics |
| a thing you can filter by | chip (button) with its hue dot |
| a fact about a card | pill with a tip |
| a destructive action | outline red; a solid red only inside a confirm |
| something the owner must notice | amber tint + a sentence, never only a colour |
| a count | a pressable chip, never a tile |

## 10 · Gaps found 2026-08-23, with fix and check

Each is a measurement, so each can be re-measured. None changes the look;
all of them remove a second way of doing one thing.

| # | gap | measured | fix | check |
|---|---|---|---|---|
| G1 | the token block is duplicated in `board.html` | two identical 30-line blocks, hand-synced twice this week | board links `shared.css`; delete its block | `rg -c -- "--canvas:" board.html` = 0 |
| G2 | radius drift | 15 values on the board | the five-step ladder as tokens (`--r-inner/-control/-card/-panel/-round`) | `rg -o "border-radius:[0-9.]+px"` yields only ladder values |
| G3 | type scale drift | 14 sizes | the seven steps as tokens (`--fs-micro` … `--fs-display`) | same grep on `font(-size)?:` |
| G4 | four focus recipes | 2px ring + three glows | one ring; one glow on the writing surface, `var(--focus-glow)` | `rg -c 'var\(--focus-glow\)' board.html` = 4, and no raw `color-mix` glow outside the three named effects |
| G5 | seven transition durations | .1 … .22 | `--t-fast: .12s`, `--t-move: .22s` | `rg -o "\.[0-9]+s"` yields two |
| G6 | `.primary` duplicates `.accent` | two solid variants, 28 vs 30 px | drop `.primary`, one height | `rg -c "\.primary" board.html` = 0 |
| G7 | `.icon` vs `.ico` | two icon-button names | keep `.icon`, hub adopts it | `rg -c "\.ico\b"` = 0 |
| G8 | eight hover recipes | counted | three (quiet, raised, accent) as mixins | hover grep yields three bodies |
| G9 | reduced-motion | one global rule + eight local | global only, after G1 | local rules = 0 |
| G10 | z-index unnamed | nine numbers | the §5 ladder as tokens | `rg -o "z-index:[0-9]+"` = 0 (all `var(--z-…)`) |
| G11 | ink-only tag hues | violet, pink, teal, grey lack tint and line | give each the three-shade ladder | a priority chip's `.on` renders tinted |
| G12 | no split / menu button | none exists; two callers arrive with #38 and Offer | define `.split` once in `shared.css` | both callers use it; a11y menu semantics |
| G13 | board links no shared sheet or script | known copy of icons, tokens, tooltip | link both; delete copies | `rg -c 'href="/shared\.css"\|src="/shared\.js"' board.html` = 2 |
| G14 | light theme | verified only on surfaces touched this week | the §17 pass runs both themes per element | screenshots in `REVIEW-<date>.md` |
| G15 | silently disabled controls | template selects at 45% with no hint | hidden or a tip that says what would enable it | a11y tree: no `disabled` without `aria-description` or absence |
| G16 | empty-state voice | "No cards in this lane" vs "Nothing yet. Write anything above…" | one voice: what is missing, then what to do | grep the three empties |
| G17 | typed arrow in a link | "open in tab ↗" | the drawn external glyph | charter test's §5 row widened to `<a>` |
| G18 | `.kbd` keycap vs `.k` hint | two keycap styles | one `.k` | grep |
| G22 | quiet hover: the book and the code disagree | §8 defines quiet as "ghost → well ground", but 9 of the 15 real hovers come up to `--card` and only 6 to `--well`; `--well` is the smaller step, so adopting it makes every chrome button's hover fainter | owner picks one, then it is applied everywhere at once | count the two bodies; one of them must reach 0 |
| G21 | a focused card and a selected card look identical | `.card:focus-visible` and `.card.sel` share one `0 0 0 2px` shadow, so keyboard focus is indistinguishable from selection, and `x` selects whatever the ring is on | give focus the §3.3 outline and leave the shadow to selection | tab to a card without selecting it; the two states must differ |
| G20 | the toast is below every overlay | `#toast` is z 3, `#help` is 50, so a toast fired while any overlay is open is invisible; measured live, and it predates this work | either lift the toast above the modal tier, or adopt a corrected §5 ladder wholesale | open the help modal, fire a toast, see it |
| G19 | the shared key map has no overlay guards | `t` is bound in both `shared.js` and `board.html`; board returns early inside five overlays, shared does not, so linking makes `t` fire twice and fire inside overlays | `data-keys="own"` on `<html>`; the shared handler returns before reading the key (charter §10) | remove the attribute and `t` must stop toggling |

**G15, G16, G17 and G18 landed 2026-08-24 (pass 4, task #64).** The one control
that goes quietly grey on this board, the selection bar's Clear, now says what
would enable it instead. Two bare empty states got the second half of the voice
the other four already had; the tag-peek one had been saying "No cards yet"
directly under a bar already reading "Nothing carries this tag yet". The two
typed corner arrows became one drawn `EXT_ICON`, and **`test-charter.sh` was
widened in the same change** rather than left behind the rule: its §5 row read
only a button whose ENTIRE content is a dingbat, so both arrows hid from it
because they carried a label too. The new row bans the character outright in all
three pages, and it was mutation-tested — putting `open in tab ↗` back turns it
red while the old row stays green, which is what "the widening was necessary"
looks like as evidence. Two keycap styles became one `kbd`.

**G14 is not pass 4's to close.** Its own fix says "the §17 pass runs both
themes per element" and its check is "screenshots in `REVIEW-<date>.md`", which
is task #16's instrument. Closing it here would mean claiming a sweep that has
not run.

**G6, G7 and G11 landed 2026-08-24 (pass 3, task #63).** `.primary` was
`.accent` plus an explicit 30px height, and it had one caller; its keycap rule
moved to `.accent`, where the note popover's Save had been carrying an unstyled
`.k` all along. `.ico` turned out to be `.ghost` + `.icon` + a fixed 30×30 box
whose colours were already byte-identical to `.ghost`, so the hub now writes the
composition the board already used, `class="icon ghost"`. The four ink-only hues
have their tint and line in both themes, every kind carries all three shades, and
a tag chip's `on` is tinted rather than outlined: measured, eight kinds, eight
distinct backgrounds.

**Two gaps in pass 3 were deliberately NOT closed.**

`G12` (the split button) has no caller. Its own row says "none exists; two
callers arrive with #38 and Offer", and neither exists yet: there is no `.split`
rule and no `class="split"` in any file. Building it now would be an exported
abstraction with zero call sites, which is the one thing
`rules/speculative-abstractions-without-a-load-bearing-caller.md` exists to stop.
It should be defined inside #38, where the first real caller lands, and the
second caller then adopts it. Its check is also unusable as written: `\.split\b`
matches every JavaScript `.split()` call and reports 12 hits in `board.html`
today, none of them CSS.

`G8` (three hovers) is the G22 disagreement above and needs a ruling before any
of the 15 bodies move, because the two candidate recipes differ in how loud every
chrome button feels and the owner has been explicit about wanting flair.

**G2, G3 and G4 landed 2026-08-24 (pass 2b, task #62):** 84 radius values onto
five steps plus the hairline, 171 type values onto seven steps, and the four
focus glows onto one `--focus-glow`. Two consequences worth knowing. `body` was
13px, half a pixel off the 13.5 step, so it collapsed onto it and roughly 220
inheriting elements grew half a pixel; that is the drift this ladder exists to
remove, and nothing reflowed. And `#help`, `#pop`, `#docmodal` and the three
pickers lost 2 to 4px of corner, which is the only change visible without a
ruler; the help modal re-ran its scroll-parity check on all five tabs and holds.
**G4's own check was too broad** in the same way G13's was: `0 0 0 [0-9]px`
counts every ring-shaped shadow, so it swept in the `fx-save` and `.found`
keyframes this book says must stay. Rewritten to name the token. G21 came out
of doing it.

**G5 and G10 landed 2026-08-24 (pass 2a, task #62):** the ladders are tokens in
`shared.css`, 59 transition durations collapsed to `--t-fast` / `--t-move` (the
drawer's width is the only genuine move), and all 11 bare `z-index` numbers are
named at their existing values, so nothing restacked. G20 came out of doing it.

**G1, G9, G13 and G19 landed 2026-08-24 (pass 1, task #61).** Three effects are
deliberate, not drift: a relative time under 90 seconds now reads in seconds
(`shared.js`'s `ago` has a tier board's copy lacked), the switcher glyphs are
13px rather than 14px (`NAV_ICON` is the one set), and a truncated path grows
back when its column widens, which board's own `tailTrim` could not do although
the comment beside it said it did. Two things had to be built rather than
deleted: G19 below, and an explicit top margin on `.term p` and
`.hplay .pane-l p`, because `shared.css` resets `*{margin:0}` and both had been
living on the UA default of `1em`. Measured before and after: 12.5px either way.

Order for the next agent: G1 and G13 first (they remove the duplication that
makes every other fix two edits), then G2–G5 and G10 as a token pass with the
charter's §14 round in both themes, then G6–G8 and G11–G12 as the component
pass, then G14–G18 as the voice and a11y pass. The §17 review (#16) reads
this book as its rubric for §§2–8.

## 11 · What this borrows, and what it refuses

Borrowed from the office kit's design language, as principles only: colour is
semantics; a control that cannot act is hidden or explains itself; a toggle
is one control that flips; the toolbar's right-hand action declares itself;
an interactive thing is a real control with a name. Refused on purpose: its
neutral palette, its flat hierarchy, its eight-way semantic colour set, and
its single-component button API. This app keeps six lane hues, eight tag
hues, a tinted drawer and an amber that shouts. Standardise the ladders, keep
the pomp.

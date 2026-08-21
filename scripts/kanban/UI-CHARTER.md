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

## 5. Icons

- **Every action button carries a glyph**, and the tooltip carries the sentence.
  A row of five word-buttons is noise (owner, 2026-08-21, on the asks rail).
- **Drawn, not typed.** Inline SVG at the board's optical weight,
  `currentColor`, 11 to 13px. Emoji and unicode dingbats do not match.
- **One glyph per meaning across the whole board.** The send arrow, the check,
  the note page and the target each appear once in the vocabulary.
- **Icons never replace a label in a primary control.** They accompany it.

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

## 12. Reporting and honesty in the UI

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

## 15. Changelog

- **2026-08-21.** Founding set, distilled from the column-width, title-brief,
  panel, notes, selection, status-band, tag and modal-sweep rounds.
- **2026-08-22.** Added the §7 peer-highlight rule (blue primary, green peer,
  dotted spaced outline, soft glow), the middle-click convention, and the
  "should be fun" clause in §1.
- **2026-08-22, second round.** Three rulings earned while building under it.
  A binding shows on its control, not only in help (§10). A palette is one
  component with sections, reused rather than re-hand-rolled per use (§13). A
  temporary surface carries a dashed border and a tinted ground, and is
  dismissed rather than dropped by the next click (§9), which is the peek
  column. Search has its own contract in SEARCH-DESIGN.md and that document is
  its acceptance list.

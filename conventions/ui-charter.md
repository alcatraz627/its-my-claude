---
brief: Give any app or UI the owner reviews repeatedly its own charter file, holding a dated record of every design ruling made on it. Used as the interpretation half of short requests and as a count-capped QA round after each change, so the owner stops re-stating the same preferences every round.
triggers:
  - topic:ui-charter
  - topic:design-rulings
  - topic:ui-round
  - phrase:"design system"
  - phrase:"don't make me repeat"
  - phrase:"every UI round"
  - phrase:"UI polish"
related:
  - conventions/visual-design.md
  - conventions/dashboard-tools.md
  - conventions/tui-handbook.md
  - conventions/preference-graduation.md
tier: 2
category: conventions
updated: 2026-08-22
stale_after_days: 365
---

# Give a long-lived UI its own charter

A UI the owner reviews more than twice accumulates rulings: a width, a hover
colour, where a label sits, what a chip may not do. Those rulings arrive one
round at a time and are then re-stated one round at a time, because nothing
holds them. The fix is a file in the project that does.

The owner's own framing, 2026-08-22, on the kanban board: *"I want to prepare a
charter we can use and keep adding to for every UI round, so I don't have to
repeat everything everywhere."*

## When a project earns one

Two conditions, both required:

1. The owner has reviewed this surface at least twice and given corrective
   feedback each time.
2. That feedback keeps generalising. "Make this button green" does not earn a
   charter. "Colour is spent once per object" does.

A surface built once and left alone does not need one. Neither does a script
with no visual output.

## What it holds

The charter is not a style guide copied from elsewhere. Every line is a ruling
this owner actually made on this surface, with its date, so it reads as a
record rather than as received wisdom.

Sections that have earned their place:

- **The disposition.** What the surface is for, in a paragraph, and the two or
  three consequences everything else follows from.
- **The category rules.** Language and labels, typography, colour, icons,
  spacing, interactivity, motion, overlays, keyboard, and where data lives.
  One section each, bullets, each bullet a ruling.
- **Standing anti-patterns.** A table of mistakes that were actually shipped
  here and corrected. This is the most useful section and the least likely to
  be written, because it requires admitting what went wrong.
- **A changelog** with dates. New rulings are appended the day they are made.

Keep it to rulings. A charter that starts explaining CSS is being padded.

## The two jobs it does

**Interpretation.** Read it before building any change to that surface. When a
request is short, the charter is the missing half of it. This is where the
value is: a one-line ask becomes a correct change because the constraints were
already written down.

**A QA round after building.** Bounded by counts, not by exhaustiveness,
because the point is to keep moving. A budget that has worked:

| Check | Count |
|---|---|
| Changed elements inspected against the style sections | 10 |
| Adjacent elements checked for consistency drift | 6 |
| Overlay-contract checks, only if an overlay was touched | 5 |
| Keyboard paths walked end to end | 4 |
| Themes | both, always, uncounted |
| Honest sentence naming what was skipped | 1 |

Run it as the same agent that built the change, in one pass, driving the real
thing. One subagent is warranted when the change spans more than three
surfaces; a fleet never is. Save the exhaustive pass for final validation.

Log a borderline case as a charter question for the owner rather than
relitigating it. A round that finds nothing says so in one line.

## How to start one

Do not invent it. Read back through the feedback already given on that surface
and distil it, which means the first version is written from a transcript
rather than from taste. Then keep it current. A ruling added the same day it is
made costs a minute, and a ruling reconstructed a month later is usually wrong.

## The worked example

`~/.claude/scripts/kanban/UI-CHARTER.md` is the live one, written for the agent
kanban board across several rounds of owner feedback. It is worth reading for
its shape rather than its content, since its content is specific to that board:
fifteen sections, nine anti-patterns each traced to a real correction, and the
capped QA round above.

## Related

- `conventions/visual-design.md` holds the cross-project visual reference. A
  charter is where one specific surface's decisions live; that file is where
  the general principles do.
- `conventions/dashboard-tools.md` is the build template for the class of
  single-user tool that most often earns a charter.
- `conventions/preference-graduation.md` is the sibling mechanism, for
  preferences that generalise past one surface and belong in the global config
  instead.

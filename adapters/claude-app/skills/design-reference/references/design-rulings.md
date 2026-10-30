# A design-rulings record per app

A UI the user reviews more than twice collects rulings: a width, a hover color,
where a label sits, what a chip may not do. Those rulings arrive one round at a
time and then get re-stated one round at a time, because nothing holds them.
The fix is one written record per app that does.

Chat has no memory of last week's round, so the record has to live somewhere
the user keeps:

- **A doc** (a Claude doc, Google Doc or similar) the user opens each round.
- **A Project file** in a claude.ai Project, so it loads with every chat there.
- **A file in the repo** (`docs/design-rulings.md` or similar) when you work in
  Claude Code or the user pastes it.

Ask where it lives the first time it earns one. At the end of each round, hand
back the updated record, or the lines to append, so the user can save it.

## When an app earns one

Two conditions, both required:

1. The user has reviewed this surface at least twice and given corrective
   feedback each time.
2. That feedback keeps generalizing. "Make this button green" does not earn a
   record. "Color is spent once per object" does.

A surface built once and left alone does not need one. Neither does a script
with no visual output.

## What it holds

It is not a style guide copied from elsewhere. Every line is a ruling this user
made on this surface, with its date, so it reads as a record rather than as
received wisdom.

Sections that have earned their place:

- **The disposition.** What the surface is for, in a paragraph, and the two or
  three consequences everything else follows from.
- **The category rules.** Language and labels, typography, color, icons,
  spacing, interactivity, motion, overlays, keyboard, and where data lives.
  One section each, bullets, each bullet a ruling.
- **Standing anti-patterns.** A table of mistakes that shipped here and were
  corrected. This is the most useful section and the least likely to get
  written, because it means admitting what went wrong.
- **A changelog** with dates. New rulings are appended the day they are made.

Keep it to rulings. A record that starts explaining CSS is being padded.

## Template

```markdown
# <App> design rulings

## Disposition
<What this surface is for. Two or three consequences.>

## Color
- <ruling> (YYYY-MM-DD)

## Typography
- <ruling> (YYYY-MM-DD)

## Layout and spacing
## Interaction and keyboard
## Overlays and motion
## Language and labels

## Anti-patterns we shipped and fixed
| What shipped | Why it was wrong | The rule now |
|---|---|---|

## Changelog
- YYYY-MM-DD: <ruling added or changed>
```

## The two jobs it does

**Interpretation.** Read it before building any change to that surface. When a
request is short, the record is the missing half of it. A one-line ask becomes
a correct change because the constraints were already written down.

**A QA round after building.** Bounded by counts, not by exhaustiveness, because
the point is to keep moving. A budget that has worked:

| Check | Count |
|---|---|
| Changed elements inspected against the style sections | 10 |
| Adjacent elements checked for consistency drift | 6 |
| Overlay checks, only if an overlay was touched | 5 |
| Keyboard paths walked end to end | 4 |
| Themes | both, always |
| Honest sentence naming what was skipped | 1 |

Run it in the same pass that built the change, on the rendered result. Use the
`ui-critique` skill's categorical check for the measuring.

Log a borderline case as an open question for the user rather than
relitigating it. A round that finds nothing says so in one line.

## How to start one

Do not invent it. Read back through the feedback already given on that surface
(this chat, pasted notes, earlier screenshots) and distill it, so the first
version is written from a transcript, not from taste. Then keep it current. A
ruling added the day it is made costs a minute. A ruling reconstructed a month
later is usually wrong.

## Where it sits

The general principles live in `visual-design.md`. A rulings record is where
one specific surface's decisions live. When a ruling generalizes past one app
("the user wants text to wrap, never ellipsis"), it belongs with the user's
general preferences instead.

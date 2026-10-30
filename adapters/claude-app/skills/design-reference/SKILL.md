---
name: design-reference
description: Reference for designing or restyling a visual surface. OKLCH color tiers, severity, layout, type, dark and light tokens, mobile patterns, and a per-app rulings record. Use before building UI.
---

# Design reference

What to consult before you draw a UI: a web page, an artifact, a native app
screen, a widget, a dashboard. This skill is the reference shelf. It does not
critique and it does not mock.

- Critiquing something already rendered: use `ui-critique`. Its defaults (type
  scale, spacing, contrast, interactive states) live there, not here.
- Putting candidate looks in front of the user: use `mock-app`.
- Terminal tools, TUIs and agent-driven tools: use `tool-design`.

## What is in references/

| File | Read it when |
|---|---|
| `visual-design.md` | Choosing colors, status lights, hierarchy, spacing, sizes, or making sibling surfaces agree. Also holds curated links per platform. |
| `html-pages.md` | Building any HTML page or artifact. The mandatory dark and light toggle, the token floor, complexity tiers. |
| `colors.css` | A page needs real color: brand, accent, status pills, filled buttons. Drop it in and change only the hues. |
| `data-dashboard.html` | A "counts at a glance, then drill in" page over nested data. Copy and adapt. |
| `mobile-patterns.md` | Designing or reviewing a mobile, capture, list, notes or task surface. |
| `design-rulings.md` | The user has reviewed this app twice or more and keeps re-stating the same preferences. |

Read the one file the task needs, not the shelf.

## The rules that apply to almost every surface

These are the condensed core. The reference files carry the reasoning and the
worked examples.

**Color**
- Put every color on an OKLCH grid. Fix lightness and chroma per emphasis
  tier (loud, medium, quiet), vary only hue inside a tier.
- Green, amber and red form a closed severity set. Nothing ambient borrows
  them at high chroma.
- Aim for about 60% calm neutral, 30% ambient color, 10% loud accent.
- Dark mode keeps each hue and raises lightness while lowering chroma.

**Severity**
- A light fires on evidence of a felt problem, not on a metric crossing a
  line. A steady-state amber is a bug.

**Layout and type**
- Weight and spacing carry hierarchy. Color comes third.
- One type scale of about three tiers. Mono for code, ids and aligned numbers,
  the system sans for prose and chrome.
- One spacing rhythm. Inconsistent spacing usually means a missing shared row
  primitive.
- Text wraps. Never cut prose or labels with an ellipsis. Where a value truly
  cannot grow, show it whole on hover or click.
- Ship sm, md and lg sizes from one token set, and check md and lg too.

**Pages**
- Every color is a CSS custom property. No hex on elements.
- Every page has a dark and light toggle. Dark is the designed-first palette.
  With no stored choice the page follows the OS, and only an explicit click is
  stored.
- Pick the lightest tier: plain HTML, then vanilla JS, then Tailwind with
  DaisyUI only on evidence.

**Words**
- Words on screen are for people. No em dashes in UI text, no raw machine
  tokens without a label.

## The user's default taste

For developer tools (dashboards, admin panels, monitors, debugging UIs), the
user's stated default is dark, dense and terminal-like, and keyboard-first.
That means muted charcoal rather than true black, tight row heights, monospace
for data, semantic color only, and every common action reachable from the
keyboard. Consumer and marketing surfaces do not inherit this. The project's
own tokens and the user's rulings record outrank it whenever they exist.

## How to use this while building

1. **Read the rulings first.** If the user has a design-rulings record for
   this app (a doc, a Project file, a repo file), read it before anything else.
   If the app has earned one and has none, offer to start it from the feedback
   already given. See `design-rulings.md`.
2. **Read the canon.** The project's tokens, sibling screens and shipped
   values beat anything here. These references fill gaps only.
3. **Open the matching reference** from the table and apply it. Cite the rule
   you followed when a choice might surprise the user.
4. **Build on tokens from the first line.** Start from `colors.css` or the
   five-token floor in `html-pages.md`, never from hex on elements.
5. **Look at the result.** Render it, view both themes and phone width, then
   hand it to `ui-critique` for a categorical check before calling it done.
6. **Record new rulings.** When the user rules on something that will recur,
   add it to the rulings record with today's date and hand the updated record
   back for them to save.

## Taste questions

When a choice comes down to taste ("which accent", "how heavy should the
header be"), do not settle it in prose. Render three to six variants with
`mock-app` and let the user pick by looking. Log the pick in the rulings
record.

## Boundaries

- This is reference, not authority over the project. The project's own design
  system and the user's rulings win.
- Do not invent numbers. A contrast ratio or size claim comes from a
  measurement or is labelled as a prediction.
- For charts and data graphics, apply these color tiers, and use a charting
  skill if one is available for the marks themselves.

## Related skills

`ui-critique` (critique and categorical checks), `mock-app` (mocks and
variants), `tool-design` (CLI, TUI and agent tools), `html-report` (styled
reports), `svg` (icons and logos), `diagrams` (architecture and flow
pictures), `plain-writing` (the words on the page).

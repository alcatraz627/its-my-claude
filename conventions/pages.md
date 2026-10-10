---
brief: Which surface to show something on (markdown, local page, Artifact, decision page), and the shared kit and checks every HTML page uses
triggers:
  - topic:html-output
  - topic:reports
  - topic:artifacts
  - topic:previews
  - skill:page
  - tool:pagekit
  - phrase:"local preview"
  - phrase:"html report"
related: [conventions/html-output.md, rules/no-unasked-artifact-publish.md, rules/owner-decisions-go-through-a-wizard.md, rules/ui-visual-verification.md]
tier: 2
category: conventions
updated: 2026-09-29
stale_after_days: 90
---

# Pages

One rule for where something is shown, one kit for how it looks, one check for whether it works. The skills that make pages stay separate. They share these three.

## Which surface

Ask two things: who opens it, and does it need an answer back.

| Who opens it | Needs | Surface | Made with |
|---|---|---|---|
| Only the owner | Plain reading | A markdown file. The owner's browser renders markdown | Write the `.md` |
| Only the owner | Layout, tabs, or something to click | A local HTML page | `pagekit.py`, or a generator built on it |
| The owner must answer something | Picks, rulings, notes | A decision page | `/decision-wizard` |
| Someone else | Anything | An Artifact | The same HTML as the local page. Publish only when the owner asks |
| A room, from a screen | Slides | A deck | `/deck` |

Three rules that follow:

- Start at the top row. Move down only when the row above cannot do the job.
- A local page and an Artifact are the same file. Build and check it locally, then publishing is a separate step the owner asks for (`rules/no-unasked-artifact-publish.md`).
- A heavy one-off preview, such as a UI mock, is a local HTML page. It uses the kit for its frame, and its own styles only for the thing it previews.

## The kit

Everything is in `~/.claude/scripts/pages/`.

| File | What it gives |
|---|---|
| `pagekit.py` | `page()` wraps a body into one self-contained file. `from_markdown()` turns markdown into a styled body. `size_columns()` sets table widths from content |
| `kit.css` | Type, tables, tabs, cards, side-by-side lists, notes, chips |
| `kit.js` | The theme switch, table headers that follow the reader, tabs |
| `conventions/html-assets/colors.css` | Every colour. Rebrand by editing its hue numbers, and nothing else |
| `demo.md` | A page that uses every part of the kit |

The shortest path from markdown to a page:

```
uv run --with markdown python3 ~/.claude/scripts/pages/pagekit.py in.md out.html
```

### What every page carries

| Thing | Rule |
|---|---|
| Theme | Dark and light, with a switch in the bar. Dark is the default |
| Colour | Only through the variables in `colors.css`. No colour written on an element |
| Tables | Column widths from `size_columns()`. Headers follow the reader. A table scrolls sideways only from eight columns |
| Text | No paragraph over about 60 words. A table cell is a lead line, then bullets |
| One file | Styles and script inline, so the file opens anywhere and publishes as it is |
| Links to headings | Anchors from `pagekit.slug()`, which match what a markdown viewer makes |
| Size | sm, md, lg from one set of size tokens: text steps most, icons less, inputs and spacing least (`conventions/visual-design.md`, One product). Check md and lg renders, not only sm |

### Writing markdown that lays out well

| In markdown | Becomes |
|---|---|
| `Lead line.<br>• point<br>• point` in a table cell | A lead line and a real list |
| A bold line, then a list, two or three times in a row | Lists side by side |
| `## Heading` | A section with an anchor |

## The check

```
uv run --with playwright python3 ~/.claude/scripts/pages/check_page.py out.html --out <folder>
```

It opens the page in headless Chrome and fails on any of these:

| Check | Fails when |
|---|---|
| Page errors | The page's script throws |
| Sideways scroll | The page, or any table, is wider than its box |
| Links | A link inside the page points at no heading. Pass `--hash-routing` when the page routes `#` links itself |
| Theme | There is no switch, or the switch changes nothing |
| Readable text | In either theme, any text has less than 3 to 1 contrast with what is behind it |
| Table headers | A tall table's header does not sit under the bar after scrolling |

It saves a screenshot of each theme. Read both before calling the page done (`rules/ui-visual-verification.md`). A pass means the page works. It does not mean the page reads well.

## What is on the kit, and what is not yet

| Surface | State |
|---|---|
| `pagekit.py` pages | On the kit |
| The SoR docket (`~/Code/Versable/sor/docket/build_docket.py`) | Its own styles, with a theme switch, and the kit's column sizing and sticky headers copied in. It passes the page check. Not moved onto the kit yet |
| Decision pages (`scripts/decision-page/`) | Its own styles. Next to move |
| Decks (`scripts/deck/`) | Its own styles |
| `/create-report` and its thirteen styles | Old. To retire once the owner's picks are harvested |

Move one surface at a time, and run its own checks after each move.

## Older guidance

`conventions/html-output.md` was the earlier front door. Its colour system, `colors.css`, is what the kit uses. Its complexity tiers and snippet table still hold for pages that outgrow the kit.

---
name: html-report
description: Turns markdown or findings into a self-contained HTML report in one of 13 styles, as an artifact or .html file, with an optional PDF. Not for slide decks (use deck).
---

# HTML report

Turn a markdown file, pasted notes, or findings from this conversation into
one HTML page that opens anywhere: all CSS inline, no build step, dark and
light themes. The value is in the 13 tested styles under `references/`, so
build from them instead of writing a stylesheet from scratch.

Not for slide decks with presenter notes (use `deck`) or for clickable app
mocks (use `mock-app`).

## Step 1: Shape the content

1. Read all of the source. If it is a file the user attached, read the file,
   not a summary of it.
2. Map it to the report shape: one H1 title, an optional subtitle, a
   generated date, H2 sections, and H3 or H4 subsections inside them.
3. Turn fenced `csv`, `json` (an array of objects) and `yaml` blocks into
   tables by parsing them in the sandbox. Do not retype data by hand.
4. Turn ASCII directory trees (`├──`, `└──`) into tree blocks and leave flat
   lists as lists.
5. Keep every number and claim as the source states it. If you write new
   prose for the report, follow `plain-writing`.

## Step 2: Pick the style

Read `references/styles/INDEX.md`. A style the user names wins. Otherwise
pick from the content:

| Content | Style |
|---|---|
| Mostly prose | default, notion, magazine, minimal |
| Mostly tables | data-table, dashboard |
| Mostly code | terminal, jupyter |
| A timeline or sequence of updates | feed |
| Numbered sections, citations, an abstract | academic, corporate |

When no kind of content clearly dominates, use `default`. Say in one line
which style you picked and why, and name two alternatives the user can ask
for.

## Step 3: Build the page

1. Read `references/skeleton.md`. It has the shell, the markup for each
   content block, and the body for each style.
2. Inline `references/styles/shared-base.css` and then
   `references/styles/<style>.css` into one `<style>` block, unchanged. The
   class names in the markup must match the ones the skeleton shows.
3. Put the theme script from the skeleton first in `<body>` and place the
   theme toggle where the style body marks `{toggle}`. Every report must open
   in the viewer's system theme and switch both ways.
4. Escape `<`, `>` and `&` in code before adding the token spans.
5. Leave out search, width pickers and the code expand dialog. They needed a
   script that is not part of this skill.
6. No remote images. Fonts from Google Fonts and KaTeX from jsDelivr are the
   only network loads, and the page must still read correctly without them.
   Load KaTeX only when the report has math.
7. `data-table` needs the tab script from the skeleton. `terminal` needs the
   inline typing animation sized to the title length.

## Step 4: Deliver

- **In chat**, publish the page as an HTML artifact so it renders inline.
- **As a file**, write `<slug>.html` in the sandbox and offer it as a download
  when the user wants to keep, email or host it, or asks for a file. In Claude
  Code, write it where the user asked, or next to the source.
- Use a short slug from the title, such as `q3-audit-report.html`.

## Step 5: Look at it

A page that parses is not checked. Pick one and say which you did:

- **Sandbox render.** If a headless browser installs in the sandbox (for
  example `pip install playwright` and `playwright install chromium`), load
  the file at 1280 by 800, screenshot it once in dark and once in light, and
  view both images. Network rules often block the browser download, so try it
  and report what happened.
- **User screenshot.** Otherwise ask the user for a screenshot of the artifact
  in each theme, and say that you have not seen it yet.

Check: every block has its styling, tables fit or scroll inside their box,
text is readable in both themes, the toggle switches, and nav links land on
their sections. Fix and look again after every change.

## Optional: a PDF

Make a PDF only when the user asks for one. A PDF is paper, so it uses the
print sheets in `references/pdf/` and is light only.

| Sheet | Use for |
|---|---|
| `professional.css` | Client-facing docs, proposals, handoffs. Serif headings, wide margins |
| `academic.css` | Papers and formal reports. Justified text, LaTeX feel |
| `compact.css` | Cheat sheets and dense reference. Smallest type and margins |

1. Convert the markdown to HTML in the sandbox with the `markdown` package
   (extensions `tables`, `fenced_code`, `toc`) and wrap it with the chosen
   sheet in a `<style>` block.
2. Options the user can ask for:
   - **Cover**: a centred title and date page, then a page break.
   - **Contents**: a list of H2 to H4 links, added when there are four or
     more sections.
   - **Landscape**: add `@page { size: A4 landscape; }` for wide tables.
3. Render with headless Chromium (`page.pdf()`) when it installs. Otherwise
   use WeasyPrint (`pip install weasyprint`), which needs no browser but runs
   no JavaScript, so write math as images or plain text.
4. Render page 1 to PNG (`pdftoppm` or PyMuPDF) and view it before handing
   the PDF over. Check page breaks around tables and code.
5. Report the file name and size.

## Hand-off

End with four lines:

1. Style used, and the two alternatives offered.
2. Deliverable: artifact, `.html` file, or both, with the file name.
3. How it was checked: sandbox screenshots in both themes, or waiting on the
   user's screenshots. If you have not seen it, say so.
4. PDF: file name, sheet and size, or "not requested".

## Related skills

- `plain-writing` for prose written into the report.
- `diagrams` or `svg` for a figure the report needs.

# Report styles

Thirteen styles. Each `<style>.css` file sits on top of `shared-base.css`, so a
page inlines both, shared-base first. The page markup each style expects is in
`../skeleton.md`.

All thirteen switch between dark and light through CSS custom properties. The
switch is a class or attribute, set by the theme script in the skeleton:

| Style | Default | Switch |
|---|---|---|
| terminal | dark (matrix) | `data-theme` on `<body>`: `paper` is light, the other 15 palettes are dark |
| jupyter | light | `dark` class on `<html>` |
| all others | dark | `light` class on `<html>` |

The theme script sets both `light` and `dark` classes, so one script serves
every style.

## Picking a style

| Content | Pick |
|---|---|
| Mostly prose | default, notion, magazine, minimal |
| Mostly tables or structured data | data-table, dashboard |
| Mostly code | terminal, jupyter |
| Dated events, a timeline, a narrative | feed |
| Numbered sections, citations, an abstract | academic, corporate |
| A talk or walkthrough read section by section | slide |
| A showpiece where look matters more than density | neon, magazine |

When no signal reaches about 60 percent of the content, use `default`.

## The styles

**default.** A documentation layout: fixed header with title and generated
date, a sticky left sidebar listing H2 and H3 sections, and a content column
up to 960 px. Indigo accent, GitHub-like greys, H2s with an accent underline.
Pick it when nothing else fits, or for reference docs and project indexes.

**notion.** Clean and quiet, like a Notion page. A floating breadcrumb bar
with jump links, a title block, and every H2 section in its own soft card with
generous whitespace. Inline code is pink. Pick it for internal write-ups,
meeting notes, and plans meant to be read top to bottom.

**dashboard.** A dark analytics view: gradient header, a row of four metric
cards (sections, tables, code blocks, date), a left section nav, and each
section as an open accordion with a coloured bar. Status pills
(`pill-active`, `pill-maintenance`, `pill-degraded`) are styled. Pick it for
status reports, audits, and anything led by numbers.

**magazine.** Editorial: a hero header with serif display type, issue line
and stats, the first section set in two columns with a drop cap, and a
three-dot ornament between sections. Warm paper tones in light mode. Pick it
for narrative essays, retrospectives, and long reads.

**terminal.** A retro terminal window: title bar with traffic-light dots, a
typing animation on the title, `=== [01] Section ===` headers, ASCII-bordered
tables, `[OK]` `[WARN]` `[FAIL]` coloured in text, and CRT scanlines. Sixteen
palettes (matrix, amber, dracula, solarized, nord, monokai, gruvbox,
catppuccin, tokyonight, onedark, cyberpunk, phosphor, ibm3278, sunset, ice,
paper). Pick it for logs, CLI output, and developer-tool reports.

**data-table.** A spreadsheet: green header bar, a stats strip (sections,
tables, rows, code blocks), and one tab per H2 section with sticky table
headers and zebra rows. Needs the small tab script in the skeleton. Pick it
when tables are most of the content.

**feed.** A social timeline: each H2 is a post card with an avatar, a handle
derived from its content (`@data`, `@code`, `@report`), a hashtag, and
decorative reply, repost and like counts. Blockquotes render as quoted posts,
lists as thread replies. Pick it for changelogs, incident timelines, and
sequential updates.

**corporate.** A formal, print-ready report: serif type, a header with DATE,
CONTENTS and PREPARED BY rows, a numbered table of contents with dot leaders,
numbered sections and subsections (1., 1.1), and an optional diagonal
watermark from `data-watermark` on `<body>`. Pick it for client-facing
documents, legal or compliance summaries, and anything that will be printed.

**academic.** A LaTeX-style paper: centred serif title, an abstract block
built from the subtitle, a numbered contents list, numbered sections, and a
running header. Restrained syntax colours. Pick it for research notes,
technical analyses with citations, and papers.

**neon.** Cyberpunk: near-black background, cyan and magenta glow on
headings, a gradient glow bar on each section header, a left nav with
indicators, and a scanline overlay. Glow is toned down in light mode. Pick it
when the user wants something striking and density is secondary.

**minimal.** Reading-first: no sidebar, a collapsible contents list at the
top, one narrow column, maximum whitespace, quiet greys. Pick it for essays
and single-topic documents someone will read once, carefully.

**jupyter.** A notebook: a menu and toolbar strip, a left outline, and every
block as a cell. Code blocks get `In [n]:` prompts, tables, math and trees get
`Out[n]:` prompts, prose becomes markdown cells. Light by default. Pick it for
analyses, experiment write-ups, and data walkthroughs that include code.

**slide.** Presentation-like: each H2 fills the viewport with scroll
snapping, the first section is a title slide, with a progress bar, nav dots,
a floating contents list and a slide counter. Accent colours switch through
`data-accent` (indigo, violet, rose, amber, emerald, cyan, sky, orange, pink,
lime). Pick it for a report read section by section. For a real talk with
presenter notes, use the `deck` skill instead.

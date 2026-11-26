---
name: gdoc
description: Publishes markdown files as one Google Doc, a tab per file, in a named Drive folder; re-runs rewrite the tabs in place so the link never changes. Confirms the gcloud account and folder every run. Use when the owner wants a doc set in Google Docs for people who do not read markdown.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, mcp__claude-in-chrome__*
user-invocable: true
argument-hint: "<config.json> [--dry-run | --status]"
---

## Brief

`/gdoc` turns a markdown set into a Google Doc that people can open, comment on and
share. `~/.claude/scripts/gdoc/gdoc.py` creates the Doc once, then builds each tab
through the Docs API in the look of `~/.claude/scripts/shared/doc-style.json` (section
`gdoc`). Later runs rewrite each tab in place, so the URL is stable and edits made in
the Doc are overwritten; the markdown stays the source of truth. A run is done when
the pageless view, read in a browser at the reader's default width, looks right.

## How it is built

The script makes a Cover tab with the title and the list of files, and one tab per
markdown file with headings, paragraphs, lists, tables, code, bold, italic, inline
code and links recreated. Tab ids are kept in the config.

Tabs are created with the `addDocumentTab` request; the same request exists on
Google's hosted Docs MCP (`https://docsmcp.googleapis.com/mcp/v1`, tool `update_doc`).
The Drive HTML import is not used, because an import lands in a single tab.

The look comes from one shared spec, `~/.claude/scripts/shared/doc-style.json`,
section `gdoc`, read through `~/.claude/scripts/shared/doc_style.py`. The owner picked it
on 2026-11-27 from a canary Doc of variants: Inter for headings and body, JetBrains Mono
for code, Comfortaa for the title, subtitle and callout label, Open Sans for tables and
callout text, all on neutral zinc greys. Each item below is a key in that section:

- **title block**: the tab's opening `# Title` gets the Title style and the paragraph
  straight after it the Subtitle style, both left-aligned, with tight leading on the
  title and every heading (`heading_line_spacing`). See "Writing the markdown" for what
  they say.
- **table**: a light grey bold header, a thin zinc grid, Open Sans 9.5, header row pinned.
  Columns are laid out like a browser's auto table: each keeps its longest word whole, a
  short label or status column stays on one line, and the prose columns share the rest
  by how much they would wrap (`char_em` is the font's average character width). The
  empty lines Google leaves around a table are shrunk to 4 pt (`tight_gaps`; a config's
  `"tight_tables": false` keeps them). An empty header row (`| | |`) makes a header-less
  card table.
- **table_light**: `<!-- table: light -->` on the line before a table picks the light
  variant: no fill, no verticals, a rule under the header and thin row separators.
- **code**: one box per block with padding on all four sides (a soft line break keeps
  the block one paragraph) and a thin bar on the left; JetBrains Mono, coloured by token
  type with GitHub's light palette (`code.colors`, keyed by pygments token names such as
  `Keyword` or `Literal.String`, the most specific listed type winning; comments italic).
  Diagrams share the box without the bar, their strokes drawn lighter. Two boxed blocks
  in a row get a small spacer, because Google fuses matching borders.
- **mermaid**: a code fence tagged `mermaid` becomes an image in the same neutral look
  (`mermaid.theme` and `themeVariables`: Inter labels, zinc fills and lines). The script
  renders it with mermaid-cli (cached in `~/.cache/gdoc-mermaid`, keyed by source and
  theme), uploads the PNG to the Doc's folder with link sharing, inserts it at the text
  width, then trashes the upload; the Doc keeps its own copy. The Docs API cannot create
  an editable Google Drawing, so an image is the only native form; the markdown stays
  the diagram's source.
- **drawio**: a code fence tagged `drawio` holding the diagram XML, or a standalone image
  line `![alt](flow.drawio)` pointing at a file beside the markdown, becomes an image the
  same way (cached in `~/.cache/gdoc-drawio`, a multi-page file shows its first page).
  Rendering uses the draw.io desktop app's command line, installed once with
  `brew install --cask drawio` and removed with `brew uninstall --cask drawio`. Without it
  the run stops and names that command; it is never installed for you.
- **pageless**: every tab is set to pageless mode and read back; the run prints `layout
  pageless, N of N tabs read back` and a WARNING for any tab Docs left in pages.
  `"pageless": false` in the config keeps pages. Pageless text runs in a column set by
  each reader's own View > Text width (Narrow by default, 516 pt). The API cannot set it,
  and the Doc's page size and margins do not change it (tested 2026-11-27). Docs centres
  tables and images at their point width, so pageless tables and images are sized to
  516 pt (`gdoc.pageless`), flush with the text at Narrow. A reader who wants it wider
  switches their own Text width; only pages mode on a custom page fixes the width for
  everyone.
- **rhythm**: body text at 145% leading with 8 pt below each paragraph and widow and
  orphan control (`readability`; a config can override or turn it off); the tab's opening
  heading has no space above it; a paragraph after a list gets the body gap.
- **rich content**: `![alt](https://…png)` inserts an image (public PNG, JPEG or GIF;
  local files and SVG get their alt text), `text[^1]` with a `[^1]: note` line makes a
  footnote, `[Name](mailto:…)` a person chip, `[Oct 1, 2026](date:2026-10-01)` a date
  chip, a bare `<https://docs.google.com/…>` link a rich-link chip, `---` a thin rule,
  `\newpage` a page break. Objects are placed in a last pass from markers, like tables.
- **callout**: one box, the key line (glyph + LABEL in Comfortaa bold) and the text under
  it in Open Sans, both at the same indent, with padding above and below.
- **quote**: Inter on the faintest grey with a light opening mark and a thin bar.
- **lists**: 1.15 line spacing, no gaps between items; nesting by 2 or 4 spaces.
  `- [ ]` items become Google checkbox bullets (a ticked `- [x]` shows unticked; the API
  cannot tick it).
- **inline_code**: a thin space either side in the code tint.

## Writing the markdown

The script publishes what the markdown says, so the house style lives in the markdown.
It prints a `check` line for each rule a tab breaks; the publish still runs, and each
check is fixed in the markdown before calling the run done.

- **Document name** (set when the Doc is created): `<Title> | <Mon D, YYYY> | Aakarsh Chopra`,
  from the config's `title`, `date` (fixed at creation, written back) and `author`
  (default from the spec).
- **Title**: the `# ` line, one phrase of 5 words or fewer.
- **Subtitle**: the line right after it, `<topic> | <same date> | <author>`, the topic a
  terse label such as `PRD`, `Engg Spec Doc` or `Incident report`.
- **First section**: `## Notes`, a bullet list of at most 3 points and nothing else. Its
  links go to things a reader would open next: related docs, Linear tickets, markdown on
  GitHub, the source or the app URL. Not citations for claims made below.
- **Below Notes**: a real hierarchy, `#` for the major parts, `##` and `###` inside them,
  never a level skipped.
- **Prefer bullets and tables** over paragraphs where the reader scans: comparisons,
  statuses, steps, options.
- **Callouts only when justified**: a risk, a decision the reader must act on, or a rule
  that is easy to break. Not for emphasis.
- **No sections readers skip**: no References, Sources or Open questions section. A
  question that belongs in the doc goes in the part it affects, with its owner.
- **Diagrams**: a `mermaid` fence for flows and sequences (it renders in the house look);
  a plain fence only for a small text sketch. The image is scaled to the 516 pt column, so
  a flow of more than about five steps goes top-down (`flowchart TD`); left-to-right at
  that length shrinks its labels below reading size.

/word-doc renders the same section, by default, except `gdoc.pageless`. Change the
spec, never the document. A PDF export
(`https://docs.google.com/document/d/<id>/export?format=pdf&tab=<tabId>` with the
gcloud bearer token) is a paged Letter render with 1 in margins, so it checks content
and blocks but not the pageless layout readers see. The config's `cover` file (the README) becomes the Cover
tab, with its links to the other files turned into links to their tabs; the script
writes no generated-on line or any other text that is not in the markdown.
`--samples "<tab>"` writes one sample of every block the skills produce at the end of
a tab the owner keeps as a style guide, replacing the previous samples (from the
"Blocks the document skills produce" heading down); the owner's own samples above it stay.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## gdoc:` entries in
`~/.claude/skills/runtime-notes.md`. Run `python3 ~/.claude/scripts/gdoc/gdoc.py -h`.
After a change to the script, run `uv run --with markdown --with pygments python3 ~/.claude/scripts/gdoc/gdoc.test.py`.

## The run

1. **Config.** A `gdoc.json` next to the docs: `account`, `folder` (the Drive folder
   id from its URL), `title`, `docs` (paths relative to the config, in reading
   order), and optionally `quota_project`. After the first run the script writes
   `doc_id` and `html_sha256` back into it; commit that file so the next session
   updates the same Doc.
2. **Status first.** `uv run --with markdown --with pygments python3 ~/.claude/scripts/gdoc/gdoc.py <config> --status`
   prints the active gcloud account, the folder, the doc id, and the token's scopes.
   The token must carry a Drive scope. `gcloud auth login` does not grant one; the
   owner runs `gcloud auth login --enable-gdrive-access` once, in a browser, and the
   script names that command when the scope is missing. Never mint, store, or edit a
   credential yourself.
3. **Confirm with the owner, every run.** Show the account, the folder link, and the
   title in one line and ask for a yes. Silence is not a yes. The default account is
   `aakarsh@versable.ai`; a different active account is a stop, not a substitution.
4. **Publish.** `uv run --with markdown --with pygments python3 ~/.claude/scripts/gdoc/gdoc.py <config> --confirm`.
   Unchanged content uploads nothing. The script prints the Doc URL; put it in the
   reply as an absolute link.
5. **Read it back in the browser.** Open the Doc in the owner's Chrome (the
   claude-in-chrome tools; it is signed in), leave View > Text width at Narrow, and
   screenshot the top of a changed tab and a stretch with tables. Say what is on screen
   before judging it: tables flush with the text edges, no blank bands around tables,
   short columns on one line, a gap between a list and the next paragraph. Never change
   the owner's Text width and leave it changed; it is their setting for every Doc. When
   no browser is available, fall back to the PDF export and say the pageless layout
   was not checked. A block that renders wrong is a defect to fix in the spec or the
   script, not a caveat.

To try a change to the script or spec without touching a shared Doc, publish a copy of
a real markdown file to My Drive: a scratch config with `"folder": "root"` and a
`[scratch]` title, read it back as above, then move it to the trash.

To replace a Doc with a fresh one, move `doc_id` and `tabs` in the config aside (as
`previous_doc_id`, `previous_tabs`), publish, check the new Doc, then retire the old one:
`gdoc.py <config> --archive <old doc id> --confirm` prefixes its title (the Drive file
name) with `[Archive]` and moves it to Drive's trash, restorable for 30 days. It refuses
the Doc the config publishes to and any Doc outside the config's folder; without
`--confirm` it only reports what it would do.

## Boundaries

- No Slack, no bot, no cron. The Doc is published when the owner asks, by this skill.
- The Doc is never edited through the Docs API by this skill; content flows one way,
  markdown to Doc. If someone edits the Doc, their edit is lost on the next run and
  the cover says so.
- Index arithmetic is the whole risk in the Docs API: text is appended with a running
  cursor, bullets consume the leading tabs used for nesting, and table cells are
  filled last-cell-first across the whole tab so no insert shifts an index still to
  be used. A 400 "insertion index must be inside the bounds of an existing paragraph"
  means that arithmetic slipped; dump the request list before touching the API.

## Validation

Efficacy dimension: a published Doc reads well to someone who never sees the markdown,
with no hand-fixing by the owner. Checks:

1. **Rendered read-back.** The step 5 screenshot exists for the run and shows tables
   flush with the text at Narrow, no blank bands around tables, short columns on one
   line. Pass: the reply names the screenshot path and what it showed.
2. **Hand edits after publish.** A Doc the owner resized or restyled by hand (a `locked`
   config, a note saying so, or Docs version history showing owner edits right after a
   publish) is rework. Each one is promoted into the spec, never left as a per-doc
   override. Pass: no `spacing`, `fonts` or `tight_tables` override in a config that the
   spec could hold for every Doc.
3. **Owner corrections.** Ledger rows with `corrections > 0`, and notes recording what
   the owner changed, over the last five runs. Pass: no correction repeats one already
   recorded.
4. **Offline tests.** `gdoc.test.py` passes after any script or spec change.

## Runtime notes and ledger

Prepend a `## gdoc:` entry via `bash ~/.claude/skills/shared/prepend-runtime-note.sh gdoc <entry.md>`
when a run taught something, then
`bash ~/.claude/scripts/skill-log.sh record gdoc --task "<gist>" --outcome <accepted|revised|discarded|unknown> --corrections <n>`.
The outcome is the owner's verdict on the published Doc (revised when they asked for
changes or edited it by hand); record `unknown` until they have seen it.

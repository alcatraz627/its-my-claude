---
name: gdoc
description: Publishes a set of markdown files as one Google Doc with one tab per file, in a named Drive folder; re-runs rewrite each tab in place so the link and tabs never change. The markdown is the source of truth. Auth is the signed-in gcloud account with Drive scope; the skill confirms the account and folder with the owner every run. Use when the owner wants a doc set in Google Docs for people who do not read markdown.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invocable: true
argument-hint: "<config.json> [--dry-run | --status]"
---

## Brief

`/gdoc` turns a markdown set into a Google Doc that other people can open, comment on,
and share, without anyone re-keying it. The script at `~/.claude/scripts/gdoc/gdoc.py`
creates the Doc in the folder once, then builds it through the Docs API: a Cover tab
with the title and the list of files, and one tab per markdown file with headings,
paragraphs, bullets, numbered lists, tables, code blocks, bold, italic, inline code
and links recreated. Every later run rewrites each tab in place (tab ids are kept in
the config), so the URL and the tabs are stable and edits made in the Doc are
overwritten. The markdown stays the source of truth.

Tabs are created with the `addDocumentTab` request; the same request exists on
Google's hosted Docs MCP (`https://docsmcp.googleapis.com/mcp/v1`, tool `update_doc`).
The Drive HTML import is not used, because an import lands in a single tab.

The look comes from one shared spec, `~/.claude/scripts/shared/doc-style.json`,
section `gdoc`, read through `~/.claude/scripts/shared/doc_style.py`. Colours are
roles on a Google Docs colour family (`"family": "blue"`, tones `light3` to
`dark3`, plus a `gray` row), so changing the family re-colours every role at the same
relative shade. What the owner ruled on 2026-09-29, each a key in that section:

- **table**: filled header (`light1`) whose dashed border is the header colour, dashed
  body grid two tones lighter (`light3`), body text the darkest tone (`dark3`), first
  column in the lightest tone (`first_col`), every column wide enough for its longest word,
  header row pinned so it repeats on every page. An empty header row (`| | |`) makes a
  header-less card table.
- **table_light**: `<!-- table: light -->` on the line before a table picks the light
  variant for lighter concerns: no fill, no verticals, a dashed header-colour rule under
  the header, dashed `light3` separators, same fonts and colours.
- **code**: one box per block with padding on all four sides (a soft line break keeps
  the block one paragraph) and a `light1` bar on the left; code in JetBrains Mono
  ExtraLight, syntax-coloured by pygments in the tango palette (any language pygments
  knows, markdown included; pandoc uses the same palette in Word). Diagrams share the box
  without the bar; their strokes and arrowheads are drawn in a lighter gray and weight.
  Two boxed blocks in a row get a small spacer, because Google fuses matching borders.
- **rich content**: `![alt](https://…png)` inserts an image (public PNG, JPEG or GIF;
  local files and SVG get their alt text), `text[^1]` with a `[^1]: note` line makes a
  footnote, `[Name](mailto:…)` a person chip, `[Oct 1, 2026](date:2026-10-01)` a date
  chip, a bare `<https://docs.google.com/…>` link a rich-link chip, `---` a thin rule,
  `\newpage` a page break. Objects are placed in a last pass from markers, like tables.
- **callout**: one box, the key line (glyph + LABEL, mono extra bold 8) and the text
  under it (mono 9), both at the same indent, with padding above and below.
- **quote**: Comfortaa italic 9 on the `light3` tint, a Georgia opening mark in the
  bar's colour hanging top-left, air inside the bar.
- **lists**: 1.15 line spacing, no paragraph gaps; nesting by one bullets request per list.
  `- [ ]` items become Google checkbox bullets.
- **inline_code**: a thin space either side in the code tint.

/word-doc renders the same section, by default. Change the spec, never the
document. To check a change by eye without a browser session, export the tab as PDF
(`https://docs.google.com/document/d/<id>/export?format=pdf&tab=<tabId>` with the
gcloud bearer token); that is Google's own render. The config's `cover` file (the README) becomes the Cover
tab, with its links to the other files turned into links to their tabs; the script
writes no generated-on line or any other text that is not in the markdown.
`--samples "<tab>"` writes one sample of every block the skills produce at the end of
a tab the owner keeps as a style guide, replacing the previous samples (from the
"Blocks the document skills produce" heading down); the owner's own samples above it stay.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## gdoc:` entries in
`~/.claude/skills/runtime-notes.md`. Run `python3 ~/.claude/scripts/gdoc/gdoc.py -h`.

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
5. **Read it back.** Export one changed tab as PDF (the export URL above), rasterize it
   with `pdftoppm`, look at the pages, and say what you saw. A block that renders wrong
   is a defect to fix in the spec or the script, not a caveat.

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

## Runtime notes and ledger

Prepend a `## gdoc:` entry via `bash ~/.claude/skills/shared/prepend-runtime-note.sh gdoc <entry.md>`
when a run taught something, then
`bash ~/.claude/scripts/skill-log.sh record gdoc --task "<gist>" --outcome <success|fail> --corrections <n>`.

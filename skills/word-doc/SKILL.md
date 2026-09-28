---
name: word-doc
description: Turns a markdown file, notes, or the conversation into a .docx that reads well in Word and Google Docs, planning the structure from the content and rendering the house typography. Use when someone wants a Word document, a docx, a Google Doc, a memo, a design note, a report, an RCA, or a guide.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
user-invocable: true
argument-hint: "<source.md | topic> [--outline] [--out <dir>] [--paper a4|letter] [--toc] [--check-only <file.docx>]"
---

## Brief

`/word-doc` makes the kind of document people open in Word or Google Docs and expect
to look finished: one typography, a heading ramp, highlighted code in a tinted box,
ASCII diagrams kept intact, banded tables, callouts, a footer with page numbers. The
agent owns what the document says and how it is organised (the planning method is
`references/structure.md`, short, read it every run); the scripts in
`~/.claude/scripts/word-doc/` own everything visual, so two documents made a month
apart look like siblings and nobody opens Word to fix a font.

The theme now lives in the shared document spec, `~/.claude/scripts/shared/doc-style.json`
(section `docx`, plus the shared `callouts`); `make_reference.py` reads it when no
`theme.json` sits beside it. /gdoc reads the same file's `gdoc` section, so a block
added to one skill is added to the spec's `blocks` list and shown in both.

Two looks, one flag. The default (the spec's `docx.look`) is `gdoc`, kept by the owner
on 2026-09-29: the Google Docs look from the spec's `gdoc` section (Comfortaa and Open
Sans, centred title and subtitle, blue-family table with a filled dashed header and a
tinted first column, the light table variant on `<!-- table: light -->`, padded code
boxes with a blue left bar, lighter diagram strokes, two-line callouts, a tinted quote
with a blue Georgia mark, 1.15 lists, a thin rule, one-inch margins). `--look harbor`
renders the 2026-09-01 ruling (Inter, Harbor palette, dotted tables). Date links become
plain text and mail links stay links; the chips exist only in Google Docs.

Fonts: a .docx has no fallback list. `make_reference.py` declares each font's shape in
the font table (body as Calibri's shape, mono as Consolas's, headings as Century
Gothic's), and Word swaps a missing font for the installed one closest to that shape.
Google Docs has all three faces natively, so a Drive import keeps the look. Open Sans
was added to ~/Library/Fonts on 2026-09-29 so the local page check renders true.

## Step 0

Read `~/.claude/skills/GUIDELINES.md`, then the `## word-doc:` entries in
`~/.claude/skills/runtime-notes.md` (`rg -n "^## word-doc" ~/.claude/skills/runtime-notes.md`). Read `~/.claude/skills/word-doc/references/structure.md`. Run
`python3 ~/.claude/scripts/word-doc/render.py -h` once to have the source shape in
front of you; that docstring is the whole contract for DOC.md.

## Usage

```
/word-doc <source.md | topic>       gather → outline → author → render → check → lint → deliver
/word-doc --outline <source.md>     stop after the outline (the plan, in the reply)
/word-doc --check-only <file.docx>  only the LibreOffice page render, for a docx that exists
/word-doc ... --out <dir>           put DOC.md and the .docx there instead of the default
/word-doc ... --paper letter        US Letter instead of A4
/word-doc ... --toc                 force a contents list (the outline decides otherwise)
```

Output, by default: `~/.claude/assets/docs/<YYYYMMDD>-<slug>/` holding `DOC.md`,
`<slug>.docx` and `check/` (the PDF and PNG pages; never commit `check/`). Use
`--out <dir>` when the document belongs next to its source or in a project.
Nothing is uploaded anywhere by default; if the owner wants it in Drive, say where
the file is and let them drop it in, or use a connected Drive tool only when they
ask for that in the same turn.

## The phases, and who owns each

| phase | who | what |
|---|---|---|
| gather | agent | read the source; write the **claim ledger** in the reply: every number, quote and ruling the document will carry, each with where it came from (`file:line`, a message, a test). Ten lines, not a document. |
| outline | agent | the four questions in `structure.md`: archetype and reader's question, level-1 headings with one line each, which pieces become tables / diagrams / code / callouts, contents list yes or no, target length. Ten to fifteen lines in the reply. Stop here on `--outline`. |
| author | agent | write `DOC.md` against the ledger and the outline, in the source shape `render.py -h` documents. Frontmatter `title`, `subtitle`, `author`, `date`. A Summary first when it is over a page. |
| render | script | `python3 ~/.claude/scripts/word-doc/render.py DOC.md -o <slug>.docx --check`. Preflight refuses a diagram over 78 columns, a skipped heading level, an unknown callout, a ragged table, a missing image, a fence option without braces; fix the markdown, never add flags. |
| check | agent | `--check` wrote `check/page-N.png` beside the docx. **Open every page PNG and look**: a wrapped code line, a diagram that lost a column, a table with one word per line, a heading orphaned at a page foot, a callout that glues to a table. Fix in DOC.md and re-render. |
| lint | script + agent | `python3 ~/.claude/scripts/word-doc/lint.py DOC.md`, the prose gate. The loop is fixed, below. |
| deliver | agent | the absolute path of the .docx and DOC.md, the page count, the lint outcome, what the outline chose and why, one line on what to look at first. No "done" verdict; the owner opens it. |

### The prose-gate loop

Same ruling as `/deck` (owner, 2026-08-18): not a heavy review, just enough to
catch offending issues.

1. Run `lint.py DOC.md`.
2. Zero to two findings: fix them, or justify each in one line, and continue.
3. Three or more: fix, **re-run**, fix again, until clean or every leftover
   finding carries a one-line justification in the delivery message.
4. `lint.py` is the whole gate. No `/skeptical-review`, no second reviewer, unless
   the owner asks. A document that will be quoted back (a board memo, an RCA that
   becomes the record) earns a `/validate` pass; offer it in one line, do not
   default to it.

## What the renderer already decides (do not re-decide in DOC.md)

- **The theme is a spec file, not code constants.** Both looks live in
  `~/.claude/scripts/shared/doc-style.json` and `render.py` reads it on every run
  (the Brief above names what each look contains). Change the look by editing the
  spec, never by re-deriving styles in DOC.md; `--accent`, `--font-body`,
  `--font-mono`, `--paper`, `--look` still override per document, and say so in
  the delivery message when you used one.
- Fonts are names the reader's machine must have; see the Brief for how a missing
  one is substituted. `--font-body Calibri --font-mono Consolas` remains the
  every-Windows-machine override.

## Delivering to Google Drive (optional, on request)

The docs land in the owner's Drive, so the skill can deliver there directly:
`bash ~/.claude/scripts/word-doc/gdrive-upload.sh <file.docx> [drive-folder]`
uploads via rclone with `--drive-import-formats docx`, which converts the file
to a native Google Doc on upload. The default folder `Docs` is the ruled
destination (owner, 2026-09-01: the pick was right, and moving inside Drive is
easy, so never ask for a path first). The script auto-detects the configured
remote (currently `versable`; `RCLONE_REMOTE` overrides). Auth was configured
once by the human and the stored refresh token is durable; if the remote is
ever missing the script says exactly what to run and exits, and the OAuth is
never attempted from a tool call. After delivering to Drive, print the link
(`rclone link "<remote>:Docs/<name>.docx"`). Upload when the doc is plainly
bound for Drive or the owner asks; the first confirmed conversion happened
2026-09-01.
- The contents list is static and hyperlinked (levels 1 to 3), not a Word TOC
  field, because the field ships empty to Google Docs and LibreOffice.
- Syntax highlighting is pandoc's, 160+ languages, `tango` by default.
- `\newpage` on its own line is a page break. A caption on a code block or diagram
  is `{.python caption="Listing 1. ..."}`; on a table it is a `Table:` line before it.
- Table columns are sized from their content (longest cell, capped, and every
  column gets its longest word unbroken). Unequal dash counts in the separator row
  (`|---|-------|`) override that when a table needs a hand-set shape.

## Checking the result is the agent's job, not the owner's

`--check` renders through LibreOffice, which substitutes fonts, so the PNGs show
layout and structure faithfully and typography approximately. One LibreOffice
quirk to read past: it keeps a heading, its first paragraph and a table that
follows together more eagerly than Word does, so a half-empty page before
"heading + short paragraph + table" in the PNG is usually the previewer, not the
document. A half-empty page before a diagram or code block is real: those blocks
do not split, so move a short block ahead of them or accept the gap. A code line that wraps
in the PNG at 84 columns should fit in Word at the same size (Consolas is narrower
than the substitute LibreOffice picks); a line that wraps at 100 wraps everywhere. Look at the pages for what no gate can measure: does the
document open with its point, do the headings read as a table of contents on their
own, is the one callout per page the one that matters.

## Validation Examples

### Example: a design note from a plan file

**Scenario:** `/word-doc docs/plan/22-split-pools.md`, a 400-line plan with numbers, two options, and a code sketch.
**Expected behavior:**

- [ ] The reply carries a claim ledger before the outline
- [ ] The outline names the archetype (design note) and the reader's question, and says which pieces become the options table, the pipeline diagram, the code listing
- [ ] `DOC.md` opens with a Summary section; the options are a table, not prose
- [ ] `render.py --check` runs and the agent reports looking at each page
- [ ] `lint.py` runs and findings are fixed or justified in the delivery message

### Example: a topic, no source file

**Scenario:** `/word-doc "RCA for the 2026-08-12 ingest outage"`, with the facts in the conversation.
**Expected behavior:**

- [ ] The ledger cites the conversation turns or files the facts came from
- [ ] The outline picks the RCA archetype: Summary with impact, duration, cause; Timeline as a table; Root cause; What we are changing
- [ ] No number appears in DOC.md that is not in the ledger

### Example: preflight refuses the source

**Scenario:** `DOC.md` has an 88-column ASCII diagram and a heading that jumps from level 1 to level 3.
**Expected behavior:**

- [ ] `render.py` exits 1 with both errors named with line numbers
- [ ] The agent fixes DOC.md (wraps the diagram, fixes the level) and re-renders; no flag is added to bypass the gate

## Runtime notes

After each real document, prepend a `## word-doc:` entry to the shared
`~/.claude/skills/runtime-notes.md` with `bash ~/.claude/skills/shared/prepend-runtime-note.sh word-doc <entry.md>`
(GUIDELINES.md §7): what the outline became, what the page check caught, what lint
caught. Then record the run:

```bash
bash ~/.claude/scripts/skill-log.sh record word-doc --task "<slug>" --outcome unknown \
  --corrections 0 --note "archetype=<x> pages=<n> lint=<n findings, n justified> check=looked"
```

## See also

- `/deck` is the sibling for slides; same split (agent writes the .md, scripts own the look)
- `/generate-pdf` and `/create-report` are the PDF and HTML siblings; this one is for documents people edit and comment on
- `conventions/ascii-diagrams.md` for the diagram rules the Diagram box assumes
- `rules/audience-aware-writing.md` and `conventions/language-quality.md` for the voice the lint enforces the mechanical half of

---
name: generate-pdf
description: Converts a markdown file to a styled PDF with 4 style variants (default, professional, academic, compact), optional cover page, TOC generation, and landscape mode. Output lands in the same directory as the input file.
allowed-tools: Bash, Read
user-invokable: true
argument-hint: "<file.md> [--style <name>] [--open] [--toc] [--cover] [--landscape]"
---

## Brief

Generates a polished PDF from any markdown file. Four style variants for different contexts:
`default` (dark code blocks, blue accents), `professional` (serif headings, client-facing),
`academic` (LaTeX-inspired, justified), `compact` (maximum density). Supports cover pages,
auto-generated TOC, and landscape mode for wide tables.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/generate-pdf <file.md>
/generate-pdf <file.md> --open
/generate-pdf <file.md> --style professional
/generate-pdf <file.md> --style academic --toc --cover
/generate-pdf <file.md> --landscape
```

| Argument | Type | Description |
|---|---|---|
| `<file.md>` | Required | Absolute or relative path to the markdown file |
| `--style <name>` | Optional | Visual style: `default`, `professional`, `academic`, `compact`. Default: `default` |
| `--open` | Optional | Open the generated PDF immediately after creation |
| `--toc` | Optional | Auto-generate a Table of Contents from headings (requires 3+ headings) |
| `--cover` | Optional | Prepend a centered title/date cover page |
| `--landscape` | Optional | Use landscape orientation (good for wide tables) |

**Styles:**

| Style | Best for | Highlights |
|---|---|---|
| `default` | Technical docs, internal reports | Dark code blocks, blue accents, compact margins |
| `professional` | Client-facing docs, proposals | Serif headings, wider margins, light table headers |
| `academic` | Papers, research, formal docs | LaTeX-inspired, justified text, light syntax theme |
| `compact` | Dense reference material, cheat sheets | Smallest fonts/margins, maximum content per page |

---

## Workflow

### Phase 1 — Resolve Input

1. Confirm the provided path exists and ends in `.md`.
2. Derive the output path: same directory, same stem, `.pdf` extension.
3. Print the plan:
   ```
   Input:  /path/to/file.md
   Output: /path/to/file.pdf
   ```

### Phase 2 — Generate

Run the generation script with applicable flags:

```bash
python3 ~/.claude/skills/generate-pdf/generate_pdf.py <input.md> [--style <name>] [--toc] [--cover] [--landscape] [--open]
```

Examples:
```bash
# Default style
python3 ~/.claude/skills/generate-pdf/generate_pdf.py /path/to/doc.md

# Professional with cover and TOC
python3 ~/.claude/skills/generate-pdf/generate_pdf.py /path/to/doc.md --style professional --cover --toc --open

# Compact landscape for wide data tables
python3 ~/.claude/skills/generate-pdf/generate_pdf.py /path/to/doc.md --style compact --landscape
```

**Style selection guidance** — if the user didn't specify a style, pick based on content:
- API docs, READMEs, technical specs → `default`
- Client proposals, business docs, handoff documents → `professional`
- Research papers, formal reports → `academic`
- Cheat sheets, quick-reference cards, dense data → `compact`
- Wide tables or dashboards → add `--landscape`
- Documents with 4+ sections → add `--toc`

The script:
- Loads CSS from `~/.claude/skills/generate-pdf/styles/<name>.css` (or embedded default)
- Calls `npx --yes md-to-pdf` with style-appropriate highlight theme
- If `--cover`: prepends a centered title/date cover page
- If `--toc`: auto-generates Table of Contents from h2-h4 headings
- If `--landscape`: sets landscape orientation in PDF options
- Passes style-specific margins
- Cleans up all temp files after completion
- Outputs the PDF to the same directory as the input

### Phase 3 — Verify

After the script exits:
- Confirm the `.pdf` file exists at the expected path
- Report file size
- If `--open` was passed, the script will have opened it automatically

### Phase 4 — Report

Print a compact summary:

```
  ✓ PDF generated
  Input:  /path/to/file.md
  Output: /path/to/file.pdf  (142.3 KB)
```

If the script failed, print the error and suggest checking:
- Whether `npx` and Node.js are installed
- Whether the input file has any unusual characters or encoding issues

---

## Design Decisions

The CSS stylesheet embedded in `generate_pdf.py` applies:

| Element | Style |
|---|---|
| Page | A4, 14mm top/bottom, 16mm left/right |
| Body font | System sans-serif, 10.5pt, 1.58 line-height |
| H1 | 20pt bold, bottom border in `#3b82f6` (blue) |
| H2 | 13.5pt, left border in `#3b82f6`, page-break-after: avoid |
| H3 | 11pt, muted slate |
| Code blocks | `#0f172a` background, 8pt mono, left blue border |
| Inline code | Light gray pill, dark text |
| Tables | Dark navy header, striped rows, 9.5pt |
| Blockquotes | Gray left border, italic, light bg |
| Syntax theme | atom-one-dark (via md-to-pdf highlight.js) with custom token overrides |

To modify the design, edit the `CSS` constant in `generate_pdf.py`.

---

## Notes

- Requires Node.js + `npx`. `md-to-pdf` is auto-downloaded on first run via `npx --yes`.
- On first run, `npx --yes md-to-pdf` may take 10–30 seconds to download Chromium.
- The output PDF is always in the same directory as the input — this is intentional.
- For very long documents with many code blocks, page breaks are hinted with `page-break-inside: avoid` on `pre`, `table`, and `blockquote`. This may cause large gaps near page boundaries — acceptable for technical documents.
- LinkedIn and external URLs in the markdown will appear as blue text (non-clickable in most PDF readers without annotation support).

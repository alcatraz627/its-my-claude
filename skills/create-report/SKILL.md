---
name: create-report
description: Takes a markdown file and generates a polished, self-contained HTML report with a clean UI. Supports 13 visual styles (default, notion, dashboard, magazine, terminal, data-table, feed, corporate, academic, neon, minimal, kanban, slide). The LLM parses markdown into structured JSON, then a Node.js script renders HTML in the chosen style. Use when you want to convert any markdown document into a browsable HTML file.
allowed-tools: Read, Write, Bash
user-invokable: true
argument-hint: "<input_markdown_path> [--style <name>] [--all-styles]"
---

## Brief

Converts any markdown file into a polished, self-contained HTML report with syntax highlighting, a navigation sidebar, and dark theme — no external dependencies required.

# Create Report Skill

Converts a markdown file into a polished, self-contained HTML report.

**Division of labor:**

- **LLM**: reads the markdown, parses it into a structured JSON document (headings, tables, code blocks, lists, etc.)
- **Node.js script**: receives the JSON and renders the complete, styled, self-contained HTML file

## Usage

```
/create-report <input_markdown_path> [--style <name>]
/create-report styles list
/create-report styles add
/create-report styles update <name>
/create-report styles delete <name>
```

**Arguments:**

- `input_markdown_path` (required): Path to the input markdown file (e.g. `.claude/project-index.md`)
- `--style <name>` (optional): Visual style for the report. Default: `default`. Run `/create-report styles list` to see all available styles.

**Subcommands:**

- `styles list` — List all available styles with descriptions. Runs `bash .claude/skills/create-report/scripts/list-styles.sh`.
- `styles add` — Interactively create a new custom style. The agent scaffolds `styles/<name>/` with `meta.json`, `template.ts`, `style.css`, and `style.js`.
- `styles update <name>` — Modify an existing style. The agent reads the current style files and applies requested changes.
- `styles delete <name>` — Remove a custom style (not allowed for built-in styles).

**Available styles:**

| Style        | Description                                                       |
| ------------ | ----------------------------------------------------------------- |
| `default`    | Dark sidebar report with accent colors, font/color/width pickers  |
| `notion`     | Clean, minimal Notion-style with cards and whitespace             |
| `dashboard`  | Dark analytics dashboard with metric cards and status pills       |
| `magazine`   | Editorial magazine layout with serif typography and hero header   |
| `terminal`   | Green-on-black retro terminal with CRT scanlines                  |
| `data-table` | Spreadsheet layout optimized for tables and structured data       |
| `feed`       | Social feed layout for narrative data — timeline cards            |
| `corporate`  | Formal corporate/legal report — print-ready, numbered sections    |
| `academic`   | LaTeX-inspired academic paper with serif fonts, numbered sections |
| `neon`       | Cyberpunk neon-glow dark theme with gradient accents              |
| `minimal`    | Ultra-clean reading-focused layout with maximum whitespace        |
| `jupyter`    | Jupyter notebook with executable-style cells                      |
| `slide`      | Presentation-style with full-viewport sections, arrow key nav     |

**Specific Templates (Reference Library):**

One-off, purpose-built HTML reports are cataloged in `specific-templates.json` — not reusable with arbitrary markdown, but tagged with features, style, and vibe for design reference. Use these as inspiration when creating new styles or custom reports. Run `/create-report specific-templates` to list them.

**Output:** Always written to `.claude/output/<YYYYMMDD-HHMM>-<purpose>/` as a single self-contained HTML file with CSS and JS inlined:

- `index.html` — the complete report (CSS and JS embedded inline, no external local dependencies)
- `data.json` — the parsed JSON data (enables zero-Claude restyling via `restyle.sh`)

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the **file lock
protocol** — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

## Argument Handling

**First**, check if the user invoked a `styles` subcommand:

- If the argument starts with `styles list` → run `bash .claude/skills/create-report/scripts/list-styles.sh` and stop.
- If the argument starts with `styles add` → scaffold a new style directory under `styles/<name>/` with `meta.json`, `template.ts`, `style.css`, `style.js`. Ask the user for the style name and description, then generate the files.
- If the argument starts with `styles update <name>` → read the existing style files, ask the user what to change, and apply edits.
- If the argument starts with `styles delete <name>` → verify it's not a built-in style, confirm with the user, then remove the directory.

**For report generation**, parse flags:

- `--style <name>` — visual style to use (default: `default`)
- `--all-styles` — generate all 8 styles in one shot; mutually exclusive with `--style`

Then compute the output directory and check if it already exists.

1. Get the current datetime stamp:

   ```bash
   date '+%Y%m%d-%H%M'
   ```

2. Derive a short purpose slug from `input_markdown_path`: take the filename without extension, lowercase it, replace spaces/underscores with `-`, truncate to 24 chars.
   - Example: `project-index.md` → `project-index`
   - Example: `Architecture Overview.md` → `architecture-overview`

3. Compose:

   ```
   output_dir  = .claude/output/<datetime>-<purpose>/
   output_html = .claude/output/<datetime>-<purpose>/index.html
   ```

   **Exception — when CWD is `~/.claude` itself:** the default relative path would
   resolve to `~/.claude/.claude/output/...` (broken double-nest; a PreToolUse hook
   blocks it). Redirect instead to:

   ```
   output_dir  = ~/.claude/assets/reports/<datetime>-<purpose>/
   output_html = ~/.claude/assets/reports/<datetime>-<purpose>/index.html
   ```

   Detect with `[ "$(pwd)" = "$HOME/.claude" ]` before composing, or check the composed
   path for `/.claude/.claude/` and rewrite.

4. Check whether the output directory already exists:

   ```bash
   ls <output_dir> 2>/dev/null
   ```

5. **If it exists** — skip Steps 1–6 entirely. Jump directly to Step 7 (open it in Chrome). Print:

   ```
   ✓ Report already exists: <output_html>
     Skipping generation — opening existing file.
   ```

6. **If it does not exist** — continue to the full generation workflow below.

---

## Workflow

### Step 1: Read the Input Markdown

Use the Read tool to load the full markdown content from `input_markdown_path`.

### Step 1.5: Pre-Parse Structured Data (before LLM JSON step)

Before the LLM walks the markdown to produce JSON, perform a **pre-processing pass** to handle structured data that the LLM would otherwise parse slowly and error-prone:

**1. Detect fenced data blocks** — scan for fenced code blocks with language tags:
- `` ```csv `` → parse into table headers + rows using `mcp__file-tools__read_tabular` or Python's csv module
- `` ```json `` → parse with `JSON.parse()` — if it's an array of objects, convert to table block; if scalar/nested, keep as code block
- `` ```yaml `` or `` ```toml `` → parse into structured data via `mcp__file-tools__read_structured`

**2. Replace data blocks in the markdown** — before handing to the LLM, replace each parsed data block with a marker:
```
<!-- DATA_TABLE_1: headers=["Name","Value","Status"], rows=[...] -->
```
The LLM then converts these markers directly to `table` blocks in the JSON instead of parsing raw CSV/JSON text.

**3. Detect input content profile** — categorize the input:
- **Prose-heavy** (>70% paragraphs, <30% tables/code): suggest `default`, `notion`, `magazine`, `minimal`
- **Data-heavy** (>50% tables or structured blocks): suggest `data-table`, `dashboard`
- **Code-heavy** (>50% code blocks): suggest `terminal`, `jupyter`
- **Narrative/timeline** (date patterns, sequential events): suggest `feed`
- **Formal** (numbered sections, citations, abstract): suggest `academic`, `corporate`

Print the detected profile and suggestion:
```
Content profile: data-heavy (62% tabular content, 8 tables detected)
Suggested style: data-table (override with --style)
```

If no `--style` was specified and the profile has a strong signal (>60% in one category), **auto-select** the suggested style. Otherwise keep `default`.

**4. Large table optimization** — for tables with >20 rows:
- Add `<!-- LARGE_TABLE: N rows -->` annotation so the renderer can apply scrollable container styling
- Consider splitting into multiple page-sized chunks for `corporate` and `academic` styles (print-friendly)

### Step 2: Parse into Structured JSON (LLM's job)

Walk through the markdown and produce a JSON object matching the schema below. This is where the LLM applies intelligence — understanding what content is a table vs a list, grouping subsections under their parent sections, extracting inline formatting, and building the navigation tree.

**JSON Schema:**

```json
{
  "title": "string — from the first # H1 heading",
  "subtitle": "string — from metadata like **Project:** or the second line under H1, or null",
  "generated": "string — from **Generated:** metadata line, or today's date",
  "nav": [
    {
      "id": "string — slug of heading text",
      "text": "string — heading text",
      "level": 2,
      "children": [{ "id": "string", "text": "string", "level": 3 }]
    }
  ],
  "sections": [
    {
      "id": "string — slug of heading text",
      "heading": "string",
      "level": 2,
      "blocks": ["...see block types below..."]
    }
  ]
}
```

**Block types** (used inside `sections[].blocks` and inside subsection blocks):

```json
{ "type": "paragraph", "html": "string — inline markdown converted to HTML spans" }

{ "type": "hr" }

{ "type": "code", "lang": "string — bash/ts/json/etc, or empty string", "content": "string — raw code text" }

{ "type": "table", "headers": ["col1", "col2"], "rows": [["a", "b"], ["c", "d"]] }

{ "type": "ul", "items": ["string — may contain inline HTML"] }

{ "type": "ol", "items": ["string — may contain inline HTML"] }

{ "type": "blockquote", "html": "string — inline markdown converted to HTML" }

{
  "type": "subsection",
  "id": "string",
  "heading": "string",
  "level": 3,
  "blocks": ["...nested blocks (no further subsection nesting needed below H4)..."]
}

{
  "type": "subsubsection",
  "id": "string",
  "heading": "string",
  "level": 4,
  "blocks": ["...nested blocks..."]
}

{
  "type": "tree",
  "nodes": [
    {
      "label": "string — directory or file name",
      "desc": "string — optional short description (optional)",
      "children": ["...recursive TreeNode objects..."]
    }
  ]
}
{ "type": "math", "latex": "string — raw LaTeX expression", "display": true }
```

**Mathematical notation (`math` blocks):**

- Use `math` blocks for equations, formulas, and mathematical expressions. The `latex` field contains raw LaTeX (e.g., `P(A) = \\frac{m_A^r}{m_A^r + m_B^r}`).
- `display: true` (default) renders as a centered block equation. `display: false` renders inline-sized.
- Inline math in paragraph `html` fields is also supported: use `$...$` delimiters (e.g., `"html": "The probability is $P(A) = 0.52$ for player A"`). KaTeX auto-render processes these client-side.
- Do NOT HTML-escape the LaTeX — use raw LaTeX syntax. Backslashes need JSON escaping only (e.g., `\\frac` not `&amp;frac`).
- Common LaTeX: `\\frac{a}{b}`, `\\sum_{i=0}^{n}`, `\\alpha`, `\\beta`, `\\cdot`, `\\times`, `\\leq`, `\\geq`, `\\approx`, `\\text{label}`.

**When to use `tree` vs `ul`:**

- Use `tree` for **hierarchical directory structure or component trees** — it renders as expandable `<details>/<summary>` nodes with indented children
- Use `ul` for flat lists, dependency lists, or bullet points
- Top-level nodes in a `tree` block are expanded by default; child nodes are collapsed

**Parsing directory trees into `tree` blocks:**
When you encounter an ASCII directory tree (lines starting with `├──`, `└──`, `│`, etc.) or indented file paths in the markdown, convert it to a `tree` block rather than a `code` block. Walk the indentation levels to build the `children` arrays. Strip tree-drawing characters (`├──`, `└──`, `│`) from labels.

**Inline markdown → HTML conversion rules** (apply when building `html` fields):

- `**text**` → `<strong>text</strong>`
- `*text*` → `<em>text</em>`
- `` `code` `` → `<code>code</code>`
- `[label](url)` → `<a href="url">label</a>`
- Plain text → as-is

**Slugification** (for all `id` fields):

- Lowercase, replace spaces with `-`, strip non-alphanumeric except `-`
- Example: `"Key Configuration Files"` → `"key-configuration-files"`
- Ensure uniqueness by appending `-2`, `-3` etc. for duplicates

### Step 3: Write the JSON to a Temp File

Write the parsed JSON to `.claude/report-data.tmp.json` using the Write tool.

### Step 4: Locate the Generator Script

The HTML generator is a static TypeScript file that lives alongside this skill. Do **not** write or modify it during a run — it is source-controlled and reused on every invocation.

**Script path (relative to the frontend root):**

```
.claude/skills/create-report/generate-html.ts
```

Verify it exists before proceeding:

```bash
ls .claude/skills/create-report/generate-html.ts
```

If the file is missing, stop and tell the user: `"generate-html.ts not found at .claude/skills/create-report/. The skill files may be missing."`

### Step 5: Run the Generator (with retry on error)

Run the generator via `npx tsx`, capturing stderr so errors can be diagnosed.

**Single style (default):**

```bash
npx tsx .claude/skills/create-report/generate-html.ts \
  .claude/report-data.tmp.json \
  <output_html> \
  --style <style_name> 2>&1
```

If no `--style` was specified by the user, omit the flag (defaults to `default`).

**All styles (`--all-styles` flag):**

```bash
npx tsx .claude/skills/create-report/generate-html.ts \
  .claude/report-data.tmp.json \
  <output_html> \
  --all-styles 2>&1
```

This generates all 8 styles into `<outputDir>/<style>/index.html` subdirectories and writes a launcher `index.html` at the root. Open `<output_dir>/index.html` in the browser to browse all styles.

The script produces a single self-contained `index.html` with CSS and JS inlined. It also writes `data.json` (the parsed JSON for zero-Claude re-rendering) alongside the HTML.

**Retry logic — attempt up to 3 times:**

On each attempt:

1. Run the command above
2. If exit code is **0** → success, proceed to Step 6
3. If exit code is **non-zero**:
   - Read the full stderr/stdout output (it contains a descriptive validation error message including the exact field path and what was wrong)
   - Read `.claude/report-data.tmp.json` to inspect the current JSON
   - Fix the specific field(s) cited in the error — do not rebuild the whole JSON from scratch
   - Overwrite `.claude/report-data.tmp.json` with the corrected JSON using the Write tool
   - Increment attempt counter and retry

**After 3 failed attempts**, stop and report to the user:

```
✗ Failed to generate HTML after 3 attempts.
Last error: <paste the final stderr here>
The JSON data has been left at .claude/report-data.tmp.json for inspection.
```

**Common errors and fixes:**

| Error message pattern                               | Fix                                                                                                     |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `Block is missing required string field "type"`     | Add `"type"` field to the block object                                                                  |
| `Invalid block type "xyz"`                          | Change to one of: paragraph, hr, code, table, ul, ol, blockquote, math, subsection, subsubsection, tree |
| `"math" requires string "latex"`                    | Add `"latex": "..."` with the raw LaTeX expression                                                      |
| `"tree" requires a "nodes" array`                   | Add `"nodes": []` to the tree block                                                                     |
| `Tree node requires a non-empty string "label"`     | Add or fix the `"label"` field on the tree node                                                         |
| `"code" block requires a string field "lang"`       | Add `"lang": ""` (empty string is valid)                                                                |
| `"table" block requires "headers" to be a string[]` | Ensure headers is `["Col1", "Col2"]` not objects                                                        |
| `Each row must be an array of strings`              | Ensure rows is `[["a", "b"], ["c", "d"]]`                                                               |
| `"ul"/"ol" block requires "items" to be a string[]` | Ensure items is `["item1", "item2"]`                                                                    |
| `requires a non-empty string "id"`                  | Add or fix the `"id"` field (non-empty slug string)                                                     |
| `Root object requires a "nav" array`                | Add top-level `"nav": []`                                                                               |
| `JSON parse error`                                  | Fix JSON syntax (missing comma, unclosed bracket, etc.)                                                 |

### Step 6: Confirm Success and Point to Style Switcher

After a successful generation, print:

```
✓ Report generated: <output_html>

  Switch styles without Claude — no re-parse needed:
    bash <output_dir>/restyle.sh terminal
    bash <output_dir>/restyle.sh magazine
    bash <output_dir>/restyle.sh notion
    ... (any of: default, notion, dashboard, magazine, terminal, data-table, feed, corporate)

  Or open the report and use the style picker in the toolbar (shows ready styles
  and copy-able restyle commands for styles not yet generated).
```

Do **not** ask the user to choose a style via `AskUserQuestion` — the `restyle.sh` script and the in-browser style picker handle this without any Claude invocation.

### Step 7: Clean Up Temp Files

```bash
trash .claude/report-data.tmp.json
```

### Step 8: Open Report

Open the generated report (or launcher page if `--all-styles`):

```bash
open -a "Google Chrome" <output_html>
```

Print to terminal:

```
✓ HTML report saved: <output_html> (style: <style>)
  Opened in Google Chrome.
```

## Notes

- The LLM's job is **parsing and structuring** — turning messy markdown into clean JSON. Invest effort here so the script output is accurate.
- `generate-html.ts` is **pure rendering** — it reads the JSON and outputs a single self-contained HTML file (CSS and JS inlined via `inlineAssets()`). It has no intelligence about content. Never modify it during a skill run.
- Inline markdown in `html` fields must be pre-converted by the LLM before being placed in the JSON — the TypeScript script does not parse markdown.
- On validation errors, the script prints the exact field path (e.g. `[sections[2].blocks[0]]`) and what was wrong, making it easy to do a targeted fix rather than regenerating the whole JSON.
- `npx tsx` works without any prior `npm install` step since `tsx` is available as an npx package. If the project has `tsx` in devDependencies (this one does), it will use the local version.
- The generated HTML includes **Open Graph and Twitter Card meta tags** (`og:title`, `og:description`, `og:type`, `twitter:card`, `twitter:title`, `twitter:description`). The description uses `subtitle` if present, otherwise falls back to the stats summary (e.g. "8 sections · 3 tables").

## Related Skills

- `/project-index` — Generates the markdown that feeds into this skill
- Full pipeline: `/project-index` → auto-calls `/create-report .claude/project-index.md`

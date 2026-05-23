# /generate-pdf — Usage Guide

## What it does

Converts a markdown file to a compact, styled PDF with dark code blocks, blue-accent headings, clean tables, and readable typography. Output goes to the same directory as the input, same filename, `.pdf` extension.

## Usage

```
/generate-pdf <file.md>
/generate-pdf <file.md> --open
```

| Argument | Type | Description |
|---|---|---|
| `<file.md>` | Required | Path to the markdown file |
| `--open` | Optional | Open the PDF immediately after generation |

## Examples

### Example 1: Generate a PDF for a candidate's interview questions

```
/generate-pdf "resumes/Mar 24, 2026 Rahul Raghunath Bodanki/interview-questions.md"
```

Produces `interview-questions.pdf` in the same folder.

### Example 2: Generate and open immediately

```
/generate-pdf docs/architecture.md --open
```

Generates the PDF and opens it in the system default PDF viewer.

### Example 3: Generate candidate notes

```
/generate-pdf "resumes/Mar 24, 2026 John Doe/candidate-notes.md"
```

Produces a compact notes PDF ready to print or share with an interviewer.

## Caveats

- Requires Node.js and `npx`. First run downloads Chromium (~200MB) via `md-to-pdf` — this is a one-time cost.
- Output path is always `<same-dir>/<same-stem>.pdf` — not configurable by design.
- Very long code blocks may cause visual gaps near page boundaries (page-break-inside: avoid is set).
- LinkedIn and GitHub URLs appear as styled blue text but may not be clickable in all PDF readers.

## Dependencies

| Dependency | Type | Notes |
|---|---|---|
| `generate_pdf.py` | Script | At `~/.claude/skills/generate-pdf/generate_pdf.py` |
| Node.js + npx | Runtime | Required for `md-to-pdf` |
| md-to-pdf 5.x | npm package | Auto-downloaded via `npx --yes` |

## Customizing the design

Edit the `CSS` constant in `~/.claude/skills/generate-pdf/generate_pdf.py`.

Key variables to tweak:
- `@page { margin }` — page margins
- `body { font-size }` — base font size
- `h1, h2` — heading styles and accent color (`#3b82f6` is the current blue)
- `pre { background }` — code block background (`#0f172a` = dark navy)
- Font family in `code:not(pre code)` and `pre code`

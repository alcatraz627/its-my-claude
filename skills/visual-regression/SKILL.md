---
name: visual-regression
description: Captures baseline screenshots via Playwright MCP and compares against later snapshots to detect visual regressions — pixel-diff reports with highlighted change regions.
allowed-tools: Read, Write, Bash, Glob, Grep
user-invokable: true
argument-hint: "<baseline | compare | report> <url | path>"
---

## Brief

Playwright-based visual regression testing. Captures baseline screenshots of web pages,
then compares future snapshots to detect unintended visual changes. Produces diff images
with highlighted change regions and a summary report.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

---

## Usage

```
/visual-regression baseline <url> [--name <label>] [--viewports <sizes>]
/visual-regression compare <url> [--name <label>] [--threshold <pct>]
/visual-regression report [--name <label>]
```

| Subcommand | Description |
| ---------- | ----------- |
| `baseline` | Capture reference screenshots for a URL |
| `compare` | Compare current state against the baseline |
| `report` | Show the latest comparison report |

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--name <label>` | URL slug | Label for this test (groups baselines + comparisons) |
| `--viewports` | `1280,768,375` | Comma-separated viewport widths to capture |
| `--threshold` | `0.1` | Pixel difference threshold (%) — below this is considered passing |

---

## Storage

All screenshots are stored in a project-local directory:

```
.claude/visual-regression/
  <name>/
    baseline/
      1280.png
      768.png
      375.png
      meta.json          # URL, timestamp, viewports
    compare/
      1280.png
      768.png
      375.png
      meta.json
    diff/
      1280-diff.png      # highlighted pixel differences
      768-diff.png
      375-diff.png
      report.json        # per-viewport diff percentages
```

---

## Subcommand: `baseline`

### Phase 1 — Capture

For each viewport width:

1. Use Playwright MCP to navigate to the URL:
   ```
   browser_resize(width, 900)
   browser_navigate(url)
   browser_wait_for("networkidle")
   ```

2. Take a full-page screenshot:
   ```
   browser_take_screenshot(fullPage: true)
   ```

3. Save to `.claude/visual-regression/<name>/baseline/<width>.png`

### Phase 2 — Record Metadata

Write `meta.json`:
```json
{
  "url": "<url>",
  "captured_at": "2026-04-22T14:30:00Z",
  "viewports": [1280, 768, 375],
  "page_title": "<title from page>"
}
```

### Phase 3 — Report

```
  ✓ Baseline captured: <name>
    URL: <url>
    Viewports: 1280px, 768px, 375px
    Screenshots: .claude/visual-regression/<name>/baseline/
```

---

## Subcommand: `compare`

### Phase 1 — Validate

1. Check that a baseline exists for the given name
2. If not: print error and suggest running `baseline` first

### Phase 2 — Capture Current State

Same process as baseline, but save to `compare/` directory.

### Phase 3 — Generate Diffs

For each viewport, compare baseline and current screenshots pixel-by-pixel.

**Using Playwright MCP:**
```
browser_run_code({
  code: `
    // Load both images into canvases and compare pixel data
    // Highlight differences in red overlay
    // Calculate diff percentage
  `
})
```

**Alternative (Python with Pillow):**
```bash
python3 -c "
from PIL import Image, ImageChops
import json

baseline = Image.open('baseline/<width>.png')
current = Image.open('compare/<width>.png')

# Resize to match if needed
if baseline.size != current.size:
    current = current.resize(baseline.size)

diff = ImageChops.difference(baseline, current)

# Calculate diff percentage
pixels = baseline.size[0] * baseline.size[1]
diff_pixels = sum(1 for p in diff.getdata() if max(p[:3]) > 10)
pct = (diff_pixels / pixels) * 100

# Create highlighted diff image
highlight = baseline.copy()
# Overlay red on changed pixels
...
highlight.save('diff/<width>-diff.png')
print(json.dumps({'width': <width>, 'diff_pct': round(pct, 3)}))
"
```

### Phase 4 — Report

Write `diff/report.json`:
```json
{
  "name": "<name>",
  "url": "<url>",
  "compared_at": "2026-04-22T14:35:00Z",
  "threshold": 0.1,
  "results": [
    {"viewport": 1280, "diff_pct": 0.023, "status": "pass"},
    {"viewport": 768, "diff_pct": 2.4, "status": "fail"},
    {"viewport": 375, "diff_pct": 0.0, "status": "pass"}
  ]
}
```

Print:
```
─────────────────────────────────────────────────────
  Visual Regression: <name>
─────────────────────────────────────────────────────

  Threshold: 0.1%

  1280px   ✓ pass   0.023% changed
   768px   ✗ FAIL   2.400% changed
   375px   ✓ pass   0.000% changed

  Diff images:
    .claude/visual-regression/<name>/diff/768-diff.png

─────────────────────────────────────────────────────
```

If any viewport fails: open the diff image for inspection using `Read` tool.

---

## Subcommand: `report`

Read the latest `diff/report.json` for the given name and print the summary. If no comparison
has been run, print the baseline metadata instead.

---

## Notes

- This skill requires Playwright MCP tools to be available (check with `browser_snapshot` test call)
- If Playwright MCP is not connected, fall back to the Python/Pillow approach for diff generation (but cannot capture screenshots)
- The `compare` subcommand is the core value — always capture a baseline first
- Threshold of 0.1% is strict — increase to 0.5% for pages with dynamic content (timestamps, avatars)
- Screenshots are stored locally in `.claude/visual-regression/` — add this to `.gitignore`
- Pairs with `/web-design review` for manual critique — this skill handles automated diffing
- For CI integration, the JSON report format enables programmatic pass/fail checking

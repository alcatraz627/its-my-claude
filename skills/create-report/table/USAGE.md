# /create-report:table — Usage Guide

## What it does

Converts tabular data (CSV, JSON, or inline) into a polished, fully self-contained interactive HTML table page. The agent parses and preprocesses the data, maps your natural-language instructions to generate-table.ts flags, and extends the script if a requested feature is missing.

## Usage

```
/create-report:table <data_source> [instructions]
```

| Argument | Type | Description |
|---|---|---|
| `data_source` | required | Path to CSV/JSON file, or description of inline data |
| `instructions` | optional | Natural-language directives: what columns to show, how to sort, theme, highlighting, export, pagination, etc. |

**Output:** `.claude/output/<YYYYMMDD-HHMM>-<slug>/index.html` — single self-contained HTML, no external deps.

---

## Feature Reference

All features are controlled via flags passed to `generate-table.ts`. The agent maps your instructions to these flags automatically.

| Feature | Flag | Example |
|---|---|---|
| Custom title | `--title` | `--title "Q4 Sales"` |
| Light theme | `--theme light` | (default is dark) |
| Show subset of columns | `--columns` | `--columns "Name,Status,Score"` |
| Default sort | `--sort-by` | `--sort-by "Score:desc"` |
| Live search bar | `--search` | _(boolean flag)_ |
| Pagination | `--pagination N` | `--pagination 50` |
| Export CSV | `--export csv` | |
| Export JSON | `--export json` | |
| Both exports | `--export both` | |
| Row highlighting | `--highlight-rules` | see below |
| Freeze columns | `--frozen-columns N` | `--frozen-columns 2` |
| Column types | `--column-types` | `'{"Score":"number","Status":"badge"}'` |
| Number format | `--number-format` | `"$0,0.00"` or `"0,0.##"` or `"0%"` |
| Date format | `--date-format` | `"MMM D, YYYY"` |
| Striped rows | `--striped` | _(boolean flag)_ |
| Compact rows | `--compact` | _(boolean flag)_ |
| Row numbers | `--row-numbers` | _(boolean flag)_ |
| Caption / subtitle | `--caption` | `--caption "As of Q4 2025"` |
| Column widths | `--column-widths` | `'{"Name":"200px","ID":"60px"}'` |
| Max cell truncation | `--max-cell-width` | `--max-cell-width "300px"` |

**Column types:** `text` (default) · `number` · `date` · `boolean` · `badge` · `url` · `email` · `code`

**Highlight rule operators:** `eq` (default) · `not` · `lt` · `gt` · `lte` · `gte` · `contains` · `startsWith` · `endsWith`

**Named highlight colors:** `red` · `yellow` · `green` · `blue` · `purple` · `orange` · `cyan` · `pink`

---

## Examples

### Example 1: Basic sales report

```
/create-report:table sales.csv "title: Q4 Sales, search, paginate 25, sort by Revenue descending"
```

Generates a dark-themed table with live search, 25 rows per page, and Revenue pre-sorted descending.

---

### Example 2: Typed columns with highlighting and export

```
/create-report:table users.json "show Name, Email, Status, Plan, MRR columns.
Status is a badge. MRR is currency. Highlight churned users in red, trial users in yellow.
Add export buttons. Striped rows."
```

Generates:
- 5-column table with badge pills for Status, `$0,0.00` formatting for MRR
- Red-highlighted rows where `Status = churned`, yellow where `Status = trial`
- CSV + JSON export buttons
- Alternating row colors

---

### Example 3: Dense ops dashboard with frozen columns

```
/create-report:table deployments.csv "freeze ID and Service columns, show all columns,
compact mode, sort by Timestamp descending, date format 'MMM D HH:mm',
highlight failed deployments in red, light theme"
```

Generates a compact light-themed table with frozen first 2 columns, readable timestamps, and red rows for failures.

---

### Example 4: Data preprocessing + grouping

```
/create-report:table orders.csv "only show orders from 2025. Add a Total column = Price × Quantity.
Group by Region and show total revenue per region. Sort by total revenue descending."
```

The agent handles preprocessing (filter, computed column, aggregation) in Phase 1 before calling the script.

---

## Caveats

- **Data transformation is done by the agent, not the script.** Computed columns, aggregations, and row filtering happen in Phase 1. The `generate-table.ts` script is display-only.
- **Column names are case-sensitive** in all flags. Use exact header names from your data.
- **JSON flag values must use single quotes in shell:** `--column-types '{"Col":"number"}'`
- **Very large datasets (100k+ rows)** will work but the HTML file will be large. Consider filtering or paginating before generating.
- **The script grows over time.** If a feature is added in one session (Phase 3a), it persists and is available in all future sessions. Always check the flag catalog before concluding a feature is missing.
- **Frozen columns require horizontal overflow** to be visible. If the table fits the screen width, frozen column shadows won't be visible (this is correct behavior).

---

## Adding a New Feature to the Script

If you ask for a feature that doesn't exist yet:
1. The agent reads `generate-table.ts` in full
2. Adds the flag to `parseArgs()`, `TableConfig`, the CSS/JS, and the header docs
3. Verifies the script compiles, then re-generates

The feature is now permanent and documented in the script header for all future runs.

---

## Dependencies

| Dependency | Type | Notes |
|---|---|---|
| `GUIDELINES.md` | Shared rules | Read at start of every run |
| `generate-table.ts` | Script | The rendering engine — read its header for current flags |
| `npx tsx` | Runtime | Available as npx package, no install required |
| `Google Chrome` | Browser | Used to open the output (`open -a "Google Chrome"`) |
| `.claude/output/` | Output dir | Created automatically if missing |

## Related Skills

- `/create-report` — Generates structured narrative HTML reports from markdown files (not table data)
- `/project-index` — Generates a markdown project index that can feed into `/create-report`

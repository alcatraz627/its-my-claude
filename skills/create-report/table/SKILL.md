---
name: create-report:table
description: Parses tabular data (CSV/JSON file or inline), maps natural-language instructions to generate-table.ts CLI flags, extends the script if a requested feature is missing, and outputs a self-contained interactive HTML table page with sorting, search, filtering, pagination, theming, type-aware columns, row highlighting, and export.
allowed-tools: Read, Write, Edit, Bash
user-invokable: true
argument-hint: "<data_source> [instructions]"
context: fork
---

## Brief

Converts any tabular data source into a polished, fully interactive HTML table page. The agent handles all data parsing and instruction-to-flag mapping; a static `generate-table.ts` script handles all HTML/CSS/JS rendering. When a request requires a feature not yet in the script, the agent adds it before generating.

---

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
/create-report:table <data_source> [instructions]
```

**Arguments:**

| Argument | Type | Description |
|----------|------|-------------|
| `data_source` | required | Path to a CSV or JSON file, OR a description of inline data to use |
| `instructions` | optional | Natural-language directives: columns to show, sort order, theme, filters, pagination, export, highlighting, etc. |

**Output:** A single self-contained `index.html` file written to `.claude/output/<YYYYMMDD-HHMM>-<slug>/`.

---

## Argument Handling

**Before any other work**, compute the output directory and check if it already exists.

1. Get the current datetime stamp:
   ```bash
   date '+%Y%m%d-%H%M'
   ```

2. Derive a slug from `data_source`: take the filename (without extension), lowercase it,
   replace spaces/underscores/slashes with `-`, truncate to 24 chars.
   - `sales_report.csv` → `sales-report`
   - `users.json` → `users`
   - "inline department data" → `inline-department`

3. Compose:
   ```
   output_dir  = .claude/output/<datetime>-<slug>/
   output_html = .claude/output/<datetime>-<slug>/index.html
   ```

4. If the output directory already exists → skip generation, open the existing file, print:
   ```
   ✓ Report already exists: <output_html>
     Skipping generation — opening existing file.
   ```

---

## Workflow

### Phase 1 — Data Ingestion & Analysis

**Goal:** Produce a normalized `table-data.tmp.json` in the standard input format.

**Standard format:**
```json
{
  "headers": ["Col1", "Col2", "Col3"],
  "rows": [["val1", "val2", "val3"], ...],
  "meta": {
    "source": "original-filename.csv",
    "count": 42
  }
}
```

#### 1a. Read the data source

- If `data_source` is a file path → use the Read tool to load it.
- If `data_source` is a description of inline data → the user likely wants you to generate or use data from context (ask for clarification if truly ambiguous).

#### 1b. Parse the format

**CSV files:**
- The first row is the header row.
- Subsequent rows are data rows.
- Handle: quoted fields with commas, empty values (use empty string `""`), trailing whitespace in headers (trim it).
- Walk the file and produce `headers: string[]` + `rows: string[][]`.

**JSON files — three possible shapes:**
1. **Array of objects:** `[{"name":"Alice","age":30}, ...]`
   → headers = `Object.keys(data[0])`, rows = `data.map(obj => headers.map(h => String(obj[h] ?? '')))`
2. **Already in standard format:** `{"headers":[...],"rows":[...]}` → use as-is.
3. **Array of arrays:** `[["Alice",30],["Bob",25],...]`
   → If first row looks like headers (all strings, no numeric-looking values), use it as headers.
   → Otherwise generate generic headers: `Col1`, `Col2`, etc.

**Other formats:** If the file is `.tsv`, use tab as delimiter. If the format is unclear, inspect the first few lines and infer.

#### 1c. Detect column types (optional but valuable)

Scan the first 20 rows for each column and infer likely types:
- All values are parseable as numbers → candidate for `"number"` type
- All values match ISO date patterns (`YYYY-MM-DD`, `YYYY-MM-DDTHH:mm:ss`, etc.) → candidate for `"date"` type
- All values are `true`/`false`/`0`/`1`/`yes`/`no` → candidate for `"boolean"` type
- Low cardinality (< 10 unique values across all rows) → candidate for `"badge"` type
- All values look like URLs (start with `http://` or `https://`) → `"url"` type
- All values look like emails (contain `@`) → `"email"` type

Store these inferences; they'll inform the `--column-types` flag in Phase 2.

#### 1d. Preprocessing (if instructions require it)

Apply any transformations the instructions request **before** writing the JSON:
- **Column rename:** Change headers in the `headers` array.
- **Computed column:** Add a new header and compute values per row (e.g., "add a Total column = Price × Quantity").
- **Data filtering:** Remove rows that don't match a condition (e.g., "only show rows where Status = Active").
- **Aggregation:** If the instruction asks to "group by X", reduce rows to one row per unique X value with aggregated sub-columns.
- **Type coercion:** Strip currency symbols, percent signs, commas from number columns.
- **Date normalization:** Convert inconsistent date formats to ISO 8601.

**Do preprocessing in this step (Phase 1), not via flags** — the generate-table.ts script only handles display, not data transformation.

#### 1e. Write data JSON

Write the normalized data to `.claude/table-data.tmp.json` using the Write tool.

---

### Phase 2 — Instruction Mapping

**Goal:** Translate the `instructions` argument into a set of CLI flags for `generate-table.ts`.

#### 2a. Read the script's flag catalog

Read the header comment of the generator script to know what flags are available:
```bash
head -120 .claude/skills/create-report/table/generate-table.ts
```

This is the authoritative source for available flags. **Always read it before mapping** — the script grows over time and may have flags added since this SKILL.md was written.

#### 2b. Map instructions to flags

For each instruction, determine the matching flag:

| Instruction | Flag |
|-------------|------|
| "dark/light theme" | `--theme dark` or `--theme light` |
| "show only columns X, Y, Z" | `--columns "X,Y,Z"` |
| "sort by ColName descending" | `--sort-by "ColName:desc"` |
| "add search bar" / "searchable" | `--search` |
| "paginate N rows per page" | `--pagination N` |
| "export button" / "download CSV" | `--export csv` |
| "export JSON" | `--export json` |
| "both export buttons" | `--export both` |
| "highlight X rows in red" | `--highlight-rules '[{"column":"X","value":"...","color":"red"}]'` |
| "highlight rows where Score < 50" | `--highlight-rules '[{"column":"Score","operator":"lt","value":"50","color":"yellow"}]'` |
| "freeze first 2 columns" | `--frozen-columns 2` |
| "number format / currency" | `--number-format "$0,0.00"` |
| "date format" | `--date-format "MMM D, YYYY"` |
| "alternating row colors" / "striped" | `--striped` |
| "compact" / "dense" | `--compact` |
| "add row numbers" | `--row-numbers` |
| "caption / subtitle" | `--caption "..."` |
| "column widths" | `--column-widths '{"Col":"120px"}'` |
| "truncate long cells at N" | `--max-cell-width "300px"` |

**For column types** — combine the inferred types from Phase 1 with any explicit instructions:
- If instructions say "Status is a badge" → override inferred type
- If instructions say "Amount is currency" → set type `number` and add number format flag
- Build the `--column-types` JSON object from the merged result

#### 2c. Identify missing features

If the instructions require something that has no corresponding flag in the script, mark it as **MISSING FEATURE** and proceed to Phase 3a. Examples of missing features:
- "Color-code cells by value intensity (heatmap)"
- "Sparkline column"
- "Collapsible row groups"
- "Column visibility toggle"

If no features are missing, skip Phase 3a and go directly to Phase 3b.

---

### Phase 3a — Script Extension (only if missing features were identified)

**Goal:** Add the missing feature to `generate-table.ts` without breaking existing features.

1. Read the full current `generate-table.ts`:
   ```bash
   cat .claude/skills/create-report/table/generate-table.ts
   ```

2. Design the new flag:
   - Pick a clear `--kebab-case-name` for it
   - Add the flag documentation to the header comment (under `─── FLAGS ───`)
   - Add it to the `TableConfig` interface
   - Add parsing in `parseArgs()`
   - Implement the rendering in `generateHtml()` or the embedded JS

3. Edit `generate-table.ts` using the Edit tool. Make surgical edits — don't rewrite the whole file. Key insertion points:
   - Header docs: under the `─── FLAGS ───` section
   - TypeScript type: `TableConfig` interface
   - Parsing: `parseArgs()` function
   - Rendering: `generateHtml()` HTML template or the embedded `<script>` JS

4. Verify the script compiles:
   ```bash
   npx tsx --noEmit .claude/skills/create-report/table/generate-table.ts 2>&1 || echo "TYPE_CHECK_ONLY_EXIT"
   ```
   (This will error on missing args but type-check the source — look for TypeScript errors, not runtime errors.)

5. Re-read the header comment to confirm the new flag is documented.

---

### Phase 3b — HTML Generation

**Goal:** Run `generate-table.ts` with the data JSON and mapped flags to produce the HTML file.

#### Build the command

Assemble the command:
```bash
npx tsx .claude/skills/create-report/table/generate-table.ts \
  .claude/table-data.tmp.json \
  <output_html> \
  [--title "..."] \
  [--theme dark|light] \
  [--columns "..."] \
  [--sort-by "...:asc|desc"] \
  [--search] \
  [--pagination N] \
  [--export csv|json|both] \
  [--column-types '...'] \
  [--highlight-rules '...'] \
  [--frozen-columns N] \
  [--number-format "..."] \
  [--date-format "..."] \
  [--striped] [--compact] [--row-numbers] \
  [--caption "..."] \
  [--column-widths '...'] \
  [--max-cell-width "..."]
```

Only include flags that are relevant to the request. Omit flags with no applicable instruction.

#### Retry logic — up to 3 attempts

On each attempt:
1. Run the command, capturing stdout and stderr.
2. Exit code **0** → success, proceed to Phase 3c.
3. Exit code **non-zero**:
   - Read the error output carefully.
   - Common causes: malformed JSON in a flag value, column name not found in headers, invalid flag combination.
   - Fix the specific issue (correct the flag value, fix JSON escaping, adjust column name).
   - Increment attempt counter and retry.

After 3 failures, stop and report:
```
✗ Failed to generate table after 3 attempts.
Last error: <paste stderr>
Data JSON is at .claude/table-data.tmp.json for inspection.
```

#### 3c. Clean up temp file

After a successful run:
```bash
rm -f .claude/table-data.tmp.json
```

---

### Phase 4 — Verification & Open

1. Confirm the output file exists and is non-empty:
   ```bash
   ls -lh <output_html>
   ```

2. Open in Chrome:
   ```bash
   open -a "Google Chrome" <output_html>
   ```

3. Print the summary:
   ```
   ✓ HTML table generated: <output_html>
     Rows: <N> · Columns: <N>
     Features: [list of active flags]
     Opened in Google Chrome.
   ```

---

## Notes

- **Division of labor:** The agent handles all data parsing, type inference, and instruction mapping. `generate-table.ts` handles all HTML/CSS/JS rendering. Never ask the script to do data transformation — do it in Phase 1.
- **Script is source-controlled** — it lives at `.claude/skills/create-report/table/generate-table.ts`. Modifications in Phase 3a are permanent improvements that benefit all future invocations.
- **Always read the flag catalog (Phase 2a) before mapping** — flags may have been added since this SKILL.md was last updated.
- **JSON flags in shell** — when passing JSON values as flag arguments, use single quotes around the JSON to avoid shell interpretation of braces and quotes: `--highlight-rules '[{"column":"Status","value":"Error","color":"red"}]'`
- **Column names are case-sensitive** — use exact header values from the data when specifying `--columns`, `--sort-by`, `--column-types`, etc.
- **Dark theme is the default** — use `--theme light` only when explicitly requested.
- **Self-contained output** — the generated HTML has no external dependencies. It can be emailed, shared, or opened offline.

## Related Skills

- `/create-report` — Generates structured HTML reports from markdown (different purpose: narrative reports vs. data tables)
- `/project-index` → `/create-report` → `/create-report:table` — A full data documentation pipeline

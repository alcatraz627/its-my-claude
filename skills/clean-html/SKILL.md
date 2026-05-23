---
name: clean-html
description: Converts HTML files to clean, readable markdown by extracting and downloading embedded media, stripping tags while preserving document hierarchy, and removing UI clutter.
allowed-tools: Read, Bash, Write, WebFetch
user-invokable: true
argument-hint: "<source> [--output <name>]"
---

# /clean-html

## Brief

Converts HTML files to clean, readable markdown by extracting and downloading embedded media, stripping tags while preserving hierarchy, and removing UI clutter (navbars, footers, stray punctuation).

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
/clean-html <source> [--output <name>]
```

| Argument          | Type     | Description                                                                             |
| ----------------- | -------- | --------------------------------------------------------------------------------------- |
| `<source>`        | required | HTML input: file path (`./index.html`), URL (`https://example.com`), or raw HTML string |
| `--output <name>` | optional | Output folder name; defaults to source filename (without extension)                     |

---

## Phase 1 — Information Gathering

**Objective:** Collect the HTML source and identify all embedded media and links.

### 1.1 — Parse input arguments

- Extract `<source>` argument
- Check for `--output <name>` flag; default to source filename if omitted

### 1.2 — Determine source type and retrieve HTML

**If source is a URL:**

- Use WebFetch to fetch the page and store raw HTML

**If source is a file path:**

- Use Read to load the file from disk
- Normalize the path

**If source looks like raw HTML:**

- Treat as inline HTML string (starts with `<` or contains HTML tags)

Store the raw HTML for later processing.

### 1.3 — Scan HTML for media and links

Parse the HTML and extract:

- **Images:** `<img src="...">`, `srcset` attributes, picture elements
- **Videos:** `<video>`, `<source>` tags, iframe embeds
- **Documents:** Links to `.pdf`, `.doc`, `.docx`, etc.
- **External URLs:** `<a href="...">` that aren't internal fragments

**Exclude:**

- JavaScript files (`.js`)
- CSS files (`.css`)
- Analytics/tracking domains (Google Analytics, etc.)

Store a list of URLs to download.

### 1.4 — Download media

For each URL found:

- Use WebFetch or Bash (`curl`) to download the file
- Save to a temporary location pending output folder creation
- Log any failures but continue (don't block on missing media)

---

## Phase 2 — Planning

**Objective:** Decide how to clean the HTML and structure the output.

### 2.1 — Determine output folder name

- If `--output <name>` provided: use `<name>/`
- Else if source is a file path: use filename without extension
  - Example: `article.html` → `article/`
- Else if source is a URL: derive from domain and path
  - Example: `https://example.com/blog/post` → `example.com-blog-post/`
- Else (raw HTML): use a timestamp or counter (e.g., `html-output-001/`)

### 2.2 — Assess HTML complexity

Heuristically evaluate if the HTML is:

- **Simple:** Clean structure, minimal nested divs, clear semantic tags → use `clean_html.ts`
- **Convoluted:** Deeply nested, minimal semantics, lots of script/CSS → flag for manual cleanup

Proceed with script by default; switch to manual cleanup only if needed.

### 2.3 — Plan output structure

```
<output-folder>/
  ├── index.md              (cleaned markdown)
  ├── metadata.json         (source info, extracted links, download log)
  └── media/
      ├── image-001.jpg
      ├── image-002.png
      ├── document-001.pdf
      └── ...
```

---

## Phase 3 — Execution

**Objective:** Clean the HTML and write output files.

### 3.1 — Create output folder

```bash
mkdir -p <output-folder>/media
```

### 3.2 — Clean HTML

**If simple HTML:**

- Call `.claude/skills/clean-html/clean_html.ts <input-html>`
- The script should:
  - Strip all HTML tags
  - Preserve heading hierarchy (`#`, `##`, `###`, etc.)
  - Preserve list structure (bullets, numbered)
  - Convert tables to markdown
  - Return structured markdown (not flattened)

**If convoluted HTML:**

- Manually inspect and clean:
  - Remove `<script>`, `<style>`, comments
  - Extract body content
  - Manually identify headings, paragraphs, lists, tables
  - Convert to markdown structure
  - Output markdown

### 3.3 — Polish the cleaned markdown

- Remove stray punctuation (orphaned dashes, extra spaces)
- Remove navbar/footer cruft (navigation menus, "Sign up" buttons, etc.)
- Remove copyright lines, cookie notices, ads
- Remove repeated whitespace
- Ensure proper markdown formatting

### 3.4 — Move media to output folder

- Move downloaded files from temp location to `<output-folder>/media/`
- Update filenames if necessary (remove query params, sanitize names)

### 3.5 — Create metadata.json

```json
{
  "source": "<original source>",
  "type": "file|url|inline",
  "created_at": "ISO-8601 timestamp",
  "media_downloaded": 12,
  "media_list": [
    {
      "url": "...",
      "type": "image|video|pdf|...",
      "filename": "media/...",
      "status": "success|failed"
    }
  ],
  "cleaning_method": "script|manual",
  "notes": "Any issues or special handling"
}
```

### 3.6 — Write output files

```bash
# Write markdown
Write <output-folder>/index.md <cleaned-markdown>

# Write metadata
Write <output-folder>/metadata.json <metadata>
```

### 3.7 — Print summary

Print to stdout:

```
✓ Cleaned HTML → <output-folder>/
  - Markdown: index.md
  - Media: <N> files downloaded
  - Metadata: metadata.json
```

---

## Phase 4 — Verification

**Objective:** Confirm output is valid and complete.

### 4.1 — Verify output folder structure

```bash
ls -la <output-folder>/
```

Confirm:

- `index.md` exists and is non-empty
- `metadata.json` exists and is valid JSON
- `media/` folder exists

### 4.2 — Spot-check markdown quality

- Read first 20 lines of `index.md` to confirm:
  - Hierarchy is preserved (headings, lists, etc.)
  - No stray HTML tags
  - No orphaned punctuation
  - Readable prose

### 4.3 — Confirm media downloads

- List `media/` folder
- Compare count to `metadata.json` media_list
- Report any mismatches

### 4.4 — Print final result

```
─────────────────────────────────────────────────────
  ✓ Cleaned HTML → ./<output-folder>/
─────────────────────────────────────────────────────

  Output files:
    index.md            (<N> lines, ~<KB> size)
    metadata.json       (source, media log, etc.)
    media/              (<N> files)

  To read:    cat ./<output-folder>/index.md
  To review:  cat ./<output-folder>/metadata.json

─────────────────────────────────────────────────────
```

---

## Notes

- **Never modifies original HTML source** — read-only access only
- **All outputs isolated** to a single output folder in the current working directory
- **clean_html.ts script expected** at `.claude/skills/clean-html/clean_html.ts` — must exist and be executable
- **Convoluted HTML fallback:** If the HTML is too messy for the script, agent may manually clean instead, but should prefer the script for simpler cases
- **Media download failures are non-blocking** — if a media link fails, log it and continue; don't block the entire run
- **Output folder naming:** Defaults to source filename; user can override with `--output`

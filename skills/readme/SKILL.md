---
name: readme
description: Scans a git repo's structure, docs, package metadata, and prior skill reports — generates a polished README.md with GitHub-style badges, a pixel-art cover image, a quick-start guide, and a linked documentation index. Writes intermediate repo data to the global scratchpad for inter-skill handoff.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
user-invokable: true
argument-hint: "[output-path]"
---

## Brief

Generates a production-quality `README.md` for any git repository. Reads package metadata,
git history, CI config, existing docs, and previously generated skill outputs — producing a
human-friendly entry point with badges, a pixel-art cover image, and a getting-started guide.
Writes collected repo data to the global scratchpad so future `/git-repo` or `/readme` re-runs
can skip Phase 1 entirely.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: at skill start, run `lock-file.sh cleanup` to clear stale locks.
> Before every Edit/Write, run `lock-file.sh acquire`; release immediately after.
> Never write to `runtime-notes.md` or any SKILL.md without holding its lock.

---

## Usage

```
/readme [output-path]
```

| Argument      | Type     | Description                                                     |
| ------------- | -------- | --------------------------------------------------------------- |
| `output-path` | optional | Where to write the README (default: `./README.md` in repo root) |

---

## Phase 1 — Repository Reconnaissance

**Goal:** Collect all raw material needed to write the README without guessing.

### 1.1 — Pre-flight checks

**Source gum-tui.sh and verify gum is available:**

```bash
source ~/.claude/skills/shared/gum-tui.sh
```

If gum is not installed, the sourcing will print an install hint and abort. All terminal
status output throughout this skill (progress lines, warnings, the completion block) MUST
use gum-tui.sh functions (`gum_info`, `gum_warn`, `gum_success`, `gum_progress`,
`gum_complete`) — never hand-craft status boxes or ASCII borders.

**Confirm repo root:**

Run `git rev-parse --show-toplevel` to find the repo root. All subsequent paths are relative
to this root. If the command fails (not a git repo), stop and report to the user.

**Early overwrite guard:**

Resolve the target output path (default `./README.md`). If the file already exists, ask
before doing any scanning work:

```bash
gum confirm "<output-path> already exists — overwrite it?"
```

If the user declines, stop immediately and report — do not proceed with Phase 1 scanning.
If accepted, continue. Record `OVERWRITE_CONFIRMED=true` so Phase 3.1 knows to skip
re-prompting.

### 1.2 — Package metadata

Read whichever manifest files exist (check in this order):

| File             | Fields to extract                                     |
| ---------------- | ----------------------------------------------------- |
| `package.json`   | name, description, version, license, scripts, engines |
| `go.mod`         | module name, go version                               |
| `Cargo.toml`     | name, version, description, license                   |
| `pyproject.toml` | name, version, description, license, requires-python  |
| `composer.json`  | name, description, license                            |

If none exist, note "no manifest found" and fall back to git metadata only.

### 1.3 — Git metadata

Run these commands and record output:

```bash
git remote get-url origin          # repo URL for badges / links (may fail)
git log --oneline -10              # recent commit activity
git describe --tags --abbrev=0     # latest tag / version (if any)
git shortlog -sn --no-merges -10   # top contributors
```

**No-remote fallback:** If `git remote get-url origin` exits non-zero (local-only repo or
no `origin`), note `REMOTE_URL=none` and continue. Skip all remote-dependent badges
(CI status, npm, GitHub issues). Scratchpad slug derivation falls back to Phase 2.2's
local fallback.

Derive the repo slug from the remote URL: `owner/repo-name` (used as the scratchpad key).
If no remote, this is deferred to Phase 2.2.

### 1.4 — CI and tooling detection

Glob for CI config files:

```
.github/workflows/*.yml
.circleci/config.yml
.travis.yml
Jenkinsfile
.gitlab-ci.yml
```

For each found, note the CI provider — this determines which badge URL pattern to use.

Also check for: `Dockerfile`, `docker-compose.yml`, `Makefile`, `.nvmrc`, `.tool-versions`.

### 1.5 — Existing documentation inventory

Glob for all markdown files excluding `node_modules/`, `dist/`, `.next/`, `build/`:

```
**/*.md
**/*.mdx
docs/**/*
wiki/**/*
```

Collect file paths, titles (first `# Heading` in each file), and file sizes. Exclude
`README.md` itself (that's what we're generating).

### 1.6 — Prior skill output scan

Check `.claude/` for previously generated skill outputs — these contain already-derived
insights that are more reliable than re-scanning:

- `.claude/project-index.md` — architecture, directory structure, key files
- `.claude/output/` — any HTML reports from `/create-report` runs
- `_*.claude.md` files in the repo root — arch-qa or other context hand-offs

Read any that exist and extract: project description, key components, tech stack, notable
patterns. Log which files were read and what was extracted.

---

## Phase 2 — Doc Summarization + Scratchpad

**Goal:** Summarize all found docs and persist all collected data for future agents.

### 2.1 — Summarize docs

For each doc file found in Phase 1.5:

- Read the file (skip if >200KB — note it as "too large to summarize")
- Generate a 1–2 sentence summary: what the doc covers, who it's for
- Record: relative path, title, summary, size

For repos with **more than 6 doc files**, use a `Task` agent to parallelize summarization —
split the list into batches of 5 and run concurrently.

### 2.2 — Write global scratchpad entry

Compute the scratchpad path:

```bash
# Primary: derive slug from remote URL (owner/repo pattern)
REPO_SLUG=$(git remote get-url origin 2>/dev/null \
  | sed 's|.*[:/]\([^/]*/[^/]*\)\.git|\1|;s|.*[:/]\([^/]*/[^/]*\)$|\1|')

# Fallback: use local directory name if no remote
if [ -z "$REPO_SLUG" ]; then
  REPO_SLUG="local-$(basename "$(git rev-parse --show-toplevel)")"
fi

SCRATCHPAD="$HOME/.claude/scratchpad/global/readme-${REPO_SLUG//\//-}.md"
```

Write a structured entry to `~/.claude/scratchpad/global/readme-<repo-slug>.md`:

```markdown
# README Scratchpad: <repo-slug>

<!-- sessions: <session-id>@<date> -->

Generated: <ISO timestamp>

## Metadata

- Name: <name>
- Version: <version>
- Description: <description>
- License: <license>
- Language/Runtime: <detected>
- CI: <provider(s)>
- Remote: <url>

## Badges

<!-- List of badge markdown lines ready to paste -->

## Documentation Inventory

| File | Title | Summary |
| ---- | ----- | ------- |
| ...  | ...   | ...     |

## Prior Skill Outputs Used

- <file>: <what was extracted>

## Quick Start Commands

- Install: <command>
- Run: <command>
- Test: <command>
- Build: <command>
```

Acquire the lock before writing (`lock-file.sh acquire`), write, release immediately.

---

## Phase 3 — README Assembly

**Goal:** Assemble all collected data into a well-structured, visually polished README.

### 3.1 — Overwrite confirmation (already handled)

Overwrite permission was obtained in Phase 1.1. If `OVERWRITE_CONFIRMED=true`, proceed
directly to badge assembly. No second prompt — do not ask again.

### 3.2 — Build badge URLs

Construct shields.io badge markdown for each detected source. Use the scratchpad inventory
from Phase 2. Common patterns:

```markdown
<!-- Language badge (from manifest) -->

![Language](https://img.shields.io/badge/language-<lang>-<color>)

<!-- Version (from git tag or manifest) -->

![Version](https://img.shields.io/badge/version-<version>-blue)

<!-- License -->

![License](https://img.shields.io/badge/license-<license>-green)

<!-- GitHub CI (if .github/workflows found) -->

![CI](https://github.com/<owner>/<repo>/actions/workflows/<file>/badge.svg)

<!-- npm version (if package.json + npm registry) -->

![npm](https://img.shields.io/npm/v/<package-name>)

<!-- GitHub issues -->

![Issues](https://img.shields.io/github/issues/<owner>/<repo>)
```

Only include badges with real data — never emit a badge with a placeholder value like `N/A`.

### 3.3 — Generate pixel-art cover SVG

Create a small inline SVG (64×64 viewBox, 8×8 grid of 8px cells) as the cover image.
The design should loosely reflect the project type:

| Project type    | Motif                                      |
| --------------- | ------------------------------------------ |
| Web / frontend  | Browser window or cursor pixel art         |
| CLI tool        | Terminal prompt `>_` motif                 |
| Library / SDK   | Puzzle piece or gear                       |
| API / backend   | Server rack or database cylinder           |
| Data / ML       | Simple bar chart or neuron dots            |
| Generic / other | Abstract geometric pattern (diamonds/grid) |

Color the SVG using 2-3 colors derived from the project's language or CI badge colors.
Keep the SVG self-contained (no external refs).

> ⚠️ **Write the SVG to a file** (e.g. `assets/cover.svg`) and reference it via
> `<img src="assets/cover.svg" ...>` — **do not paste raw `<svg>` markup into the README**.
> GitHub.com renders inline SVG, but most other markdown renderers (IDE previews, terminal
> viewers like glow/mdcat, AI assistants, npm/crates pages) strip the SVG and dump the
> `<text>` nodes as plain text — producing an unreadable wall of words. Always go file-first.

Example skeleton — write SVG to `assets/cover.svg`:

```xml
<!-- assets/cover.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="128" height="128">
  <!-- 8x8 pixel grid — fill each rect based on motif -->
  <rect x="0" y="0" width="8" height="8" fill="#..." />
  ...
</svg>
```

Then reference it from the README:

```html
<div align="center">
  <img src="assets/cover.svg" alt="Project cover" width="128">
</div>
```

### 3.4 — Write README sections

Write the complete README in this order:

```markdown
<!-- Cover image (SVG block) -->

<h1 align="center">Project Name</h1>

<p align="center">
  One-line description of the project.
</p>

<p align="center">
  <!-- Badge row -->
  ![badge1](...) ![badge2](...) ...
</p>

---

## About

2-3 paragraphs explaining what this project does, who it's for, and why it exists.
Draw from: manifest description, git log topics, project-index.md if available.

## Quick Start

\`\`\`bash

# Clone

git clone <remote-url>
cd <repo-name>

# Install

<install-command>

# Run

<run-command>
\`\`\`

> See [detailed setup](#) for advanced configuration, environment variables, and
> production deployment.

## Documentation

| Document                  | Description       |
| ------------------------- | ----------------- |
| [Title](relative/path.md) | One-liner summary |
| ...                       | ...               |

## Contributing

Contributions are welcome! Please open an issue or pull request.

<!-- If CONTRIBUTING.md exists, link to it -->

## License

This project is licensed under the <License> License.

<!-- If LICENSE file exists, link to it -->
```

Acquire lock before writing. Write to `output-path` (default: `./README.md`). Release lock.

---

## Phase 4 — Verification + Preview

**Goal:** Confirm correctness, cross-check against scratchpad, preview, and offer HTML export.

### 4.1 — Scratchpad cross-check

Re-read the scratchpad entry written in Phase 2. Verify:

- Every doc file in the Documentation Inventory is present as a row in the README's Documentation table
- Every badge source detected in Phase 1.4 has a corresponding badge in the README
- The Quick Start commands match what was recorded in the scratchpad
- The repo name and description match the manifest metadata

Report any discrepancies found. If a doc is missing from the README, offer to add it.

### 4.2 — Link validation

For every relative link in the README (doc paths, CONTRIBUTING.md, LICENSE), run:

```bash
test -f "<resolved-path>" && echo "OK: <path>" || echo "BROKEN: <path>"
```

Report any broken links.

### 4.3 — Open in viewer

```bash
open <output-path>
```

This opens the README in the system default handler (typically a Markdown viewer or browser).

### 4.4 — Offer HTML report

Ask the user if they want to generate an HTML version via `/create-report`:

```bash
gum confirm "Generate an HTML report from the README?"
```

If yes, present a style selection:

```bash
STYLE=$(gum choose "default" "notion" "dashboard" "magazine" "terminal" "data-table" "feed" "corporate")
```

Then invoke:

```
/create-report <output-path> --style <style>
```

---

## Phase 5 — Post-Run Insights

**Goal:** Log what was learned and print the completion block.

### 5.1 — Generate insights

Produce 2–6 concrete observations from this run — things that would make a future `/readme`
run faster or more accurate. Examples:

- Which manifest file had the most useful metadata
- Whether project-index.md or arch-qa output was available and actually helped
- Any doc files that were too large to summarize or had no usable title
- Whether the scratchpad already existed and was reused (Phase 1 skipped)
- Badge sources that were detected but couldn't produce a valid URL

### 5.2 — Write runtime note

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## readme: [repo-slug] — [YYYY-MM-DD HH:MM]

**Purpose:** Generated README.md for <repo-name>.

**Insights:**

1. [point]
2. [point]
...

---
ENTRY

bash ~/.claude/skills/shared/prepend-runtime-note.sh "readme" /tmp/runtime-note-entry.md
```

### 5.3 — Print completion block

Use `gum_complete` from gum-tui.sh:

```bash
source ~/.claude/skills/shared/gum-tui.sh
gum_complete "readme" \
  "Repo=<repo-name>" \
  "Badges=N" \
  "Docs linked=N" \
  "Output=<absolute-path-to-README.md>" \
  "Errors=<broken links or none>"
```

---

## Validation Examples

### Example: Fresh repo with no README

**Scenario:** User runs `/readme` in a git repo with `package.json`, a GitHub Actions
workflow, and 3 docs. No `README.md` exists.
**Expected behavior:**

- [ ] Phase 1.1 confirms repo root via `git rev-parse --show-toplevel`
- [ ] Phase 1.2 reads `package.json` for name/description/license/scripts
- [ ] Phase 1.4 detects `.github/workflows/` and builds a CI badge URL
- [ ] Phase 2.2 writes scratchpad to `~/.claude/scratchpad/global/`
- [ ] Phase 3.3 produces a project-type-matched pixel-art SVG cover

### Example: README already exists

**Scenario:** User runs `/readme` when `README.md` already exists.
**Expected behavior:**

- [ ] Overwrite check fires in Phase 1.1 before any scanning work begins
- [ ] If user declines, skill stops without scanning, writing, or prompting further
- [ ] If user accepts, `OVERWRITE_CONFIRMED` prevents re-prompting in Phase 3.1

### Example: No git remote

**Scenario:** Repo has no remote (local-only). `git remote get-url origin` fails.
**Expected behavior:**

- [ ] Phase 1.3 notes `REMOTE_URL=none` and continues without stopping
- [ ] Remote-dependent badges (CI status, npm, GitHub issues) are skipped
- [ ] Phase 2.2 derives slug via `basename $(git rev-parse --show-toplevel)`
      with `local-` prefix

### Example: Post-run completion

**Scenario:** Skill completes successfully.
**Expected behavior:**

- [ ] Phase 4.3 opens the README with `open <output-path>`
- [ ] Phase 4.4 offers HTML report via `gum confirm` then `gum choose` style picker
- [ ] Phase 5.2 writes a runtime note to `runtime-notes.md` via `prepend-runtime-note.sh`
- [ ] Phase 5.3 prints `✓ readme complete` block with absolute file path and stats

---

## Notes

- **Overwrite guard:** Always confirm before overwriting an existing README — never silently clobber.
- **Pixel art is a placeholder:** The SVG cover is intentional placeholders; users can swap it for a real image later. Never attempt to fetch or embed external images.
- **Scratchpad key:** The global scratchpad file is keyed to the repo slug (e.g., `readme-owner-repo.md`). This is the intended handoff surface for the future `/git-repo` skill — it can read this file instead of re-running Phase 1.
- **`/git-repo` integration:** This skill is designed to be callable as a step within `/git-repo`. When invoked that way, pass the `output-path` argument to avoid prompting for the location.
- **No external image fetches:** All badge URLs are shields.io pattern strings — they are not fetched at generation time. The SVG cover is inline. The README is fully portable offline.

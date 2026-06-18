---
name: improve-config
description: Audits the project's .claude/ directory (or ~/.claude/ for global config) using /user-config context to catalogue instructions and skill patterns, produces a prioritized improvement list, applies user-approved changes, and generates a summary HTML report.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Skill
user-invokable: true
argument-hint: "[--scope=<focus-area>] [--skip=<skill,...>] [--dry-run] [notes...]"
---

## Brief

Audits the project's `.claude/` directory (or `~/.claude/` for global config) — skills,
guidelines, personal config, and settings — catalogues all instructions and patterns,
generates a prioritized improvement list (consolidation, skill extraction, dead-instruction
removal, guideline promotion), applies user-approved changes, and optionally produces a
summary HTML report via `/create-report`.

# Improve Config

A whole-directory audit and improvement tool for your Claude Code configuration. Unlike
`/improve-skill` which targets individual skills, `/improve-config` takes a holistic view:
it understands what the entire `.claude/` setup is trying to do, finds redundancy and gaps
across all files, and helps you evolve it as a coherent system.

**What it produces:**

- Categorized improvement list across all `.claude/` files
- Applied changes (consolidations, rewrites, new skills, deletions)
- Optional HTML summary report via `/create-report`
- Updated `runtime-notes.md` entry

**Scope:**

- **Operates within:** `.claude/` only — never writes elsewhere
- **Can read:** anywhere in the project and `../backend/` for context
- **Never modifies:** `../backend/.claude/` (read-only) or anything outside `.claude/`

---

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: hold a `lock-file.sh` lock around every Edit/Write to any `.claude/` file,
> including `runtime-notes.md`. Full protocol in 3.1.

---

## Usage

```
/improve-config [--scope=<focus-area>] [--skip=<skill,...>] [--dry-run] [notes...]
```

| Argument               | Type     | Description                                                                                                                                  |
| ---------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `--scope=<focus-area>` | optional | Short description of which improvement aspects to prioritize (e.g. `--scope="consolidate shared instructions"`). Weights the analysis phase. |
| `--skip=<skill,...>`   | optional | Comma-separated list of skills or filenames to exclude from the audit entirely (e.g. `--skip=create-report,arch-qa`).                        |
| `--dry-run`            | optional | Run the full analysis and print the improvement plan, but write no files. Exits after user approval step.                                    |
| `notes...`             | optional | Additional free-form guidance that shapes the improvement run (e.g. "don't remove edge case handling").                                      |

---

## Phase 1 — Information Gathering

### 1.1 — Parse arguments

Extract from the invocation string:

- `--scope=<value>` → store as `SCOPE` (empty string if not provided)
- `--skip=<value>` → parse as comma-separated list, store as `SKIP_LIST`
- `--dry-run` → set `DRY_RUN=true` if present
- Remaining tokens → store as `NOTES`

Print parsed values:

```
  Scope:    "<value or (none)>"
  Skip:     [list, or "(none)"]
  Dry run:  yes / no
  Notes:    "<value or (none)>"
```

### 1.2 — Load codebase context from existing index

Print: `  Loading codebase context ...`

**Do not run `/project-index`** — it does a full filesystem scan and HTML report generation, which is too heavy for a config audit.

Instead:

1. Check if `.claude/project-index.md` exists:
   ```bash
   ls .claude/project-index.md 2>/dev/null
   ```
2. **If it exists and is recent (within 7 days):** Read it in full. Use it as codebase context.
3. **If it does not exist or is stale:** Print a note — `"No recent project index found. Run /project-index first for richer context. Proceeding with limited codebase knowledge."` — then continue without it.

Extract and note (from the index or from known project structure):

- Primary tech stack (framework, language, key libraries)
- Folder structure and major feature areas
- Any backend/frontend split relevant to `.claude/` scope

### 1.3 — Run /user-config for Claude config overview

Invoke `/user-config` to get a structured view of all Claude configuration:
skills, guidelines, personal settings, and permissions.

Print: `  Running /user-config for config overview ...`

Extract and note:

- All skill names and their one-line descriptions
- What GUIDELINES.md contains at a high level
- What personal.md contains
- Permissions in settings files

### 1.4 — Read all .claude/ files directly

Reading everything directly is more reliable than relying solely on /user-config output.

For each file in `.claude/`:

- `Glob(".claude/**/*")` — list all files
- Exclude: anything in `SKIP_LIST`, `node_modules/`, lock files in `shared/locks/`
- For each file found: Read it in full, note its purpose and content summary

Print each file as it is read:

```
  Reading .claude/skills/arch-qa/SKILL.md ... [purpose: architecture Q&A skill]
  Reading .claude/skills/GUIDELINES.md ...    [purpose: shared rules for all skills]
  ...
```

### 1.5 — Build the catalogue

For each file, record:

| Field              | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| Path               | Relative path                                                           |
| Type               | `skill`, `guideline`, `personal`, `settings`, `shared-script`, `other` |
| Purpose            | One-sentence summary                                                    |
| Key instructions   | Bullet list of main things it tells Claude to do                        |
| Overlap candidates | Other files with similar instructions                                   |
| Specificity score  | `high` (very task-specific) / `medium` / `low` (broadly applicable)    |

Cross-reference all files to identify:

- Instructions that appear in 2+ files (duplication)
- Skills that have near-identical scope to another skill (consolidation candidates)
- Instructions that belong in GUIDELINES.md but live only in one skill
- Functionality that is invoked repeatedly but has no dedicated skill

Weight all findings by `SCOPE` if provided, and exclude `SKIP_LIST` entries throughout.

---

## Phase 2 — Analysis & Planning

**Do not write any files in this phase.**

### 2.1 — Generate improvement list

Produce a categorized list of proposed improvements. For each item include:

- **Category** (see below)
- **Title** — one-line description
- **Rationale** — why this matters and what it fixes
- **Risk** — `low` / `medium` / `high` (high = significant rewrites or deletions)
- **Files affected**

**Categories:**

| Category              | Description                                                                                |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `cross-cutting`       | A change that must be applied consistently across multiple skills/files                    |
| `per-skill`           | Vague phrasing, stale references, or obsolete instructions in a single skill               |
| `consolidation`       | Two or more skills/sections that can be folded into one                                    |
| `skill-extraction`    | Recurring functionality that warrants a dedicated new skill                                |
| `guideline-promotion` | An instruction repeated across skills that belongs in GUIDELINES.md                        |
| `dead-instruction`    | An instruction that no longer applies, is contradicted, or is redundant with GUIDELINES.md |

Dead instruction removals must be justified: cite which GUIDELINES rule or other file
already covers it. Never remove an instruction that handles an edge case not covered elsewhere.

### 2.1a — Consult the placement indices before any structural move

Before proposing any `skill-extraction` or any item that **relocates** a rule, feature,
convention, or script, consult the canonical "where does config go" indices. This is the same
discipline `~/.claude/PLACEMENT.md` mandates for adding config by hand.

- `~/.claude/PLACEMENT.md` — the category × tier rule for where new config belongs. Read this
  before extracting a skill or moving an instruction; it decides whether the thing is a rule, a
  feature, a convention, a skill, or inline.
- `~/.claude/NAMESPACE.md` — the `std::claude::*` cluster the thing belongs to.
- `~/.claude/FOLDERS.md` — the per-folder owner/purpose map; confirms the destination folder
  accepts this kind of file.

For any item that **moves a canonical path** — renames a script others reference, relocates a
skill, changes a top-level directory — file a `/migrate` entry. Note the planned `/migrate` call
in the improvement item's rationale so the user sees it before approving.

If the indices say a proposed extraction belongs somewhere other than a new skill (e.g. it's a
rule or a convention), reclassify the item and say so in its rationale rather than extracting a
skill anyway.

### 2.2 — Print analysis summary

```
─────────────────────────────────────────────────────
  /improve-config Analysis
─────────────────────────────────────────────────────

  Files catalogued: N
  Scope filter:     "<value or none>"
  Skip list:        [list or none]

  Proposed improvements (N total):

    cross-cutting     [N] — [brief overall theme]
    per-skill         [N] — [brief overall theme]
    consolidation     [N] — [brief overall theme]
    skill-extraction  [N] — [brief overall theme]
    guideline-promo   [N] — [brief overall theme]
    dead-instruction  [N] — [brief overall theme]

  Full list:
    1. [category] [title] — [rationale] (risk: low/medium/high)
    2. ...

─────────────────────────────────────────────────────
```

### 2.3 — Collect user input

Ask two questions sequentially.

**Question A — which items to apply:**

```
Which improvements should I apply?
  Enter: "all" / item numbers (e.g. "1,3,5") / "none"
→
```

Wait for input.

**Question B — modification prompt:**

```
Any modifications to how I apply these? (free-form, or press enter to skip)
→
```

Wait for input.

If `DRY_RUN=true`: skip both questions. Print:

```
─────────────────────────────────────────────────────
  DRY RUN — no files will be written.
  Improvements that would have been applied: [list]
─────────────────────────────────────────────────────
```

Then exit.

---

## Phase 3 — Execution

Apply all approved improvements. Process them in this order to minimize conflicts:

1. `guideline-promotion` items first (GUIDELINES.md changes affect all subsequent edits)
2. `dead-instruction` removals
3. `per-skill` improvements
4. `cross-cutting` changes (apply to each affected file sequentially)
5. `consolidation` merges
6. `skill-extraction` — first confirm placement against `PLACEMENT.md` / `NAMESPACE.md` /
   `FOLDERS.md` (per 2.1a), file a `/migrate` entry if the extraction moves a canonical path,
   then invoke `/create-skill` interactively for each new skill

When an approved improvement **rewrites a skill's SKILL.md** (its prose, structure, or output
contract), apply the Claude-consumption house rules in
`~/.claude/assets/reports/20260618-persona-dogfood/claude-consumption-spec.md` — behavior over
flavor, plain declaratives over ALL-CAPS/MUST, explicit scope, a load-bearing output contract,
action-oriented frontmatter. A SKILL.md is system-prompt material consumed by Claude, not a
human doc.

### 3.1 — File lock protocol

For every file write, follow the lock protocol from GUIDELINES.md:

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "<relative-path>" "improve-config"
# ... perform Edit or Write ...
bash ~/.claude/skills/shared/lock-file.sh release "<relative-path>" "improve-config"
```

If acquire exits 1 (file locked): print the owner, skip this file, note it in the final summary.

### 3.2 — Per-change narration

Narrate each applied improvement in one block — title, files, the section touched, and the
result. The lock acquire/release happens per 3.1; you don't need to narrate each lock step.

```
  [✎] <title> — <files> — editing <section> ... ✓
  [+] Extracting skill <name> — invoking /create-skill ...
```

### 3.3 — Respect modification prompt

Apply `NOTES` and Question B input as a consistent lens across all edits:
e.g. if the user said "keep all edge case handling", never remove instructions
that exist specifically to handle edge cases even if flagged as dead.

---

## Phase 4 — Verification & Reporting

### 4.1 — Read back all modified files

For each file that was edited or written during Phase 3:

- Read the file back
- Confirm the change is present and the file is non-empty
- Print: `  ✓ <path> verified`

### 4.2 — Print terminal summary

```
─────────────────────────────────────────────────────
  /improve-config complete
─────────────────────────────────────────────────────

  Files modified:     N
    .claude/skills/GUIDELINES.md          (2 changes)
    .claude/skills/arch-qa/SKILL.md       (1 change)
    ...

  New skills created: N
    .claude/skills/<name>/

  Improvements skipped (locked / user-excluded):
    ...

  Items not applied (user selection):
    ...

─────────────────────────────────────────────────────
```

### 4.3 — Offer HTML report

```
Generate an HTML report of this run? (yes / no)
→
```

If yes:

1. Write the terminal summary above to `.claude/improve-config-summary.md`
2. Acquire lock on that file before writing, release after
3. Invoke `/create-report` with the summary file as input
4. Open the generated HTML

### 4.4 — Update runtime-notes.md

Write the entry to a temp file and call `prepend-runtime-note.sh`:

```bash
cat > /tmp/runtime-note-entry.md << 'ENTRY'
## improve-config: <brief description of what was run> — YYYY-MM-DD HH:MM

**Purpose:** <one sentence>

**Insights:**

1. [point]
2. [point]
ENTRY

bash ~/.claude/skills/shared/prepend-runtime-note.sh "improve-config" /tmp/runtime-note-entry.md
```

---

## Notes

- No additional constraints beyond GUIDELINES.md defaults.
- Operates strictly within `.claude/` — the rest of the project is readable for
  context but never written to.
- `../backend/.claude/` is read-only; never modified under any circumstances.
- `--dry-run` exits cleanly after Phase 2 with no file writes.
- When `/create-skill` is invoked for skill-extraction items, the wizard runs interactively —
  the user will be asked the standard Q&A questions for each new skill.
- Dead instruction removals are conservative: if an instruction handles an edge case not
  covered elsewhere, it is flagged as "informational" not removed.
- After this skill runs, `/user-config` can be used to review the updated configuration.

---
name: archive-notes
description: Archives old runtime-notes entries beyond a threshold to a dated archive file, keeping the active notes file lean. Accepts a project path argument.
allowed-tools: Read, Edit, Write, Bash, Glob
user-invokable: true
argument-hint: "<project-path> [--keep N]"
metadata:
  filePattern: ["**/runtime-notes*.md"]
  bashPattern: ["archive.notes"]
---

## Brief

Reads a project's `runtime-notes.md`, counts entries, and archives entries beyond a configurable threshold to a dated archive file. Keeps the active notes file lean for faster context loading.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `~/.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `~/.claude/skills/shared/lock-file.sh acquire` before
> every Edit/Write, and release it immediately after. Never write to `runtime-notes.md` or
> any SKILL.md without holding its lock.

## Usage

```
/archive-notes <project-path> [--keep N]
```

| Argument | Type | Description |
|---|---|---|
| `<project-path>` | Required | Absolute or relative path to the project root (directory containing `.claude/`) |
| `--keep N` | Optional | Number of most recent entries to keep. Default: 50. |

---

## Phase 1 — Validate Input

1. Parse arguments: extract `project-path` and optional `--keep N` (default 50).
2. Resolve the project path to an absolute path.
3. Locate `runtime-notes.md`:
   - Check `<project>/.claude/skills/runtime-notes.md` (standard location)
   - If not found, check `<project>/.claude/runtime-notes.md` (fallback)
   - If neither exists, report "No runtime-notes.md found" and exit.
4. Print the plan:

```
  Project:   <resolved-path>
  Notes:     <path-to-runtime-notes.md>
  Keep:      N most recent entries
```

## Phase 2 — Count & Split

1. Read the entire `runtime-notes.md` file.
2. Parse entries. Each entry starts with `## ` (h2 heading). The file header (lines before the first `## `) is preserved separately.
3. Count total entries.
4. If total <= keep threshold:
   - Print "Only N entries found (threshold: M). No archival needed." and exit.
5. Split the entries:
   - **Keep:** First N entries (most recent, since entries are prepended)
   - **Archive:** Remaining entries (oldest)

Print the split plan:

```
  Total entries: X
  Keeping:       N (most recent)
  Archiving:     Y (oldest)
```

## Phase 3 — Write Archive

1. Determine the archive filename:
   - Format: `runtime-notes-archive-YYYY-QN.md` where Q is the current quarter
   - Location: Same directory as `runtime-notes.md`
2. Check if an archive file already exists for this quarter:
   - If yes, **append** the new archived entries to the existing file (after any existing content)
   - If no, create a new archive file with a header:

```markdown
# Runtime Notes Archive — YYYY QN

Archived entries from <project-name>. Original file: runtime-notes.md

---

<archived entries>
```

3. Acquire lock, write the archive file, release lock.

## Phase 4 — Truncate Active Notes

1. Rebuild `runtime-notes.md` with:
   - The original file header (title line + description)
   - Only the N most recent entries
2. Acquire lock, write the truncated file, release lock.

## Phase 5 — Verify

1. Read back both files to confirm:
   - Archive file exists and contains the archived entries
   - Active notes file exists and contains only the kept entries
   - No data was lost (total entry count matches: kept + archived)
2. Print summary:

```
─────────────────────────────────────────────────────
  ✓ Runtime notes archived
─────────────────────────────────────────────────────

  Project:     <project-name>
  Active file: <path> (N entries kept)
  Archive:     <path> (Y entries archived)
  Total:       X entries preserved (0 lost)

─────────────────────────────────────────────────────
```

## Phase 6 — Post-Run

Write a runtime note via:

```bash
bash ~/.claude/skills/shared/prepend-runtime-note.sh "archive-notes" /tmp/runtime-note-entry.md
```

---

## Notes

- Entries are identified by `## ` (h2 heading) markers. Content between headings belongs to the preceding entry.
- The `---` separator between entries is part of the entry, not a separate element.
- Always preserve the file header (everything before the first `## `).
- Never delete the original `runtime-notes.md` — always truncate in place.
- The archive filename uses quarters (Q1=Jan-Mar, Q2=Apr-Jun, Q3=Jul-Sep, Q4=Oct-Dec) to group by period.
- If an archive for the current quarter already exists, append — don't overwrite. This allows multiple archival runs per quarter.
- The `--keep` default of 50 matches the GUIDELINES.md rotation policy threshold.

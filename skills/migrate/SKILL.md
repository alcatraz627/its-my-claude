---
name: migrate
description: Create a migration entry for a structural change to ~/.claude/. Required before/alongside any change that moves a canonical path, renames a script other things reference, changes a data schema, alters hook architecture, or creates/removes a top-level dir. See conventions/gcc-hygiene.md for the structural-change definition. Use this when about to commit structural change to gcc, or to backfill a missing migration entry after the fact.
allowed-tools: Read, Write, Edit, Bash, Glob
argument-hint: "[--backfill] [--title TITLE]"
user-invokable: true
---

## Brief

Interactive (or guided) creation of `~/.claude/migrations/NNNN-<slug>.md`. Updates the MIGRATIONS.md index in the same flow. Templates the why / what-changes / verification / rollback shape.

## When this is mandatory

A structural change is any of (full definition in `conventions/gcc-hygiene.md`):
- Top-level `~/.claude/` directory created, renamed, or deleted
- A canonical file moved, renamed, or its format changed
- Settings.json hook architecture changes (event handler added/removed/orchestrated)
- Namespace cluster added, renamed, removed
- A skill or script's path moves AND any external caller references it
- A data store schema changes (events.jsonl, index.jsonl, MEMORY.md format)

When in doubt, file the entry. Lightweight stub is better than missing record.

## Usage

```
/migrate                       # interactive: prompts for title + fields
/migrate --title "X"           # skip the title prompt
/migrate --backfill            # mark migration as retrofitted (status: complete, dated past)
```

## Phase 1 — Resolve next migration number

```bash
last=$(ls ~/.claude/migrations/00*.md 2>/dev/null | tail -1 | grep -oE '00[0-9]+' | head -1)
next=$(printf '%04d' $((10#${last:-0} + 1)))
```

E.g., if `0007-scripts-cleanup.md` is latest, next is `0008`.

## Phase 2 — Gather inputs via mcp__inputs__form

Required fields:
- `title` — short imperative (e.g., "Symlink-cleanup for migration 0007 leftovers")
- `slug` — auto-suggest from title (lowercase, hyphens, ≤30 chars); user can edit
- `status` — pick_one: planned / in-progress / complete / abandoned
- `why` — free text (the driving constraint)

Optional:
- `proposal_id` — if this migration executes a filed proposal
- `affected_paths` — comma-separated list

## Phase 3 — Write the migration file

Copy `~/.claude/migrations/_TEMPLATE.md` to `NNNN-<slug>.md`, fill in frontmatter + headers. Leave verification + rollback sections with placeholder bullets the user fills as they execute the migration.

## Phase 4 — Update MIGRATIONS.md index

Append a row to the index table:

```markdown
| 00NN | <title> | <status-icon> | <relative path> |
```

Use the status legend already in MIGRATIONS.md (✅ 🔄 ⏳ 💡 ❌).

## Phase 5 — Print next steps

```
─────────────────────────────────────────────────────
  ✓ Migration NNNN drafted
─────────────────────────────────────────────────────

  File:    ~/.claude/migrations/NNNN-<slug>.md
  Status:  <status>

  Next:
    1. Execute the migration steps
    2. Check off the Verification checklist
    3. Update the migration's status field in frontmatter
    4. Re-run /migrate (status update only) when complete

─────────────────────────────────────────────────────
```

## Notes

- The skill writes the FILE — the human (or executing agent) is responsible for following through on the verification + rollback checklists.
- For multi-phase migrations, the Phases section in the body should list each step with a check-mark as it lands.
- Backfilling (`--backfill`) is acceptable per MIGRATIONS.md's own note: "Retrofits are OK."
- The migration enforcement hook (`PreToolUse on Bash`) reminds users to invoke `/migrate` when structural commands (`mv`, `ln`, `mkdir` on `~/.claude/`) fire without recent migration creation. Mute via `~/.claude/.no-migrate-hint`.

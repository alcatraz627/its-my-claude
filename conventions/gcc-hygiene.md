---
brief: Heuristics for a clean ~/.claude/: what to keep, what to derive, what to archive, and what counts as a "structural change" requiring a migration entry.
triggers:
  - topic:gcc-cleanup
  - topic:gcc-hygiene
  - phrase:clean up claude
  - phrase:consolidate gcc
  - phrase:structural change
  - tool:migrate
related:
  - PLACEMENT.md
  - FOLDERS.md
  - migrations/MIGRATIONS.md
tier: 2
category: conventions
updated: 2026-05-17
stale_after_days: 365
---

# GCC Hygiene: keeping `~/.claude/` clean

> The rules for evaluating what should live where in the Global Claude Config, when to consolidate, when to archive, and what counts as a "structural change" that requires a migration entry.

## The five principles

### 1. Authoritative source > derived view

If a fact is computable from another source, the other source is canonical and the view is regenerable. Examples:
- `mistake-patterns.md` derives from `atone/events.jsonl` (kernel-locked)
- `pending-todos.jsonl` derives from `subconscious/dreams/ingest-queue/*.json`
- `FOLDERS.md`'s census section derives from `~/.claude/*/` (a script regenerates it)

**Rule:** never hand-edit a derived view. If you need to fix a derived view, fix the source and re-derive. If the source can't express what you want, fix the derivation script.

### 2. Subcommand dispatcher > script-per-action

When 5+ scripts share state, config, or naming prefix (`shell-log-X`, `sl-X`, `wal-X`), they belong inside one script with subcommand dispatch (`atone.sh`-style). The lift is:
- One place to evolve shared logic
- Easier to discover (one `--help`, one place to look)
- Settings.json and hook references stay shorter
- Adding a new action is a case-branch and no new file

**Anti-pattern:** more than about 10 files with the same prefix and similar shape.

### 3. Orchestrator > settings.json fan-out (with one caveat)

When a single lifecycle event has 5+ hook registrations doing independent things, a modular orchestrator (`scripts/<event>/run.sh + tasks/NN-name.sh`) is cleaner than 5+ blocks in settings.json. See `std::claude::startup` for the pattern.

**Caveat:** Claude Code runs each settings.json hook registration as a parallel subprocess. An orchestrator collapses them into one serial process. For **latency-sensitive events** (`PostToolUse`, `UserPromptSubmit`), keep the per-registration parallelism and never orchestrate. For **bounded one-shots** (`SessionStart`, `Stop`, `PreCompact`), orchestrate freely.

### 4. Cleanup is a task, not a habit

If a file accumulates and "should be cleaned up periodically," that is a missing task and no process. Add it to `scripts/startup/tasks/` so it runs deterministically on login.

Examples:
- `/tmp/claude-*` cleanup: 10-cleanup-tmp-state.sh
- `_*.claude.md` archival: 40-archive-scratch-checkpoints.sh
- `projects/*.jsonl` pruning: 20-prune-transcripts.sh

**Rule:** if the description starts with "every now and then" or "sometimes I need to," it is a candidate for automation.

### 5. Anthropic-managed dirs are off-limits

`projects/`, `file-history/`, `tasks/`, `todos/`, `ide/`, `plugins/`, `statsig/`, `telemetry/`, `session-env/` (mostly), `sessions/` (mostly), `agents/`, `teams/` hold Claude Code's runtime data. Don't audit, don't reorganize, don't trash. Exception: extending a startup-script task to PRUNE (for example projects/*.jsonl by age) is fine, because that is deletion by policy and no restructure.

**See:** `FOLDERS.md` for the per-folder owner taxonomy.

---

## When to consolidate vs leave alone

| Signal | Consolidate | Leave |
|---|---|---|
| Multiple files share a prefix + shape | YES | n/a |
| Settings.json has 10+ blocks for one event type | YES (if event is bounded) | n/a |
| A backlog file duplicates another backlog file | YES | n/a |
| A directory has zero recent activity but documentation references it | YES, archive it | n/a |
| A pattern is interesting but only happens in 1 place | n/a | LEAVE (premature abstraction) |
| A script is referenced from external code you don't own | n/a | LEAVE (back-compat first) |
| You're "while I'm here" expanding scope | n/a | STOP |

---

## What counts as a "structural change"

A change is **structural** (and requires a migration entry under `~/.claude/migrations/`) when ANY of:

1. **A top-level `~/.claude/` directory is created, renamed, or deleted**
2. **A canonical file is moved, renamed, or its format changes** (anything other agents or scripts read by path)
3. **Settings.json hook architecture changes** (new event handler, removal, orchestrator introduction)
4. **A namespace cluster is added, renamed, or removed** (NAMESPACE.md tree change)
5. **A skill or script's path moves** AND any external caller (hook, script, doc) references it by path
6. **A data store schema changes** (events.jsonl, index.jsonl, MEMORY.md format)

NOT structural (no migration entry needed):
- Editing a script's internals without changing its CLI or output schema
- Adding entries to backlogs (proposals.jsonl, weekly-todos.md)
- Rotating logs
- Adding a new skill (creates a new path but doesn't move anything)
- Writing a report under `assets/`

---

## How to file a migration entry

Use `/migrate` (skill) for interactive creation, OR create the file manually:

```
~/.claude/migrations/NNNN-<slug>.md
```

Frontmatter and body shape: copy from `~/.claude/migrations/_TEMPLATE.md`.

Always update the `~/.claude/migrations/MIGRATIONS.md` index in the same change. Use the next free number.

---

## What clean looks like

- Root has CLAUDE.md, the 5 indices (LOOKUP, NAMESPACE, GLOSSARY, PLACEMENT, FOLDERS), the canonical state files (settings.json, mcp-catalog.json), and the active checkpoint symlink. No stray `_*.claude.md` (those archive monthly).
- Each top-level directory has either a README (if policy-bearing) or is referenced from FOLDERS.md (if pure-data).
- Backlogs: one per concern. proposals.jsonl for system improvements. weekly-todos.md for user-facing tasks. atone/events.jsonl for mistakes. affirm/events.jsonl for wins. No duplicates.
- /tmp/claude-* files cleared per cadence by a startup task.
- Anthropic-managed dirs untouched.

---

## See also

- `PLACEMENT.md`: where new rules, features and conventions go
- `FOLDERS.md`: the per-folder owner and purpose map
- `migrations/MIGRATIONS.md`: historical structural changes
- `assets/docs/20260517-gcc-audit-v1.md`: the recent consolidation audit

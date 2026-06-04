---
name: catchup
description: Resumes a session from a /core-dump checkpoint. Reads ~/.claude/checkpoints/ index when CWD is ambiguous (presents a picker), or a specific _checkpoint.claude.md when one is given. Restores session context with minimum token usage by loading only targeted file sections relevant to pending tasks, and presents a compact briefing to immediately resume work. Companion skill to /core-dump.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[filename | --session-id ID | --pick N]"
user-invokable: true
---

## Brief

Resume a cleared session from a `/core-dump` checkpoint with minimum exploration overhead. Parses the four-section checkpoint format, presents pending items first, loads only targeted file sections referenced by pending tasks — no full file reads, no broad codebase scans — then hands off cleanly for immediate work.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/catchup [filename | --session-id ID | --pick N]
```

| Argument          | Type     | Description                                                                                                                                                                                                            |
| ----------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `filename`        | optional | Explicit checkpoint file to read. Must follow `_*.claude.md` convention. When given, Phase 0.4 is skipped entirely — use this when you know exactly which file. Defaults to `_checkpoint.claude.md` in the project.    |
| `--session-id ID` | optional | Resolve via `~/.claude/checkpoints/<ID>.json`. Use when a long-running agent knows its own session-id and wants to skip the picker.                                                                                    |
| `--pick N`        | optional | Resolve the Nth most-recent entry in `~/.claude/checkpoints/index.jsonl` (1-based). Use to re-pick the same option from a previous picker non-interactively.                                                            |

When none of the above are passed and CWD is ambiguous (`~/.claude/` or not in a project), Phase 0.4 runs the auto/picker resolution flow.

## Phase 0.1 — Parse Arguments

Inspect the args string before any resolution work:

1. **`--session-id ID`** present → set `ARG_SESSION_ID=ID`. Skip the rest of Phase 0 entirely. Jump to Phase 0.3 to resolve directly:
   ```bash
   ~/.claude/scripts/checkpoint/resolve.sh --session-id "$ARG_SESSION_ID"
   ```
2. **`--pick N`** present → set `ARG_PICK_N=N`. Skip Phase 0.4 picker UI; resolve directly:
   ```bash
   ~/.claude/scripts/checkpoint/resolve.sh --pick "$ARG_PICK_N"
   ```
3. **Bare filename** (a token matching `_*.claude.md`) → set `ARG_FILENAME`. Skip Phase 0.4 (the user named the file).
4. **No args** → continue to Phase 0.4 for resolution.

If `resolve.sh` exits non-zero from `--session-id` or `--pick`, fall through to Phase 0.4 (the user's chosen reference is stale; let them pick fresh).

## Phase 0.3 — Direct Resolution (when `--session-id` or `--pick` was used)

The JSON entry returned by `resolve.sh` contains `checkpoint_path`, `project_root`, `name`, `summary`, `ts`. Run the Phase 0.4.4 validation + announce sequence on it (same checks as the picker path), then skip to Phase 1.3 (parse the checkpoint file).

## Phase 0.4 — Global Checkpoint Resolution (CHECK FIRST when CWD is `~/.claude/` OR no filename arg)

This phase exists to defeat the "stale `~/.claude/_checkpoint.claude.md` masquerading as project root" trap. After `/clear`, the new session's CWD often resets to `~/.claude/` rather than the project the previous session was working in. Without this phase, /catchup would Glob from `~/.claude/`, find a stale leftover checkpoint, and confidently load the wrong project's context.

### 0.4.1 — Decide whether to consult the global index

Consult `~/.claude/checkpoints/` when **any** of these conditions hold:

1. CWD is exactly `$HOME/.claude` (the global config dir — never a real project)
2. CWD does NOT contain a `.claude/` subdirectory (not in a project at all)
3. No `filename` argument was passed AND no `_checkpoint.claude.md` exists at the resolved project root

If the user passed an explicit `filename` argument, skip this phase — they've named the file they want.

### 0.4.2 — Try `--auto` resolution (single fresh entry)

```bash
~/.claude/scripts/checkpoint/resolve.sh --auto
```

Exit code meaning:
- `0` — exactly one checkpoint is fresh (<30 min); use it. Stdout is the JSON entry.
- `2` — multiple fresh entries OR no fresh entries but stale ones exist; **show picker** (next step).
- `3` — no checkpoints at all; fall through to Phase 0.5.

### 0.4.3 — Show picker (`mcp__inputs__pick_one`)

When `--auto` returned exit 2, render the list and prompt the user to pick:

```bash
~/.claude/scripts/checkpoint/list.sh --limit 8
```

This prints a numbered table with name / project / age / summary. Present via `mcp__inputs__pick_one`, with options labelled like:

```
[claude-audit]  ~/.claude (2h ago)
    Cleaning up ~/.claude folders, building FOLDERS.md
```

Plus a final "Enter a path manually" option (`text_input` follow-up).

Resolve the chosen option via `~/.claude/scripts/checkpoint/resolve.sh --pick <N>` and use that JSON entry.

### 0.4.4 — Validate and load

For whichever JSON entry was resolved (`--auto` or `--pick`):

- `checkpoint_path` exists on disk (project moved/deleted check)
- `project_root` is NOT `$HOME/.claude` (would re-trigger the trap)
- `ts` is younger than 7 days (older entries: warn but allow if user explicitly picked)

If valid, **announce clearly** before loading:

```
─────────────────────────────────────────────────────
  Loading checkpoint
─────────────────────────────────────────────────────
  Name:       <name>
  Project:    <project_root>
  Checkpoint: <checkpoint_path>
  Written:    <ts> (<N> hours ago)
  Summary:    <summary>

  If this is the wrong checkpoint, re-run as:
    /catchup <explicit-filename>
─────────────────────────────────────────────────────
```

Then read `checkpoint_path` directly and skip to **Phase 1.3** (parse). Do NOT continue to Phase 0.5 / 1.1 — those would re-find the wrong file.

### 0.4.5 — Back-compat fallback

`resolve.sh` already falls back to the legacy `~/.claude/_last-checkpoint.json` when the new index is empty. That fallback is removed in migration 0008 once all sessions have written to the new index at least once.

### 0.4.6 — CWD-trap hard-stop

If CWD is `$HOME/.claude` AND no entries exist in the index AND no `filename` arg was passed, **stop and ask** rather than scanning `~/.claude/` for `_*.claude.md` files. Print:

```
CWD is ~/.claude/ — this is the global config dir, not a project.
No entries in ~/.claude/checkpoints/index.jsonl either.

Options:
  1. cd to the project and re-run /catchup
  2. Pass an explicit checkpoint path: /catchup <filename>
```

Wait for user direction. Do NOT proceed to scan or load anything from `~/.claude/`.

---

## Phase 0.5 — Check WAL First (Fast Path)

Before looking for a checkpoint file, check if a Write-Ahead Log exists.
The WAL may be in either format — prefer JSONL, fall back to markdown:

1. **Try `.claude/wal.jsonl` first** (canonical format since 2026-04-17):
   - If found and **less than 24 hours old** (check `ts` of the last line):
     - Read the last checkpoint with:
       ```bash
       jq -c 'select(.kind == "checkpoint")' .claude/wal.jsonl | tail -1
       ```
     - Present `goal` / `done` / `current` / `next` / `blockers` fields from that object
     - Print: `Resumed from WAL (JSONL fast path). Last checkpoint at [ts].`
     - Skip directly to Phase 2 (targeted file loading), driving Phase 2 from the
       `next` field and any file paths referenced in recent `action` entries:
       ```bash
       jq -r 'select(.kind == "action" and .target) | .target' .claude/wal.jsonl | tail -20 | sort -u
       ```
2. **If `wal.jsonl` is missing, stale, or empty** — try `.claude/wal.md` (legacy):
   - Find the **last `=== CHECKPOINT ===` block**
   - Present Goal / Done / Current / Next / Blockers from the checkpoint
   - Print: `Resumed from WAL (legacy markdown fast path). Last checkpoint at [time].`
   - Skip directly to Phase 2 using the checkpoint's pending items
3. **If neither exists or both are stale (>24h)** — fall through to Phase 1 (checkpoint file).

This fast path avoids reading the larger `_checkpoint.claude.md` when the WAL has recent state.
Format reference: `skills/shared/wal-format.md`.

---

## Phase 0.8 — Read session workspace (if present)

Before the main checkpoint parse, read the resuming session's workspace doc. **Resolve it by session id, NOT via `_active.md`** — `session_id` is stable across resume, and multiple sessions can share a project dir, so the shared `_active.md` symlink may point at a *different* session's doc. Read `<notes-dir>/$CLAUDE_CODE_SESSION_ID.md` first; fall back to `_active.md` only if the session's own doc is absent. Its **Todos** (unchecked) and **Doc Links** are the most direct expression of "what the user was actually trying to do" and should anchor the briefing.

```bash
ND="$PROJECT/.claude/session-notes"; { [ "$PROJECT" = "$HOME/.claude" ] || [[ "$PROJECT" == */.claude ]]; } && ND="$PROJECT/session-notes"
DOC="$ND/${CLAUDE_CODE_SESSION_ID}.md"; [ -f "$DOC" ] || DOC="$ND/_active.md"
test -e "$DOC" && cat "$DOC"
```

When rendering the briefing in Phase 2, surface the workspace's unchecked Todos as the **immediate next steps** above (or in place of) the checkpoint's Pending Items. The workspace is the user-curated truth; the checkpoint is the agent's synthesis. When they disagree, the workspace wins.

On a revived session your live Task list starts empty, so these notes are the only record of open work. **Rehydrate them**: recreate the unchecked Todos (both the `## Todos` machine block — which mirrored the prior session's live task list — and any human-area items) as tasks via TaskCreate, so the session resumes with a populated, syncing task list rather than a stale doc.

Silently skip this phase if neither the session's own doc nor `_active.md` exists. (The `stop-sync` hook auto-creates `<sid>.md` once a session has more than a couple of tasks, so a substantive prior session will have left its own doc.)

## Phase 1 — Locate and Parse Checkpoint

### 1.1 Resolve filename

- If a `filename` argument was provided, use it.
- Otherwise default to `_checkpoint.claude.md`.

Use Glob to locate the resolved filename in the project root (the directory containing `.claude/`).

### 1.2 Handle missing file

If the file is **not found**:

1. Glob for all `_*.claude.md` files in the project root.
2. If matches exist: print the list and ask the user which one to use. Wait for their selection, then proceed with the chosen file.
3. If no `_*.claude.md` files exist at all: print a clear error and stop.

```
No checkpoint file found.
Run /core-dump first to create one, then re-run /catchup.
```

### 1.3 Parse the checkpoint

Read the checkpoint file. Extract the four sections produced by `/core-dump`:

1. **Initial Goal** — what the session was originally trying to accomplish
2. **Agent Actions** — sequential log of what was done (with file references)
3. **Current Expectation** — what the user expected to happen next at dump time
4. **Pending Items** — what still needs to be done

If any section is missing or the file does not match the expected structure, warn the user and present whatever content exists. Do not fail silently.

## Phase 2 — Extract File References

Scan the **Agent Actions** and **Pending Items** sections for file path references — tokens that look like file paths (contain `/`, end in `.ts`, `.tsx`, `.py`, `.md`, etc.).

Build an ordered reference list:

- Rank paths that appear in **Pending Items** first (most relevant to continuing work)
- Then paths from **Agent Actions** that relate to pending items
- Exclude paths from actions that are clearly already resolved

**Do not read any files yet.** This phase only builds the list.

Print the reference list so the user can see what will be loaded.

## Phase 3 — Present Briefing

### 3.1 Print the briefing in inverted order

Present sections in this order — start from "what's next", not "where we started":

```
─────────────────────────────────────────────────────
  Session Catchup
─────────────────────────────────────────────────────

  ▸ Pending Items
    [bullet list from checkpoint]

  ▸ Current Expectation
    [from checkpoint]

  ▸ Initial Goal
    [from checkpoint]

─────────────────────────────────────────────────────
```

### 3.2 Load targeted file context

For each file in the ranked reference list (Phase 2), load **only the relevant section** using Grep:

- If the action log cites a specific line or function: use Grep to extract ±10 lines around that reference
- If no specific location is cited: use Grep for the relevant symbol/function name
- Never read the full file — targeted context only

Print each loaded snippet with its source path and why it was loaded.

### 3.3 Load relevant runtime notes

Scan `.claude/skills/runtime-notes.md` for entries relevant to the task domain (match by skill names, file paths, or keywords mentioned in the checkpoint). Print any matching entries as "Learnings from previous runs" — these may prevent repeating past mistakes.

## Phase 4 — Hand Off

Print:

```
─────────────────────────────────────────────────────
  Context restored. Ready to continue.
─────────────────────────────────────────────────────
```

Then ask:

```
Which pending item should we start with?
→
```

Wait for the user's response before beginning any work. Do not make assumptions about priority or start executing autonomously.

## Notes

- **Input contract:** expects the four-section `_*.claude.md` format written by `/core-dump`. Sections are identified by `## Initial Goal`, `## Agent Actions`, `## Current Expectation`, `## Pending Items` headings.
- **Inverted presentation order is deliberate:** pending items → expectation → goal. The user knows their goal; they need to know what's left.
- **Targeted Grep over full Read:** reduces token usage for large referenced files. The checkpoint's agent actions log provides enough location context (file + symbol) to scope the Grep correctly.
- **Do not begin work autonomously:** always hand off with a question. The user may want to reprioritize or provide new context before continuing.
- **Malformed checkpoint:** if sections are missing, warn but do not stop — partial context is better than none.
- **Post-run:** write a runtime-notes entry via `prepend-runtime-note.sh` as per GUIDELINES.md §7.

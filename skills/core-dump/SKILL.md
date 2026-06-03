---
name: core-dump
description: Writes _checkpoint.claude.md (or a named file) to the project root — condensing the active session into original goal, sequential agent actions, current expectation, and pending items. Supports "mini" mode for quick abbreviated notes. Records a session-keyed pointer + chronological index entry under ~/.claude/checkpoints/ so multiple long-running agents do not clobber each other. Serves as a hand-off artifact for /catchup after /clear.
allowed-tools: Read, Write, Glob, Bash, Edit
argument-hint: "[mini] [filename] [--name NAME] [--no-prompt] [instructions]"
user-invokable: true
---

## Brief

Snapshot the active session into a structured `_checkpoint.claude.md` file (or a named alternative) in the project root. Captures the initial user goal, agent actions in sequence, current user expectation, and pending to-dos — focused on task context, not conversational tone. Designed as the hand-off artifact consumed by `/catchup` after `/clear`.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md`. Apply all rules — forbidden paths, retry logic,
tool preferences, verbosity, timeouts, post-run insights, and the **file lock protocol**
— for the entire duration of this skill run before proceeding.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock hygiene: run `bash ~/.claude/skills/shared/lock-file.sh cleanup` once at the start
> of this skill to clear any stale locks from crashed sessions. Then acquire a lock via
> `~/.claude/skills/shared/lock-file.sh acquire` before every Edit/Write, and release it
> immediately after. Never write to `runtime-notes.md` or any SKILL.md without holding
> its lock.

## Usage

```
/core-dump [mini] [filename] [--name NAME] [--no-prompt] [instructions]
```

| Argument       | Type     | Description                                                                                                                                                                                                                                            |
| -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mini`         | optional | If the first token is literally `mini`, run in **mini mode** — abbreviated checkpoint with just done/not-done/next-steps/goal. Designed for quick `/catchup` recovery, not thorough hand-off.                                                          |
| `filename`     | optional | Target filename for the checkpoint. Must end in `.md`. Defaults to `_YYYYMMDD-<session-id>.claude.md` (e.g., `_20260331-fix-auth-3b.claude.md`) if not provided. Also creates a symlink `_checkpoint.claude.md` → latest for `/catchup` compatibility. |
| `--name NAME`  | optional | Human-readable label for the checkpoint (shown in the `/catchup` picker). When supplied, skips the name prompt in Phase 3.5 and uses this value directly. Defaults to the session-id when not supplied.                                                |
| `--no-prompt`  | optional | Skip the interactive name/summary form in Phase 3.5. Use for headless / automated runs (CI, sub-agent). Defaults are still recorded.                                                                                                                    |
| `instructions` | optional | Free-form style or format instructions for this dump (e.g. "focus on design decisions only", "be very terse"). Ignored in mini mode.                                                                                                                   |

If both filename and instructions are present, the filename is detected first (starts with `_` or ends in `.md`), and all remaining text is treated as instructions.

## Phase 1 — Parse Arguments

1. Read the args string passed to the skill (may be empty).
2. **Check for mini mode:** If the first token is literally `mini` (case-insensitive), set `mode = mini` and remove it from the args. Otherwise `mode = full`.
3. **Pull out flag args** before treating remaining tokens as filename/instructions:
   - `--name <value>` — store as `ARG_NAME`, remove both tokens. The value may be quoted with spaces.
   - `--no-prompt` — set `ARG_NO_PROMPT=1`, remove the token.
4. Scan for a filename token: a word that ends in `.md` or starts with `_`. If found, use it as the output filename. Otherwise default to `_YYYYMMDD-<session-id>.claude.md` (using today's date and the current session ID). After writing, create/update a symlink `_checkpoint.claude.md` → the written file so `/catchup` always finds the latest.
5. Treat all remaining text in args as style/format instructions. Store them for use in Phase 2. (Ignored in mini mode.)
6. Print the resolved mode, filename, name (if supplied), and any instructions before proceeding.
7. **If mode is `mini`**, skip directly to **Phase 2-mini** below. Do not run Phase 2 (full).

## Phase 2-mini — Abbreviated Summary (mini mode only)

If `mode = mini`, produce a flat, scannable checkpoint. No deep analysis, no insights section, no `improvement-ideas.md` update. Just the essentials for `/catchup`:

1. **Goal** — 1-2 sentences: what the user originally asked for
2. **Done** — Bullet list of what was accomplished (files modified, features added, bugs fixed)
3. **Not Done** — Bullet list of what remains incomplete
4. **Next Steps** — Numbered list of immediate actions for the next agent, in priority order
5. **Key Files** — List of file paths that were central to the work

Write the mini checkpoint using this template:

```markdown
# Mini Core Dump — <ISO timestamp>

**Goal:** <1-2 sentences>

**Done:**

- <item>
- <item>

**Not Done:**

- <item>

**Next Steps:**

1. <step>
2. <step>

**Key Files:**

- `<path>`

---

_Generated by /core-dump mini. Resume with /catchup._
```

After writing, skip to **Phase 3** (write checkpoint) and then **Phase 4** (verification). Do not run the visual summary in mini mode — print only the standard verification block.

---

## Phase 2 — Summarize Session (full mode)

Analyze the full conversation and produce a structured summary. Focus on task context — skip session tone, pleasantries, and off-topic exchanges.

**Thoroughness checklist** — ensure every checkpoint covers:

- [ ] What was done (files modified, features added, bugs fixed)
- [ ] What are the next steps (in priority order)
- [ ] The original user goal (and any pivot mid-session)
- [ ] User feedback received (corrections, preferences, constraints)
- [ ] Tangential / additional scope that came up but wasn't addressed
- [ ] Insights — what worked, what didn't, problems faced, gotchas
- [ ] Notes for future agents (things not obvious from the code)
- [ ] Immediate steps (last item — what to do right now)

For insights that are broadly applicable (not project-specific), also append a dated entry to `~/.claude/improvement-ideas.md` (create with `# Claude Improvement Ideas` header if it doesn't exist).

> **Cross-reference (insight vs proposal — keep distinct):**
> - `improvement-ideas.md` — **general cross-project LEARNINGS** (tool bugs, shell gotchas, workflow patterns, "next time consider X"). Free-form markdown, dated entries. Not necessarily actionable; future agents read for context.
> - `~/.claude/proposals.jsonl` — **actionable system improvements** that someone should pick up and ship. Structured JSONL with status. Filed via `propose.sh add`.
> - `runtime-notes.md` — **skill-specific run history** (what happened when this skill was invoked, in this project).
>
> Routing rules:
> - "I learned X" / "X is a gotcha" / "consider X next time" → `improvement-ideas.md`
> - "We should build X" / "X needs fixing" → `propose.sh add ...` → `proposals.jsonl`
> - "When `/foo` was invoked, Y happened" → `runtime-notes.md`
>
> Some insights from `improvement-ideas.md` graduate to proposals when the user decides to act on them. That's expected; don't duplicate at write-time.

### 2.1 Initial User Goal

One to three sentences capturing what the user originally asked for at the start of this session. If the goal shifted mid-session, note the original goal and the pivot.

### 2.2 Agent Actions (Sequential Log)

A numbered list of actions taken, in order. For each action:

- State what was done and why (one line)
- For large data (file reads, API results, long code): reference the source path or describe what was found — do **not** reproduce the content verbatim
- For tool calls: note the tool used and the outcome
- For decisions or proposals: capture the decision, not the deliberation

Example entry:

```
3. Read src/data/pipeline/pipeline.types.ts — found PipelineArgs type mismatch at line 42; proposed fix captured below
```

### 2.3 Current User Expectation

One to two sentences: what does the user expect to happen next right now? What are they waiting for, or what are they about to do?

### 2.4 Pending Items / To-Dos

A bullet list of things that have not yet been done but are needed to complete the current task. Include both agent-side and user-side items.

Seed this from the live Task list first: read `~/.claude/tasks/<session-id>/*.json` (each is `{id, subject, status}`) and treat every non-`completed` task as a pending item. Then add anything the conversation surfaced that the task list missed. The live Task list is the freshest record of what's still open; the conversation only fills gaps.

### 2.5 Session Insights & Meta

Capture meta-observations about the session:

- **What worked well** — tools, approaches, or decisions that paid off
- **What didn't work** — dead ends, failed approaches, wasted effort
- **Gotchas encountered** — non-obvious traps or quirks discovered
- **Notes for future agents** — things the next agent should know that aren't in the code
- **User feedback received** — corrections, preferences, or constraints the user stated
- **Tangential / additional scope** — things that came up but weren't addressed

If any insight is broadly applicable (not project-specific), also append it as a dated entry to `~/.claude/improvement-ideas.md`. Create the file with a `# Claude Improvement Ideas` header if it doesn't exist.

### 2.6 Apply Style Instructions

If instructions were extracted in Phase 1, adapt the above sections accordingly:

- "focus on design decisions only" → collapse 2.2 to decisions only, drop procedural steps
- "be terse" → compress each section to the minimum viable content
- "include file references" → ensure every action in 2.2 cites a file path

If no instructions were given, use the default balanced style above.

## Phase 3 — Write Checkpoint

### 3.1 Locate project root

Use Glob to find `.claude/` in the working directory tree. The project root is the directory that contains `.claude/`. Print the resolved project root path.

### 3.2 Acquire lock and write

```bash
bash ~/.claude/skills/shared/lock-file.sh acquire "_checkpoint.claude.md" "core-dump"
```

Write the checkpoint file to `<project-root>/<resolved-filename>` using the Write tool. Structure:

```markdown
# Quick Summary (for LLMs) — <ISO timestamp>

> <3-5 sentence executive summary: what the session accomplished, what's in progress,
> what the immediate next step is, and any critical blockers. Written for an agent that
> will load this file first and decide what to read in detail below.>

# Core Dump — <ISO timestamp>

## Initial Goal

<2.1 content>

## Agent Actions

<2.2 numbered list>

## Current Expectation

<2.3 content>

## Pending Items

<2.4 bullet list>

## Session Insights

<2.5 content — what worked, what didn't, gotchas, notes for future agents>

---

_Generated by /core-dump. Resume with /catchup._
```

The **Quick Summary** must be the very first section — agents loading this file can read only the summary to decide whether to deep-dive into the full dump. Write it last (after all other sections are drafted) so it accurately reflects the complete state.

Then release the lock:

```bash
bash ~/.claude/skills/shared/lock-file.sh release "_checkpoint.claude.md" "core-dump"
```

### 3.3 Format the checkpoint

```bash
npx prettier --write <resolved-filename>
```

### 3.4 Additional context files (if needed)

If the summary is too large or fragmented to fit cleanly in one file, create supplementary files following the `_*.claude.md` convention (e.g., `_decisions.claude.md`, `_file-refs.claude.md`). Reference each from the main checkpoint under a `## Supplementary Files` section. This is the exception, not the default.

### 3.5 Prompt user for checkpoint name + summary

Before writing the global pointers, give the user a chance to set a human-readable **name** and a one-line **summary** for this checkpoint. These show up in the `/catchup` picker, so they're the user's anchor for finding this checkpoint later.

**Skip the prompt** when any of:
- `mode == mini` (latency-sensitive — use defaults silently)
- `ARG_NO_PROMPT == 1` (passed `--no-prompt`)
- `ARG_NAME` was already supplied (use it directly; auto-generate summary)
- No TTY / structured-output mode (CI, sub-agent context). Detection: if running inside a sub-agent task or under `claude -p` headless mode, skip.

Compute the defaults first:
- `DEFAULT_NAME` = `ARG_NAME` if set, else the current session-id (e.g. `auth-refactor-a7`)
- `DEFAULT_SUMMARY` = the first non-empty sentence of the checkpoint's "Original Goal" / Phase 2.1 capture, trimmed to ~80 chars

If skipping the prompt: set `CKPT_NAME=$DEFAULT_NAME`, `CKPT_SUMMARY=$DEFAULT_SUMMARY`, continue.

Otherwise, present `mcp__inputs__form` with both fields pre-filled. Schema:

```json
{
  "title": "Checkpoint name + summary",
  "description": "Press Enter to accept defaults — both fields show up in the /catchup picker.",
  "fields": [
    {
      "key": "name",
      "label": "Name",
      "type": "text",
      "default": "<DEFAULT_NAME>",
      "required": true,
      "help": "Short slug for the picker. Defaults to session-id."
    },
    {
      "key": "summary",
      "label": "Summary",
      "type": "text",
      "default": "<DEFAULT_SUMMARY>",
      "required": false,
      "help": "One-line description of what this checkpoint covers."
    }
  ]
}
```

On user submit: set `CKPT_NAME` and `CKPT_SUMMARY` from the form result.
On user cancel or tool error: fall back to defaults silently — never block on this prompt.

### 3.6 Write global pointers (MANDATORY)

Call the checkpoint writer — it handles all three writes (session-keyed pointer, chronological index, legacy back-compat) atomically:

```bash
~/.claude/scripts/checkpoint/write.sh \
  --session-id      "<session id slug>" \
  --session-uuid    "${CLAUDE_CODE_SESSION_ID:-}" \
  --project-root    "<absolute project root>" \
  --checkpoint-path "<absolute path to checkpoint file>" \
  --name            "$CKPT_NAME" \
  --summary         "$CKPT_SUMMARY"
```

The `--session-uuid` is the full Claude Code session UUID from `$CLAUDE_CODE_SESSION_ID`. It enables `/revive` to join checkpoints with the underlying transcript file at `~/.claude/projects/<encoded>/<uuid>.jsonl`.

This writes:
- `~/.claude/checkpoints/<session-id>.json` — your session's own pointer (no contention with other sessions)
- `~/.claude/checkpoints/index.jsonl` — append-only chronological log feeding the `/catchup` picker
- `~/.claude/_last-checkpoint.json` — legacy single-slot pointer (kept for back-compat during migration; readers stop using it after **migration 0008** ships, tracked by proposal `prop-20260515-141140-44`)

Why the directory + index instead of a single file: multiple long-running agents across different projects each get their own pointer. No last-writer-wins; no clobbering each other.

Print: `Checkpoint indexed as "$CKPT_NAME" — resume with /catchup`.

### 3.7 Workspace doc diff (optional, non-blocking)

If `<project>/.claude/session-notes/_active.md` exists, propose updates to it. Never blind-overwrite.

> **The `## Todos` machine block is auto-managed.** The region between
> `<!-- sync:auto:start -->` and `<!-- sync:auto:end -->` mirrors the live Task
> list and is rewritten by the `stop-sync` hook every turn — do NOT propose
> todos into it; they'd be overwritten on the next turn. Only propose
> `todos_new` for genuinely human-area items the Task list doesn't track. The
> high-value writeback from `/core-dump` is the durable narrative — notes,
> decisions, doc links — not the task checkboxes (those sync mechanically).

1. Build a JSON proposal from the Phase 2 synthesis:
   ```json
   {
     "todos_done":    [<usually empty — completed tasks sync into the block automatically>],
     "todos_new":     [<only human-area todos NOT present in the live Task list>],
     "notes_append":  [<2-3 most load-bearing observations from Phase 2.5>],
     "doclinks_new":  [<URLs / file refs cited this session, deduped>],
     "decisions_new": [<load-bearing choices from Phase 2.5 "What worked / didn't">]
   }
   ```

2. Show the diff:
   ```bash
   echo "$PROPOSAL_JSON" | \
     ~/.claude/scripts/session-notes/diff.sh \
       --project "$PROJECT" \
       --session-id "$SESSION_ID"
   ```

3. Confirm via `mcp__inputs__confirm` with 3 options:
   - `apply` (default) → pipe JSON to `apply.sh`
   - `edit` → write JSON to `/tmp/core-dump-ws-proposal-<sid>.json`, prompt user to edit, re-read, apply
   - `skip` → do nothing

Skip this phase silently if `_active.md` does not exist. (The `stop-sync` hook auto-creates it once a session has more than a couple of tasks, so on a substantive session it will usually be present; a trivial session legitimately has none.)

## Phase 4 — Visual Summary (full mode only)

After writing the checkpoint, render a CPU-dump style visual summary to the terminal using the `render-visual.sh` script. This is **terminal output only** — it is NOT written to the checkpoint file.

### 4.1 Write session data as JSON

Path: `/tmp/core-dump-data-<session-id>.json` — per-session naming prevents the stale-data hazard where a parallel session's renderer would pick up the previous session's data.

**Before writing:** if the file already exists, `trash` it. This file is ephemeral per-render — never reused across sessions.

```bash
test -f "/tmp/core-dump-data-<session-id>.json" && trash "/tmp/core-dump-data-<session-id>.json"
```

Then write the JSON with this schema:

```json
{
  "session_id": "<session-id>",
  "timestamp": "<ISO timestamp>",
  "goal": "<1-line original goal from Phase 2.1>",
  "status": "<in-progress | blocked | complete>",
  "expects": "<what user expects next, from Phase 2.3>",
  "files": [{ "path": ".../path/to/file", "change": "+N / -N" }],
  "pipeline": ["next action 1", "next action 2"],
  "interrupts": ["BLOCKED: ...", "WARN: ...", "NOTE: ..."],
  "stack_trace": ["action 1 summary", "action 2 summary"],
  "coprocessor": {
    "worked": ["what worked well"],
    "failed": ["what didn't work"]
  },
  "checkpoint_path": "<resolved checkpoint filename>"
}
```

- Truncate long file paths with `.../` prefix (e.g., `.../components/Nav.tsx`)
- Keep action summaries to ~60 chars max
- Use empty arrays `[]` for sections with no content — the renderer handles all empty states

### 4.2 Call the renderer

```bash
/bin/bash ~/.claude/skills/core-dump/render-visual.sh /tmp/core-dump-data-<session-id>.json
```

The script uses `gum` (via `gum-tui.sh`) to render styled, bordered panels for each section. It handles:

- **File truncation**: >6 files → show first 6, then `... and N more`
- **Stack compression**: >8 actions → first 3, `... (N more)`, last 3
- **Interrupt highlighting**: border turns red when interrupts are present
- **Empty states**: all sections render gracefully with `(none)` / `(no files modified)` placeholders
- **macOS bash 3.2 compatible** — no `mapfile`, no `local -a`

### 4.3 Skip in mini mode

Skip this entire phase in `mini` mode — no JSON write, no renderer call.

---

## Phase 5 — Verification

1. Read back the written file to confirm it exists and is non-empty.
2. Print a final summary:

```
─────────────────────────────────────────────────────
  ✓ Core dump written (<mode: full | mini>)
─────────────────────────────────────────────────────

  File:    <absolute path to checkpoint file>
  Mode:    <full | mini>
  Covers:  <one-line description of what was captured>

  Resume with: /catchup

─────────────────────────────────────────────────────
```

## Validation Examples

> **Visual test:** Run `render-visual.sh` with the test JSON files in `/tmp/test-core-dump-*.json` and verify each renders without errors.

### Example: Full session (happy path)

**Scenario:** Standard `/core-dump` after a complete bug-fix session. All 6 sections populated with moderate content. 3 files modified, 5 stack trace entries, no blockers.
**Expected behavior:**

- [ ] JSON written to `/tmp/core-dump-data-<session-id>.json` with all fields populated
- [ ] `render-visual.sh` exits 0 and renders all 6 styled panels (REGISTERS, CACHE, PIPELINE, INTERRUPTS, STACK TRACE, COPROCESSOR)
- [ ] Header panel shows session ID and timestamp
- [ ] Footer panel shows checkpoint path and `Resume: /catchup`
- [ ] Checkpoint file written and formatted with Prettier (Phase 3.3)

### Example: Empty/minimal session

**Scenario:** `/core-dump` invoked immediately after `/clear` with no meaningful work done. All sections present but with placeholder content.
**Expected behavior:**

- [ ] REGISTERS shows `(no work performed)` for Goal
- [ ] CACHE shows `(no files modified)` placeholder
- [ ] STACK TRACE shows `(no actions taken)` placeholder
- [ ] Renderer handles empty arrays without crashing (no unbound variable errors)
- [ ] Visual is not skipped — a minimal visual is always produced

### Example: Many files (>6 in CACHE)

**Scenario:** Refactoring session that touched 10+ files. CACHE section must show top 6 with overflow.
**Expected behavior:**

- [ ] First 6 file entries shown with `├─` tree prefix
- [ ] Last line is `└─ ... and N more` with correct count
- [ ] Long paths truncated with `.../` prefix in the JSON (e.g., `.../components/Nav.tsx`)
- [ ] Dot-leaders connect file names to change annotations

### Example: Long stack trace (>8 actions)

**Scenario:** Large feature session with 12+ agent actions. STACK TRACE must compress: first 3 + `... (N more)` + last 3.
**Expected behavior:**

- [ ] First 3 actions shown with `├─` prefix
- [ ] Middle line is `├─ ... (N more)` with accurate count of omitted actions
- [ ] Last 3 actions shown, final one with `└─` prefix
- [ ] Total visible lines = 7 (3 + ellipsis + 3), regardless of actual action count

### Example: Active blockers (INTERRUPTS populated)

**Scenario:** Debugging session blocked on external dependency. INTERRUPTS section has 3 items (BLOCKED, WARN, NOTE). Status is "blocked" in REGISTERS.
**Expected behavior:**

- [ ] REGISTERS Status shows `blocked`
- [ ] INTERRUPTS panel border turns red (border-foreground 1)
- [ ] All 3 interrupt items shown with `├─` / `└─` tree prefixes
- [ ] BLOCKED/WARN/NOTE prefixes are visible and not truncated

## Notes

- **No sub-agents.** Core-dump requires full parent conversation context (initial goal, all actions, current state). Sub-agents spawned with `context: fork` get an isolated context and cannot see the parent conversation. Passing the full conversation as a prompt parameter would exceed context limits and defeat the purpose. Evaluated and rejected 2026-04-06.
- Always overwrite — never append. The checkpoint is a point-in-time snapshot, not an append log.
- If no meaningful work has been done in the session (e.g., run immediately after `/clear`), write a minimal checkpoint noting the session was empty rather than skipping the write.
- All internal context files generated by Claude follow the `_*.claude.md` naming convention: start with `_`, end with `.claude.md`. Never use bare filenames like `checkpoint.md` for agent-generated context files.
- `/catchup` is the companion skill that reads this file to restore session context after `/clear`.
- **Pre-compact hook integration:** `~/.claude/scripts/session-mgmt/pre-compact-checkpoint.sh` runs automatically before ALL compaction events (auto and manual `/compact`). It writes a lightweight `_precompact-checkpoint.claude.md` and a WAL CHECKPOINT. This hook is the shell-level counterpart to `/core-dump mini` — it runs faster (no skill invocation) but captures less detail. The hook was updated 2026-04-06 to fire on all compaction, not just auto.
- Post-run: write a runtime-notes entry via `~/.claude/skills/shared/prepend-runtime-note.sh` as per GUIDELINES.md §7. Always use the absolute path — this skill may be called from any directory.

---
name: revive
description: Lists Claude Code session transcripts under ~/.claude/projects/, cross-references with the checkpoint index, presents a picker, and prints the exact `claude --resume <uuid>` command for the user to run. Use when the user wants to fully rehydrate a past session — not just a summary. Companion to /catchup (which restores task context from a checkpoint summary). /revive is heavier (full conversation rehydration) and runs from a different terminal since a Claude process cannot replace itself.
allowed-tools: Read, Glob, Grep, Bash
argument-hint: "[--project PATH] [--all] [--within DAYS]"
user-invokable: true
---

## Brief

Find past Claude Code session transcripts on disk and surface them with their associated checkpoint name/summary (when one exists). Present a picker. Print the exact `claude --resume <uuid>` command the user copies and runs from another terminal.

`/revive` does NOT exec — a Claude process cannot replace itself with another `claude` invocation. It hands the user a copy-paste command.

## When to use

- The user explicitly wants "to resume" or "to revive" or "to continue" a past session
- `/catchup` gave a summary but the user needs the full conversation context
- The user remembers a session from days ago and wants back into it

When NOT to use:
- The user just wants a quick reorientation → use `/catchup`
- The user is mid-session and wants to compact → use `/core-dump` first, then `/compact`

## Usage

```
/revive                          # transcripts for the CURRENT project (CWD-derived)
/revive --project PATH            # transcripts for a specific project
/revive --all                     # transcripts across ALL projects (recent N)
/revive --within DAYS             # constrain by recency (default 30)
```

## Phase 1 — Parse arguments

Extract `--project`, `--all`, `--within` from args. Defaults:
- `--project` = current CWD if it contains `.claude/`, else the project_root from `~/.claude/_last-checkpoint.json` if fresh, else prompt user to pick
- `--within` = 30 days

## Phase 2 — List candidates

```bash
~/.claude/scripts/checkpoint/list-transcripts.sh \
  ${PROJECT:+--project "$PROJECT"} \
  --within "${WITHIN_DAYS:-30}" \
  --limit 15 \
  --pretty
```

This prints a numbered table:
```
  #   NAME                  PROJECT                    AGE     SIZE    HAS-CKPT
  1   global-claude-audit   /Users/.../.claude         today   2MB     ✓
        └─ Audited ~/.claude: cleanup, FOLDERS.md, …
  2   (c5baf85e)            /Users/.../logger-crab     today   5MB     ·
  3   docs-gate-a7          /Users/.../logger-crab     1d      890KB   ✓
        └─ Drafting docs-gate ADR for the new module boundary
```

Transcripts without checkpoints show their UUID prefix in parens — user can still revive them, just without the named-summary context.

If the list is empty, say so and exit cleanly:
```
No transcripts found in <project> within last <N> days.
Try: /revive --all  (or widen --within)
```

## Phase 3 — Present picker

Use `mcp__inputs__pick_one` to let the user choose. Build options from the JSON output:

```bash
~/.claude/scripts/checkpoint/list-transcripts.sh \
  ${PROJECT:+--project "$PROJECT"} \
  --within "${WITHIN_DAYS:-30}" \
  --limit 15
# (no --pretty → outputs JSONL)
```

For each row, label format:
```
[<name OR (uuid-prefix)>]  <age>  ·  <project basename>
    <summary if available>
```

Add a final "Open transcript file directly" option that just prints the path (useful if user wants to grep/inspect instead of resume).

## Phase 4 — Output the resume command

For the picked transcript, the JSON entry has `transcript` (full path) and `session_id` (UUID). Print:

```
─────────────────────────────────────────────────────
  Resume command (run in another terminal)
─────────────────────────────────────────────────────

  cd <project>
  claude --resume <uuid>

  Transcript:  <full path>
  Checkpoint:  <name> — "<summary>"   (or "(no checkpoint)")
  Last touched: <age>
─────────────────────────────────────────────────────
```

Do NOT attempt to exec. The user runs it themselves.

## Tips for the user (in the output)

- `--fork-session` on the resume creates a NEW session UUID — useful for branching off without disturbing the original conversation
- `claude --resume` opens an interactive picker if you omit the UUID
- For PR-linked sessions: `claude --from-pr <#>` is more direct than `/revive`

## Notes

- Cannot self-exec. A Claude process running `claude --resume` would either fork a child (the child runs in the new conversation) or attempt to replace itself (which would terminate the current session). Neither is acceptable for an interactive skill — the user MUST run the resume command from a separate terminal/tab.
- If the user is in a terminal multiplexer (tmux, zellij), `/revive` can suggest opening a new pane/window with the resume command pre-filled.
- The checkpoint join (HAS-CKPT column) uses `session_uuid` field added in 2026-05-15 enhancement. Older checkpoint entries without `session_uuid` fall back to session-id prefix match — sometimes imperfect.

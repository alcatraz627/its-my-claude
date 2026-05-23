# /catchup — Usage Guide

## What it does

Resumes a cleared session from a `/core-dump` checkpoint with minimum token overhead.
Reads `_checkpoint.claude.md` (or a named file), presents pending items first, loads
only targeted file sections referenced by the pending tasks, then hands off cleanly for
immediate work — no broad scans, no full file reads.

## Usage

```
/catchup [filename]
```

| Argument   | Type     | Description                                                                                          |
| ---------- | -------- | ---------------------------------------------------------------------------------------------------- |
| `filename` | optional | Checkpoint file to read. Must follow `_*.claude.md` convention. Defaults to `_checkpoint.claude.md`. |

## Examples

### Example 1: Default resume

```
/catchup
```

Reads `_checkpoint.claude.md` from the project root. Prints a briefing with pending items
first, loads only the file sections cited in the top pending tasks via Grep, then asks
which item to start with.

### Example 2: Named checkpoint

```
/catchup _decisions.claude.md
```

Reads `_decisions.claude.md` — a focused checkpoint written with `/core-dump _decisions.claude.md "design decisions only"`. Restores design-decision context and presents pending architectural choices.

### Example 3: Mid-debug resume

```
/catchup
```

Checkpoint contains: goal ("fix pipeline type error"), last action (read `pipeline.types.ts`,
identified mismatch at line 42, proposed fix). Catchup loads only `pipeline.types.ts` lines
38–48 via Grep, presents the fix proposal, and asks whether to apply it.

### Example 4: File not found

```
/catchup
```

`_checkpoint.claude.md` does not exist. Catchup globs for `_*.claude.md` files in the
project root, finds `_before-refactor.claude.md` and `_decisions.claude.md`, and asks
the user which one to use.

## Caveats

- Requires a checkpoint file written by `/core-dump` — the four-section format
  (`## Initial Goal`, `## Agent Actions`, `## Current Expectation`, `## Pending Items`)
  is the expected input contract.
- If sections are missing from a malformed checkpoint, the skill warns and continues with
  whatever is present — partial context is better than nothing.
- Does not start work autonomously — always ends with a question before executing.
- Targeted Grep is used instead of full file reads; if a referenced file has moved or been
  deleted since the checkpoint was written, the Grep will fail gracefully with a warning.

## Dependencies

| Dependency              | Type         | Notes                                            |
| ----------------------- | ------------ | ------------------------------------------------ |
| `GUIDELINES.md`         | Shared rules | Read at start of every run                       |
| `runtime-notes.md`      | Shared log   | Scanned for task-domain learnings after briefing |
| `/core-dump`            | Skill        | Writes the checkpoint file this skill reads      |
| `_checkpoint.claude.md` | File         | Default checkpoint; must exist in project root   |

## Tips

- Always run `/core-dump` just before `/clear` — then `/catchup` immediately after starting the new session.
- Use named checkpoints (`/core-dump _pre-refactor.claude.md`) when working on parallel tracks; `/catchup _pre-refactor.claude.md` restores that specific context.
- The briefing presents **pending items first** — scan them before deciding where to start. The initial goal is shown last for context, not action.
- If the checkpoint references many files, only the top-ranked (most relevant to pending items) are loaded — you can ask to load additional references manually.

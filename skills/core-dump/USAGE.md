# /core-dump — Usage Guide

## What it does

Writes a structured `_checkpoint.claude.md` (or a named alternative) to the project root,
condensing the active session into a comprehensive hand-off artifact. Supports two modes:

- **Full mode** (default): Detailed checkpoint with goal, actions, insights, visual summary
- **Mini mode**: Abbreviated checkpoint with just done/not-done/next-steps for quick `/catchup`

Designed as the hand-off artifact for `/catchup` after `/clear`.

## Usage

```
/core-dump [mini] [filename] [instructions]
```

| Argument       | Type     | Description                                                                                                       |
| -------------- | -------- | ----------------------------------------------------------------------------------------------------------------- |
| `mini`         | optional | If the first token is `mini`, run in abbreviated mode — just done/not-done/next-steps/goal. Ignores instructions. |
| `filename`     | optional | Output filename. Must end in `.md`. Defaults to `_YYYYMMDD-<session-id>.claude.md`.                               |
| `instructions` | optional | Style/format instructions for the dump (e.g. "focus on design decisions only", "be terse", "decisions").          |

Filename is detected as the first token that starts with `_` or ends in `.md`. Everything
else is treated as instructions. In mini mode, instructions are ignored.

## Examples

### Example 1: Default full checkpoint

```
/core-dump
```

Writes `_YYYYMMDD-<session-id>.claude.md` (+ `_checkpoint.claude.md` symlink) to the project
root with a Quick Summary, four-section detailed dump, insights, and a CPU-dump visual summary
in the terminal.

### Example 2: Mini checkpoint for quick recovery

```
/core-dump mini
```

Writes a flat, scannable checkpoint: Goal, Done, Not Done, Next Steps, Key Files. No insights,
no visual summary, no `improvement-ideas.md` update. Fastest path to `/catchup` recovery.

### Example 3: Named file with focus instructions

```
/core-dump _decisions.claude.md "focus on design decisions only"
```

Writes `_decisions.claude.md` containing only the architectural and design decisions made
during the session — procedural steps and tool calls are collapsed or omitted.

### Example 4: Mid-debug snapshot

```
/core-dump
```

Called mid-investigation. Writes a checkpoint capturing: goal ("fix pipeline type error"),
actions (read `pipeline.types.ts`, identified mismatch at line 42, proposed fix), current
state (awaiting user to apply fix), pending (verify build passes after fix). Includes a
CPU-dump visual in the terminal showing the session flow.

## Output Structure

### Full mode

```
# Quick Summary (for LLMs) — <timestamp>
> Executive summary for agents...

# Core Dump — <timestamp>
## Initial Goal
## Agent Actions
## Current Expectation
## Pending Items
## Session Insights
```

Plus a CPU-dump visual summary printed to terminal (not in the file).

### Mini mode

```
# Mini Core Dump — <timestamp>
**Goal:** ...
**Done:** ...
**Not Done:** ...
**Next Steps:** ...
**Key Files:** ...
```

## Pre-compact Hook Integration

The PreCompact hook (`~/.claude/scripts/pre-compact-checkpoint.sh`) runs automatically before
ALL compaction events (auto and manual `/compact`). It writes a lightweight
`_precompact-checkpoint.claude.md` — the shell-level counterpart to `/core-dump mini`. The
hook is faster (no skill invocation) but captures less detail since it doesn't have access to
the full conversation context.

## Caveats

- Always **overwrites** — never appends. Each `/core-dump` is a full point-in-time snapshot.
- Does not reproduce large data blocks (file reads, API results, code) verbatim — references them by path or description only.
- If run immediately after `/clear` with no work done, writes a minimal "session was empty" checkpoint rather than failing.
- Requires `/catchup` to be available to resume from the checkpoint; this skill does not implement the resume itself.
- All generated context files follow the `_*.claude.md` naming convention.
- Sub-agents **cannot** be used for core-dump — they lack parent conversation context.
- Full mode updates `~/.claude/improvement-ideas.md` with broadly applicable insights.

## Dependencies

| Dependency                  | Type         | Notes                                            |
| --------------------------- | ------------ | ------------------------------------------------ |
| `GUIDELINES.md`             | Shared rules | Read at start of every run                       |
| `lock-file.sh`              | Shared tool  | Used to safely acquire/release file write lock   |
| `/catchup`                  | Skill        | Companion skill that reads the checkpoint file   |
| `pre-compact-checkpoint.sh` | Hook script  | Fires before compaction, writes lightweight dump |

## Tips

- Run `/core-dump` just before `/clear` to preserve session context across a clean restart.
- Use `/core-dump mini` when you just need a quick bookmark — don't need the full analysis.
- Use the `instructions` arg to tailor the dump for specific use cases — "decisions only" is useful when handing off architectural work to another session.
- Keep the default filename so `/catchup` can find it without arguments.
- If you need to preserve multiple snapshots, use named files (`_before-refactor.claude.md`, `_after-auth-fix.claude.md`) — each run overwrites its own file independently.

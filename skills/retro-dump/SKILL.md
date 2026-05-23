---
name: retro-dump
description: Manually trigger a retroactive /core-dump on a past session that ended without one. Headless — spawns `claude -p --resume <uuid>` to read the transcript and synthesize a /core-dump mini. Use when a session crashed mid-work, ran out of context without /core-dump'ing, or you want to backfill a checkpoint after the fact. Cost-aware (one LLM call per session) — guarded by MIN_TURNS / MAX_AGE_DAYS.
allowed-tools: Read, Bash, Glob
argument-hint: "[--uuid UUID | --last | --queue] [--min-turns N] [--max-age-days N]"
user-invokable: true
---

## Brief

Run `/core-dump mini` against a past Claude Code session transcript without entering that session interactively. Useful for crashed sessions, abandoned ones, or filling in the checkpoint index after the fact.

## When to use

- A session crashed before `/core-dump` — you have the transcript but no summary
- Long-tail backfill: "I had a productive session 3 days ago, I should checkpoint it now"
- The SessionStart hook surfaced "you have N unmatched sessions" — drain a few

## When NOT to use

- The session is still active in another terminal — use `/core-dump` from there
- You just want a quick read of the transcript — use `/past-sessions`

## Usage

```
/retro-dump --uuid <UUID>         # one specific session
/retro-dump --last                # the most recent unmatched session in CWD's project
/retro-dump --queue               # drain the queued backlog (up to MAX_PER_RUN=3)
/retro-dump --scan                # show candidates without running
```

## Phase 1 — Resolve target

If `--uuid` given: use it directly.

If `--last`: run `~/.claude/scripts/checkpoint/retro-scan.sh --print --limit 1` scoped to current CWD's project; pick the first row.

If `--queue` or `--scan`: skip Phase 1.

## Phase 2 — Confirm cost intent

Each retro-dump is one LLM call. Show the picker before firing:

```
About to retro-dump:
  UUID:         2edcbebe…
  Project:      ~/.claude
  Age:          2.3 days
  Transcript:   ~/.claude/projects/-Users-…/2edcbebe-….jsonl (2 MB)

  Cost estimate: ~5-15K tokens (mini mode)
  Proceed? [y/N]
```

Use `mcp__inputs__confirm` for the prompt. Default no.

## Phase 3 — Execute

```bash
~/.claude/scripts/checkpoint/retro-dump.sh --uuid "$UUID"
```

OR for queue mode:
```bash
~/.claude/scripts/checkpoint/retro-dump.sh --queue --max-per-run 3
```

The script handles timeout, log capture (`~/.claude/logs/retro-dump.log`), and queue file cleanup.

## Phase 4 — Output

```
─────────────────────────────────────────────────────
  Retro-dump complete (N processed)
─────────────────────────────────────────────────────
  Successes: K
  Failed:    F  (preserved in ~/.claude/checkpoints/retro-queue/failed/)

  View results: bash ~/.claude/scripts/checkpoint/list.sh --limit 10
─────────────────────────────────────────────────────
```

## Notes

- The retro-dumped checkpoint lands in `index.jsonl` with `kind=retro` and name `retroactive-<uuid8>`.
- Failures are NOT auto-retried — they sit in `retro-queue/failed/` with the return code and timestamp. Inspect with `ls ~/.claude/checkpoints/retro-queue/failed/`.
- Cost guardrail: `--max-per-run 3` is a hard cap. Override with care.
- The SessionStart hook (`40-retro-checkpoint-queue.sh`) and startup task (`30-retro-checkpoint-flush.sh`) handle the AUTO path. `/retro-dump` is for MANUAL control.

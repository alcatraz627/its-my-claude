---
brief: Write-ahead log (.claude/wal.jsonl): session lifecycle events, checkpoint cadence, /catchup contract
triggers:
  - tool:wal
  - topic:session-recovery
  - skill:catchup
  - skill:core-dump
  - phrase:"write-ahead log"
related: [features/context-retention.md]
tier: 1
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Wal
Write-ahead log at `.claude/wal.jsonl` (project-local) or `~/.claude/wal.jsonl` (global). Canonical format since 2026-04-17. **Maintain automatically — don't wait for the user to ask.**

## Core rules

- Append-only during session. Keep only last 2 sessions.
- JSONL: one JSON object per line. Required fields: `ts`, `kind`, `session_id`, plus kind-specific body.
- Skip trivial reads. Compress aggressively — one event per line.
- `jq`-queryable. Last checkpoint: `jq -c 'select(.kind == "checkpoint")' .claude/wal.jsonl | tail -1`

## Event kinds

`session_start` → `action` / `decision` / `bash_intent` / `bash_closed` / `tool_intent` / `agent_start` / `agent_done` / `turn_start` / `heartbeat` → `checkpoint` (every ~15-20 actions and before risky ops) → `session_end`.

## Checkpoint body

`goal` / `done[]` / `current` / `next` / `blockers[]` / `learnings[]` — all one line. Written at tool count ~30, before risky operations, and on user break signals.

## /catchup contract

`/catchup` reads `.claude/wal.jsonl` first → finds last `checkpoint` line → resumes from `current` / `next`. Falls back to `.claude/wal.md` (legacy markdown), then to `_checkpoint.claude.md`.

## Writing WAL entries safely

Never hand-compose JSONL. Use `bash ~/.claude/scripts/wal/wal.sh <kind> '<fields>'` which wraps `jq -cn` for safe escaping.

## Full format spec

See `~/.claude/skills/shared/wal-format.md` for complete field reference, parser states, and migration history.

## Legacy markdown WAL

`.claude/wal.md` is still honored by `/catchup` as a fallback. No migration required for existing projects — new sessions write JSONL, old markdown keeps working.

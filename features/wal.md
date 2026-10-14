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
The write-ahead log lives at `.claude/wal.jsonl` (project-local) or `~/.claude/wal.jsonl` (global). The format has been canonical since 2026-04-17. **Maintain it automatically, without waiting for the user to ask.**

## Core rules

- Append-only during the session. Keep only the last 2 sessions.
- JSONL: one JSON object per line. Required fields: `ts`, `kind`, `session_id`, plus a kind-specific body.
- Skip trivial reads. Compress aggressively, with one event per line.
- It is `jq`-queryable. Last checkpoint: `jq -c 'select(.kind == "checkpoint")' .claude/wal.jsonl | tail -1`

## Event kinds

`session_start` → `action` / `decision` / `bash_intent` / `bash_closed` / `tool_intent` / `agent_start` / `agent_done` / `turn_start` / `heartbeat` → `checkpoint` (every ~15-20 actions and before risky ops) → `session_end`.

## Checkpoint body

`goal` / `done[]` / `current` / `next` / `blockers[]` / `learnings[]`, each on one line. Written at tool count ~30, before risky operations, and on user break signals.

## /catchup contract

`/catchup` reads `.claude/wal.jsonl` first, finds the last `checkpoint` line, and resumes from `current` / `next`. It falls back to `.claude/wal.md` (legacy markdown), then to `_checkpoint.claude.md`.

## Writing WAL entries safely

Never hand-compose JSONL. Use `bash ~/.claude/scripts/wal/wal.sh <kind> '<fields>'`, which wraps `jq -cn` for safe escaping.

## Full format spec

See `~/.claude/skills/shared/wal-format.md` for the complete field reference, parser states and migration history.

## Legacy markdown WAL

`/catchup` still honors `.claude/wal.md` as a fallback. Existing projects need no migration: new sessions write JSONL, and old markdown keeps working.

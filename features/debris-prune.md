---
brief: The monthly sweep of old Claude checkpoints, handbacks, WALs and backups across the machine, what it archives or trashes, and how to undo a run.
triggers:
  - topic:debris
  - topic:checkpoint-archive
  - phrase:"debris-prune"
  - phrase:"prune checkpoints"
related: [features/context-retention.md, conventions/scratch-files.md, rules/scheduling-discipline.md]
tier: 2
category: features
updated: 2026-11-04
stale_after_days: 180
---

# Debris prune

Claude sessions leave files in every project they touch. On the first of each month at 04:20, `~/.claude/scripts/debris/debris-prune.py` moves the ones worth keeping to `~/.claude/assets/checkpoints/` and sends the rest to the Trash. Nothing is deleted outright, and `/catchup` still finds a moved checkpoint because its pointer is rewritten.

| What | Older than | Goes to |
|---|---|---|
| `_YYYYMMDD-*.claude.md` and other `_*checkpoint*.claude.md` | 30 days | Archive, with its pointers and index rows rewritten |
| `_codex-handback*.claude.md` | 30 days | Archive |
| Backups (`*.bak*`, `*.orig`, `*.rej`) inside a `.claude` folder | 60 days | Archive, under `bak/` |
| A project's `.claude/wal.jsonl` and its lock | 60 days | Trash |
| `.DS_Store` under `~/Code` and `~/.claude` | 30 days | Trash |
| A checkpoint pointer whose file no longer exists | 90 days | Trash |
| Half-written temp files in `~/.claude/checkpoints` | 1 day | Trash |
| A `_checkpoint.claude.md` link that is stale or lost its target | 30 days | Removed; the undo restores it |

## What it never touches

Any git-tracked file. Any other `_*.claude.md`, because a hand-named note may be a living document however old it is. `.env` backups, because they hold secrets. These folders: `assets/backups`, `assets/reports`, `archive`, `backups`, `skills-parked`, `atone`, `atone-snapshots`, `kanban` and `~/Code/Claude/its-my-config`.

It also leaves two large folders alone, because `cleanupPeriodDays` is set to 365 on purpose: `~/.claude/file-history` (1.2 GB) and `~/.claude/projects` (18 GB).

## Running it

```
python3 ~/.claude/scripts/debris/debris-prune.py --dry-run --list   # every file it would touch
python3 ~/.claude/scripts/debris/debris-prune.py                    # run now
python3 ~/.claude/scripts/debris/debris-prune.py --undo RUN_ID      # put a run's moves back
```

Each run records its actions in `assets/checkpoints/manifest.jsonl` and prints its run id; the latest summary is in `assets/checkpoints/last-run.txt`. An undo restores what was archived. Files in the Trash come back through Finder's Put Back.

To change an age, edit `DAYS` in the script. To change what is off limits, edit `KEEP_TREES`. The schedule is `gcc-schedule show debris-prune`, and `gcc-schedule rm debris-prune` retires it.

Tests: `python3 ~/.claude/scripts/debris/debris-prune.test.py`.

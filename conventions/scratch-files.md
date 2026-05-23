---
brief: ~/.claude/_*.claude.md scratch-file hygiene: naming, monthly archive to assets/checkpoints/YYYYMM/
triggers:
  - topic:scratch-files
  - topic:checkpoints
  - skill:core-dump
related: [features/context-retention.md]
tier: 2
category: conventions
updated: 2026-04-24
stale_after_days: 90
---

# Scratch Files
Hygiene rules for `~/.claude/_*.claude.md` scratch and checkpoint files.

## Naming convention

- `_checkpoint.claude.md` — session-rolling checkpoint (overwritten each session)
- `_precompact-checkpoint.claude.md` — auto-saved before compaction
- `_YYYYMMDD-<slug>-<sid2hex>.claude.md` — dated scratch files (per session)

All scratch files at the `~/.claude/` root start with `_` and end with `.claude.md`. They are `.gitignore`d.

## Monthly archival — MANDATORY (going forward)

Scratch files older than **14 days** must be archived monthly to:

```
~/.claude/assets/checkpoints/YYYYMM/
```

Archive command (to be wired into `/core-dump` or a weekly hook — see proposals):

```bash
# month_ago=$(date -v-14d +%Y-%m-%d)
# Move _YYYYMMDD-*.claude.md files with date < month_ago to assets/checkpoints/YYYYMM/
```

## Why this matters

As of 2026-04-24, **30** `_20260*-*.claude.md` files had accumulated at the root since March — no archival was happening. This produces visual noise in `ls ~/.claude/`, increases risk of accidental load into context, and makes `/catchup` harder (it can't tell stale from current).

## Quick retrieval — common commands

Browse / search live and archived scratch files:

```bash
# Most recent scratch at root (excluding session-rolling checkpoints)
ls -t ~/.claude/_2026*-*.claude.md | head -10

# Find by session id across live + archives
/usr/bin/grep -rl "<sid>" ~/.claude/_*.claude.md ~/.claude/assets/checkpoints/ 2>/dev/null

# Find by keyword in content
/usr/bin/grep -r "<keyword>" ~/.claude/assets/checkpoints/ | head -20

# Count of pending scratch files at root (should stay small)
ls ~/.claude/_20260*-*.claude.md 2>/dev/null | wc -l

# Which month does a dated filename map to (for archival)
echo "_20260424-restructure-7a.claude.md" | /usr/bin/awk -F'[_-]' '{print substr($2,1,6)}'
# → 202604

# Archive a specific scratch file to the right month
SF=_20260324-old-session.claude.md
YYYYMM=$(echo "$SF" | /usr/bin/awk -F'[_-]' '{print substr($2,1,6)}')
mkdir -p ~/.claude/assets/checkpoints/"$YYYYMM" && mv ~/.claude/"$SF" ~/.claude/assets/checkpoints/"$YYYYMM"/
```

## Related

- **Scratchpad system** (different concept — plans/learnings, not session checkpoints): [`~/.claude/scratchpad/README.md`](../scratchpad/README.md)
- **Scratchpad scripts:** `~/.claude/scratchpad/scripts/` — CLI helpers for the scratchpad feature
- **core-dump / catchup lifecycle:** [`features/context-retention.md`](../features/context-retention.md)

## Exceptions

`_checkpoint.claude.md` and `_precompact-checkpoint.claude.md` are session-rolling — **never archive these**, they always reflect the most recent state.

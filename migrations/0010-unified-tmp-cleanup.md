---
migration: 0010
title: Unified /tmp/claude-* cleanup (rename 10-cleanup-tab-state.sh → 10-cleanup-tmp-state.sh)
session: claude-audit-2e@2026-05-17
status: complete
date: 2026-05-17
---

# Migration 0010 — Unified /tmp/claude-* Cleanup

## Why

The original startup task only cleaned `/tmp/claude-tab-*`. Live scan on 2026-05-17 showed:

| Prefix | Count | Cleaned? |
|---|---|---|
| tab | 231 | YES (existing task) |
| turns | 112 | NO |
| tools | 17 | NO |
| edits | 15 | NO |
| timeline | 14 | NO |
| net | 14 | NO |
| fchg | 14 | NO |
| statusline | 13 | NO |
| last | 12 | NO |

8 prefixes accumulating forever. Audit doc § D.

## What changes

| From | To |
|---|---|
| `scripts/startup/tasks/10-cleanup-tab-state.sh` (tab-only) | `scripts/startup/tasks/10-cleanup-tmp-state.sh` (all prefixes) |

The new script iterates a list of known prefixes (tab, turns, tools, edits, timeline, net, fchg, statusline, last, ctxwatch). Same `--retain-days 7` default.

## What does NOT change

- Cleanup cadence (once per startup, login-triggered LaunchAgent)
- Default retention (7 days)
- Source-of-truth scripts that WRITE the files — unchanged; cleanup is independent
- Other startup tasks (`20-prune-transcripts.sh`, `30-retro-checkpoint-flush.sh`, `40-archive-scratch-checkpoints.sh`)

## Verification

- [x] New task script written
- [x] Tab-state still cleaned (covered by `prefixes` array)
- [ ] Dry-run shows expected per-prefix counts
- [ ] Old script trashed (after dry-run confirms new task works)

## Rollback

```bash
# Restore original tab-only task:
mv ~/.claude/scripts/startup/tasks/10-cleanup-tmp-state.sh \
   ~/.claude/scripts/startup/tasks/_disabled-10-cleanup-tmp-state.sh
# The pre-rename version is recoverable from git history or from earlier
# checkpoint files referencing it.
```

## Phases

1. **Phase 1** — Write new unified script ✅
2. **Phase 2** — Dry-run validation ⏳
3. **Phase 3** — Trash old `10-cleanup-tab-state.sh` ⏳

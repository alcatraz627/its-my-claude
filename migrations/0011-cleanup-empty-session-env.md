---
migration: 0011
title: Defensive cleanup of empty session-env/ subdirs
session: claude-audit-2e@2026-05-17
status: complete
date: 2026-05-17
---

# Migration 0011 — Defensive Cleanup of Empty session-env/ Subdirs

## Why

`~/.claude/session-env/` is Anthropic-managed per FOLDERS.md but contains 834 EMPTY subdirs (0 non-empty). Claude Code appears to create them speculatively per session for env snapshots that never materialize. They accumulate forever.

Audit doc § H.

## What changes

- Add `scripts/startup/tasks/50-cleanup-empty-session-env.sh`
- Uses `rmdir` (NOT `rm -r` / `trash`) — refuses to delete non-empty dirs as a defensive guarantee
- Default: removes empty subdirs older than 7 days

## What does NOT change

- `~/.claude/session-env/` itself remains (Anthropic creates it)
- Any NON-empty subdir is preserved (`rmdir` no-ops)
- Other Anthropic-managed dirs (`projects/`, `tasks/`, `todos/`, `file-history/`, `ide/`, `plugins/`, `statsig/`, `telemetry/`, `sessions/`) — NOT touched

## Verification

- [x] Script uses `rmdir` (verified — line 47)
- [ ] Dry-run shows expected count
- [ ] Live run reduces empty subdir count
- [ ] Anthropic-managed source-of-truth tests pass: a new session creates a new `session-env/<uuid>/` (unaffected by this cleanup)

## Rollback

```bash
# Disable the task:
mv ~/.claude/scripts/startup/tasks/50-cleanup-empty-session-env.sh \
   ~/.claude/scripts/startup/tasks/_disabled-50-cleanup-empty-session-env.sh
```

Restoration of removed subdirs is unnecessary — they're recreated as needed by Claude Code.

## Phases

1. **Phase 1** — Write task script ✅
2. **Phase 2** — Dry-run validation ⏳
3. **Phase 3** — Auto-runs on next login via startup orchestrator ✅

## Notes / followups

- If a future Claude Code version starts POPULATING these dirs, the rmdir failsafe protects us — task becomes a no-op silently.
- If this becomes an issue, mute via `mv .../50-cleanup-empty-session-env.sh .../_disabled-50…`.
- Open question for upstream: is the empty-dir-per-session intentional, or a bug? Worth filing.

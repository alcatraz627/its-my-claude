---
migration: 0013
title: Hook orchestrator for SessionStart + Stop (Option C — parallel)
session: claude-audit-2e@2026-05-17
status: in-progress
date: 2026-05-17
---

# Migration 0013 — Hook Orchestrator for SessionStart + Stop

## Why

`SessionStart` had 11 hook registrations and `Stop` had 10 — each managed separately in settings.json. Adding / disabling / reordering meant editing settings.json directly, with 6 lines of boilerplate per change. The orchestrator pattern (already used by `std::claude::startup`) collapses N registrations into one + a `.tasks` config file. Option C (parallel fork) preserves Claude Code's per-registration parallelism — net cost is ONE extra parent subprocess per event (~5-10 ms).

Audit doc § F. Per user direction Q3: "performance > cleanliness, but Option C gives both."

## What changes

| Event | From | To |
|---|---|---|
| `SessionStart` | 11 blocks in settings.json | 1 block: `hook-orchestrator/run.sh SessionStart` |
| `Stop` | 10 blocks in settings.json | 1 block: `hook-orchestrator/run.sh Stop` |

Task lists move to:
- `~/.claude/scripts/hook-orchestrator/SessionStart.tasks`
- `~/.claude/scripts/hook-orchestrator/Stop.tasks`

Each `.tasks` file is one command per line, with `#` comments / disabled rows.

## What does NOT change

- The 21 underlying scripts (turn-counter, dream-insights, retro-queue, etc.) — unchanged at their existing paths
- Their behavior — each still receives the same hook-input JSON via stdin
- Their per-task subprocess isolation (orchestrator forks each with `&`)
- Other events (PreToolUse, PostToolUse, UserPromptSubmit, etc.) — NOT orchestrated; PostToolUse specifically should stay fanned-out for latency reasons

## Verification

- [x] Orchestrator written + tested (11/11 SessionStart tasks ran in parallel)
- [ ] Settings.json migrated for SessionStart
- [ ] Settings.json migrated for Stop
- [ ] First post-migration session start: log shows `ok=11 fail=0`
- [ ] First post-migration session stop: log shows `ok=10 fail=0`
- [ ] No latency regression (tasks still parallel — verify via timing in log)

## Rollback

The orchestrator's `.tasks` file format makes the original-state recovery mechanical:

1. Read `SessionStart.tasks` / `Stop.tasks`
2. For each non-comment line, restore the corresponding block in settings.json
3. Remove the single orchestrator block

OR keep settings.json's git history and revert that specific commit.

Disable a single task without rollback: comment its line in the `.tasks` file (prefix with `#`).

## Phases

1. **Phase 1 — Build orchestrator** ✅
2. **Phase 2 — Write task config files** ✅
3. **Phase 3 — Smoke test** ✅ (11 tasks ran in parallel, all ok)
4. **Phase 4 — Settings.json migration for SessionStart** ⏳
5. **Phase 5 — Settings.json migration for Stop** ⏳
6. **Phase 6 — Monitor 1 week of normal sessions; check log for any regressions** ⏳

## Notes / followups

- `HOOK_ORCH_TASK_TIMEOUT` (default 30s) and `HOOK_ORCH_TOTAL_TIMEOUT` (default 60s) are env-tunable.
- Failed tasks are logged to `~/.claude/logs/hook-orchestrator.log` with `[orch]   FAIL <name> (rc=N)` lines — easier to spot than dispersed stderr.
- Per-task mute: prefix line with `# DISABLED ` in the `.tasks` file.
- If we ever orchestrate PreCompact (currently 3 registrations — borderline), the same orchestrator works; just add `PreCompact.tasks`.

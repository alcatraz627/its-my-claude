---
migration: 0017
title: Repoint todo-sync at the Task tool + add Stop-hook writeback & drift-block
session: todo-discipline@2026-06-01
status: complete
date: 2026-06-01
---

# Migration 0017 — Todo-sync onto the Task tool (live writeback + drift enforcement)

## Why

The `sync-todos` Phase-1 system (`prop-20260518-093153-58`, built 2026-05-19) was
**inert and mis-targeted**:

- Its `sync-wal.jsonl` was 0 bytes since build day — it had **never fired once**.
- It pulled *into* `TodoWrite`, which this environment no longer uses: across 50
  recent transcripts `TodoWrite` = 0 calls, the harness **Task tool**
  (`TaskCreate/TaskUpdate/TaskList`) = 1566. The TUI todo list is now the Task
  tool, persisted at `~/.claude/tasks/<session-id>/<id>.json`.
- The canonical "written notes" surface (`_active.md` from `/workspace`) had
  **zero adoption** — no `_active.md` existed anywhere — so the pull always
  no-op'd silently.

User ask ("keep todos fresh as priorities move; enforce a tri-surface sync,
don't just remind me"). Two problems: **liveness** (the agent letting the task
list go stale) and **tri-sync** (Task ↔ notes ↔ memory consistency, the deferred
Phase-2 writeback). Design adversarially reviewed before build
(`assets/reports/20260601-todo-discipline-review/skeptical.md`); the review
killed the original "additive text-matched writeback + advisory nudge" approach.

## What changes

| Addition / change | Path |
|---|---|
| New reconciler (machine-owned `## Todos` block, id-keyed, regenerated) | `~/.claude/scripts/sync-todos/reconcile.py` |
| New writeback orchestrator (Task→notes→memory, stdin SID, per-file lock, auto-init) | `~/.claude/scripts/sync-todos/writeback.sh` |
| New Stop hook (mechanical mirror + one-shot `decision:block` on drift) | `~/.claude/scripts/sync-todos/stop-sync.sh` |
| New UserPromptSubmit hinter (soft drift follow-up) | `~/.claude/hinters/46-sync-drift.sh` |
| New direct Stop hook wired (non-async, after `cleanup-comments-nudge`) | `settings.json` Stop[] |
| Repointed wording TodoWrite→Task; placeholder/`(#id)` strip on rehydrate | `hinters/45-sync-pending.sh`, `scripts/sync-todos/pull.sh` |
| `/core-dump` sources pending from `~/.claude/tasks/<sid>/`; leaves the machine block alone | `skills/core-dump/SKILL.md` §2.4, §3.7 |
| `/catchup` rehydrates unchecked notes-todos into the Task list on revival | `skills/catchup/SKILL.md` §0.8 |

## Key design decisions

- **Temporal authority model.** *Within* a session the live Task list is the
  source of truth (writeback mirrors Task→notes→memory). *Across* the session
  boundary (revival) the notes are truth (the new session's task dir is empty);
  `pull.sh` re-seeds the Task list from notes. This makes the
  `feedback_redundant-trio-sync` "workspace wins on conflict" precept precise:
  it's the cross-session rule, not the within-session one.
- **Machine-owned block, not additive append.** The region between
  `<!-- sync:auto:start -->` / `<!-- sync:auto:end -->` is regenerated each turn,
  keyed by stable Task `id` (never subject text). This delivers reorder / remove
  / reprioritise (the headline ask) and keeps the writeback off the human-authored
  area — so `/core-dump`'s confirmed writes and the hook's silent writes never
  race (disjoint regions). Rejects the magi doc's text-keyed approach.
- **SID from stdin only.** `~/.claude/.current-session-id` is a single global
  slot the most recent session clobbers (observed pointing at a different session
  than the live one) — every new-path script reads `session_id` from the hook
  event stdin instead.
- **Enforcement honesty.** The *sync* is mechanically enforced (writeback just
  happens). The *liveness* leg can only be agent-driven (hooks can't call
  TaskUpdate), so it's a one-shot `decision:block` above threshold (>2 tasks,
  ≥8 stale turns, ≥5 edits), with a `stop_hook_active` escape so a turn is never
  trapped. User chose this over advisory-only. Trivial sessions never block.
- **Revival empty-guard.** `reconcile.py` refuses to regenerate the block from an
  empty task list while the block still holds items — a freshly-revived session
  can't wipe real pending work before pull rehydrates it.

## What does NOT change

- `_lib.sh`, `wal.sh`, `sync-cli.sh` (`/sync status|reset|disable`) keep working.
- `pull.sh`'s SessionStart wiring (`hook-orchestrator/SessionStart.tasks:39`) is
  unchanged — only its extraction (strip `(#id)` + placeholder) and the hint
  wording were touched.
- `/workspace`, `create.sh`, `apply.sh`, `diff.sh` unchanged. `_active.md` stays
  a relative symlink (reconcile follows it via `realpath`, never replaces it).
- Existing Stop hooks (orchestrator, review-gate, auto-continue, cleanup-comments,
  claude-ipc) untouched; the new block composes via `stop_hook_active`.

## Verification

- [x] `reconcile.py` unit tests: create / regenerate / **reorder+remove+rename** /
      revival-guard / no-section / multiline-sanitise / bad-input (16/16 functional)
- [x] `writeback.sh` e2e: auto-init, memory pointer, decoy (`.lock`/`.highwatermark`)
      skip, WAL write (first ever), idempotency, **symlink preserved** (realpath fix)
- [x] `stop-sync.sh`: one-shot block fires on drift; `stop_hook_active` escape
      drops soft marker; ≤2-task gate; empty-stdin fail-safe
- [x] `46-sync-drift.sh`: surfaces+unlinks fresh marker; clears stale (>60min)
- [x] `pull.sh`: rehydrates with `(#id)` + placeholder stripped
- [x] Full lifecycle integration: auto-init → complete-task regen → revival
      empty-guard (4 items before = 4 after) → clean rehydration
- [x] `settings.json` valid JSON after edit (6 Stop hooks)

## Rollback

```bash
# Remove the Stop hook entry for sync-todos/stop-sync.sh from settings.json Stop[]
# (or: touch ~/.claude/sync-disabled  → all sync hooks skip silently)
touch ~/.claude/sync-disabled
```

Disable without rollback: `bash ~/.claude/scripts/sync-todos/sync-cli.sh disable`
(marker `~/.claude/sync-disabled`) or `touch ~/.claude/scripts/sync-todos/.hinter-off`
for just the hinters.

## Notes / followups

- The drift hinter globs the newest marker rather than keying on session id,
  because `hint-injector.sh:34` passes only the prompt text to hinters (not the
  event JSON / session id). Acceptable: the drift nudge is generic.
- Threshold constants (`SYNC_DRIFT_TURNS=8`, `SYNC_DRIFT_EDITS=5`,
  `SYNC_DRIFT_MIN_TASKS=2`) are env-overridable; tune after real-session telemetry.
- Multi-session-same-project writeback is last-writer-wins on the block (per-file
  lock prevents interleave, not divergence). Genuine concurrent edit of one
  project's `_active.md` from two sessions is out of scope (magi rejected CRDT).

## Addendum 2026-06-03 — source switched from task-dir to transcript

The original build read the live task list from `~/.claude/tasks/<sid>/*.json`.
**That dir is a volatile runtime cache** and is the wrong source: it lags within
a turn, **drops completed tasks** (so `[x]` could never be tracked), and is wiped
on resume. Observed directly: completing tasks #8/#9 removed their json files, so
the notes block froze showing them as `[ ]`.

Fix: `writeback.sh` and `stop-sync.sh` now reconstruct the task list by replaying
the **session transcript** (`replay_tasks.py`) — the durable, complete,
append-only record of every `TaskCreate` (id+subject from the result) and
`TaskUpdate` (status/subject/delete from the input). The Stop hook receives
`transcript_path` on stdin, so identity is unambiguous. The task-dir read remains
only as a fallback for manual invocations without a transcript path. Verified: the
block now renders all completed tasks as `[x]`, survives resume, and tracks
status changes that the dir lost.

New: `~/.claude/hinters/47-todo-heartbeat.sh` — a per-prompt nudge (reuses the
Stop hook's drift state) that fires when the list lags ≥2 turns, so focus-shifts
get reconciled continuously rather than only at the coarse Stop-block threshold or
at `/catchup` (which the user noted is too rare/late to be the sync mechanism).

Still agent-bound by design: a hook cannot call `TaskCreate`/`TaskUpdate`, so the
visible list can only be *pressured* fresh and *rehydrated-with-agent-help* on
resume — never populated by a hook. The notes file is the durable backbone.

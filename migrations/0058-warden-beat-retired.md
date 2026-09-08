---
migration: 0058
title: Warden standing beat retired per owner ruling D1a; on-demand judgment survives
session: caa097f8@2026-09-08
status: complete
date: 2026-09-08
---

# Migration 0058: Warden standing beat retired (owner ruling D1a, 2026-09-02)

## Why

The owner ruled the warden's fate on 2026-09-02 through the decision page
`assets/decision-pages/warden-keep-0901` (answer file: D1a, D2a, D3a, with the note
"Session recovery and lifecycle seem to be totally neglected, please identify all
the cases for that and suggest fixes as well"). The ruling was executed the same
day (`assets/reports/20260901-warden-keep-or-kill/plan.md:121-143`,
`features/warden.md` status block) but no migration recorded it, so a diagnosis
written five days later reported the page as unruled. This entry is the record.

## What changes

| From | To | Why |
|---|---|---|
| `~/Library/LaunchAgents/com.alcatraz.warden-beat.plist` fires every 45 min (migration 0051) | plist trashed, service bootout and disabled; no warden plist exists | D1a retired the standing judgment session. The beat's own log ends 2026-09-02T08:21:40Z "skip: paused by owner" |
| a standing sonnet warden session resumed by `warden/current-session` | on-demand only: `claude-warden open` | D3a: done-claim challenge is on-demand plus optional per-group watcher seats |
| `warden/ward-revive.sh` invoked by the beat | no invoker | the beat was its only caller (adversarial review 2026-09-02, `assets/reports/20260902-adversarial-review/indictment.md:26-31`) |
| `warden/ipc-wake.sh` runner (pm2 `ipc-wake`, 2026-08-26) | no runner: `pm2 describe ipc-wake` reports it does not exist; last ran 2026-08-27 | the half of D1a (event-driven revive) that was never built; pending owner decision |

## What does NOT change

- `~/.claude/warden/` stays on disk: `PROMPT.md`, `ledger.jsonl` (36 rows), `revive.jsonl` (5,955 rows), `spend.jsonl`, `insights.md`, `state/`, the scripts. Nothing is archived; on-demand judgment reads them.
- `warden/warden-beat.sh` and its test stay; they are not scheduled.
- The usage gate (migration 0053) and the calendar companion rule are unaffected.
- The `.paused` sentinel named in `features/warden.md` and the 09-01 session notes is NOT on disk (`ls -la ~/.claude/warden/` 2026-09-08). Nothing reads it now that the beat is unscheduled, so it is not recreated.

## Verification

- [x] `ls ~/Library/LaunchAgents/` lists no warden plist (2026-09-08)
- [x] `launchctl print-disabled gui/501` shows `com.alcatraz.warden-beat => disabled` (per `indictment.md:26-31`, 2026-09-02)
- [x] `tail -1 ~/.claude/warden/beat.log` is "skip: paused by owner ()" dated 2026-09-02T08:21:40Z
- [x] `pm2 describe ipc-wake` reports the process does not exist
- [x] `cat ~/.claude/assets/decision-pages/warden-keep-0901/.answer.json` holds "D1a D2a D3a"

## Indices updated

- [x] `MIGRATIONS.md` row added
- [ ] `FOLDERS.md`: not affected (no directory created, renamed or removed)
- [ ] `NAMESPACE.md`: not affected
- [x] `LOOKUP.md`: not affected; `features/warden.md` already carries the retired state and is the lookup row
- [ ] `rules/00-index.md` / `skills/00-index.md`: not affected

## Rollback

```bash
# Re-arm the beat (owner only): recreate the plist from migration 0051 and load it
launchctl enable gui/501/com.alcatraz.warden-beat
launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.alcatraz.warden-beat.plist
```

Rollback is a new owner ruling, not a repair: D1a was made on the efficacy record
(6 of 6 warden-tagged atone events are first-person warden failures).

## Notes / followups

- The one open half: wire a runner for `ipc-wake.sh` (an autonomous headless-turn daemon) or retire event-driven revive too. Put to the owner 2026-09-08 with the warden diagnosis (`assets/reports/20260907-alignment-surfaces-diagnosis/warden-diagnosis.md`). **Ruled 2026-09-08, decision page unblock-0908 D1a: retire event-driven revive too; the in-session hooks (goal-standing hinter, task nudge, goal-arm lint) carry ask 1.** Nothing is built; `ipc-wake.sh` stays on disk with no runner, like the rest of `warden/`.
- The owner's note on the ruling (session recovery and lifecycle neglected) was worked in the 09-01 to 09-03 gcc-audit session: reapers `60-reap-session-state.sh`, `61-reap-orphan-bg.sh`, the turnstate-active.sh freshness fix (`session-notes/78060eb5-041d-42ca-a4a6-0fbeaada71b8.md:50-62`).

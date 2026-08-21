---
migration: 0052
title: Cron duty ledger + CronCreate process-scope convention
session: docs-skill ac7f34c0@2026-08-21
status: complete
date: 2026-08-21
---

# Migration 0052: Cron duty ledger + CronCreate process-scope convention

## Why

A resume re-armed the warden 3h check-in from a checkpoint claim that the cron
"died with the /clear". It had not: CronCreate jobs are process-scoped, the
process survives a /clear, and cron c2271ddc was still firing. The result was
two identical check-ins at :23. Two gaps drove it: no doc stated the lifetime
model, and duties had no identity beyond a per-arming job id, so no session
could ask "is this duty already armed?". Owner directive 2026-08-21: make the
reconciliation structural in docs and tools. Related: prop filed the same
morning ("core-dump/catchup: stop assuming /clear kills CronCreate jobs").

## What changes

| From | To | Why |
|---|---|---|
| no cron duty registry | `~/.claude/scripts/cron/cron-duty.sh` + data dir `~/.claude/cron-duties/` | stable duty slugs; liveness verdict via recorded harness pid + start time |
| lifetime model undocumented | `rules/scheduling-discipline.md` §"Harness CronCreate jobs are PROCESS-scoped" | the read-before-scheduling rule now carries the model + ledger convention |
| core-dump Live commitments: goal/wake/deadline only | adds `crons:` field (full dump bullet + mini template), read via CronList | checkpoint states what was armed at dump time, with the lifetime caveat inline |
| catchup live-commitments table: no cron row | adds `crons:` row: CronList first, re-arm only what is absent, record what you arm | the resume-side half of the reconciliation |
| wake SKILL: "session-only, dies when Claude exits" | Phase 1b CronList-before-arm; Phase 2 records duty `wake-halt-check`; off clears it; Phase 3 says process-scoped | the one in-tree consumer now models its own lifetime correctly |

## What does NOT change

- `CronList` remains the in-session ground truth; the ledger is advisory and is
  what OTHER sessions and post-/clear resumes read.
- launchd / gcc-schedule / crontab jobs: not covered, they have their own
  registries and the calendar-companion rule.
- The wake payload (halt-check triage) is untouched.
- The calendar-companion waiver for /wake stands, with its stated reasoning.

## Verification

- [x] `bash ~/.claude/scripts/cron/cron-duty.sh` branches exercised 2026-08-21:
      record (real harness pid 11409), check LIVE exit 0, check DEAD exit 1
      (bogus pid), UNARMED exit 1, list, clear.
- [x] Pid-reuse guard mutation-tested: a live pid with a mismatched recorded
      lstart reads DEAD (exit 1).
- [x] Real duties recorded: warden-checkin-3h (23f936fc), wake-halt-check
      (1d76c14f); duplicate c2271ddc CronDeleted.
- [ ] First real resume exercises the catchup crons row (lands on next /clear).

## Rollback

trash ~/.claude/scripts/cron/cron-duty.sh ~/.claude/cron-duties/ and revert the
four doc sections (each names this migration or the c2271ddc incident, so
rg "cron-duty|c2271ddc" ~/.claude/rules ~/.claude/skills finds them all).

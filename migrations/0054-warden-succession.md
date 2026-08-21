---
migration: 0054
title: Warden succession hardening + weekly review row
session: docs-skill ac7f34c0@2026-08-21
status: complete
date: 2026-08-21
---

# Migration 0054: Warden succession hardening

## Why

Owner directive 2026-08-21 after the gap analysis: the warden externalized
memory continuously but its deaths were crashes, never dumps; an API error
could trigger a spurious succession; a hung invoke could stack beats; and
sub-challenge suspicion had no durable home. Recovery must never stall.

## What changes

| From | To | Why |
|---|---|---|
| resume-fail = instant fresh session | failure ladder: attempt 1 gets slack (exit 1, deltas preserved, retry next beat via .resume-fails counter); attempt 2 forces succession | transient API error and dead session look identical; slack for the first, guaranteed recovery by the second |
| succession = crash discovery | planned retirement: transcript >= WARDEN_RETIRE_BYTES (8MB) triggers a told FINAL beat + succession note, then current-session cleared | handoff, not crash |
| successor told "read three files" | computed $0 brief (open ledger rows, state-note freshness, beat-log tail) + mandatory read-back verify row | first paid invoke starts oriented; skipped reads visible in the ledger |
| uncapped invoke | timeout -k 30 1200s wrapper | a hung beat cannot stack with the next |
| suspicions die at succession | PROMPT.md permits watching: lines in state notes; carried and pruned | the one cross-succession memory leak |
| beat.sh hardcoded paths | WARDEN_DIR / WARDEN_GOALS_DIR / WARDEN_CLAUDE seams | testable against a fixture institution with a stubbed model |
| no warden weekly review | weekly-todos.md review items (this week + next) + WATCH item 13 | owner ask |

## What does NOT change

Conduct rules 1-10 · the beat flow before the invoke (hours/pause/gate/roster/
L0/governor/mid-turn) · the epilogue duties · ipc alias persistence.

## Verification

- [x] warden-beat.test.sh: 11/11 (ladder slack + forced succession + counter
      lifecycle, brief content, read-back demand, stamp-commit-on-success,
      retirement announce + pointer clear, timeout presence).
- [x] bash -n clean; in-situ run proceeded to a live production beat.
- [ ] First real retirement (~day 5-6) — WATCH item 13 carries it.

## Rollback

Revert warden-beat.sh invoke section + PROMPT.md §Succession + watching:
sentence; trash warden-beat.test.sh; drop WATCH item 13.

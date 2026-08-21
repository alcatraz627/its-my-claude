---
migration: 0053
title: Usage gate for autonomous institutions (warden + residue-review)
session: docs-skill ac7f34c0@2026-08-21
status: complete
date: 2026-08-21
---

# Migration 0053: Usage gate for autonomous institutions

## Why

Owner ruling 2026-08-21: the warden and speculative-atone/residue-review must
not consume tokens when the 5h or weekly usage window is above 90%; an
institution that eats task capacity is worse than none. Telemetry already
existed (statusline writes ~/.claude/widgets/.limits.json with both windows).

## What changes

| From | To | Why |
|---|---|---|
| no shared usage gate | `~/.claude/scripts/cron/usage-gate.sh` (PASS/GATED/UNKNOWN-passes, staleness-guarded) | one gate, allow-list shape checks per limits-check.sh lessons |
| warden-beat.sh invokes unconditionally (post-governor) | gate before invoke; skip logs + spend row `"gated":true` | spend.jsonl schema gains optional `gated` field |
| residue-review.sh runs unconditionally | gate at top; GATED log + exit 0 (unlike loud AUTH-FAIL) | a by-design skip is not a failure |
| WATCH.md items 1-11 | adds item 12: consecutive gated days = institution off, surface it | gate must not silently masquerade as clean weeks |

## What does NOT change

- /wake keeps its own limits-check.sh (5h-only) — extending it to weekly was
  not in the ruling.
- The governor (12 invoked beats/day) and $0 delta short-circuit stay; the gate
  sits after both, so gated rows still record roster size.

## Verification

- [x] Gate branches exercised 2026-08-21: PASS both-low, GATED 5h=91, GATED
      wk=95, PASS exactly-90, GATED nan+95, UNKNOWN-pass junk/missing/stale.
- [x] Live-fired gated warden beat (skip logged, gated spend row, no invoke)
      with delta cache snapshot/restored; live-fired gated residue run (exit 0
      before cursor).
- [ ] First real gate fire in production (weekly was 85% at ship time).

## Rollback

trash ~/.claude/scripts/cron/usage-gate.sh; remove the gate blocks in
~/.claude/warden/warden-beat.sh and ~/Code/Claude/i-dream/scripts/residue-review.sh
(both cite "usage gate" + this date); drop WATCH.md item 12.

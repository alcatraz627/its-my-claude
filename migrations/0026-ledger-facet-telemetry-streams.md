---
migration: 0026
title: Extend ::ledger facet with scheduler + hook-telemetry streams
session: fable-audit-7c@2026-07-07
status: complete
date: 2026-07-07
---

# Migration 0026 — Extend ::ledger facet with scheduler + hook-telemetry streams

## Why

The 2026-07-07 Fable audit of i-dream (batch 4, gcc::logging surface — report at
`~/Code/Claude/i-dream/.claude/output/20260708-fable-audit/data-logging-docs.md` §7)
found the "telemetry dashboard" promotion criterion for the deferred
`::observability` entry already satisfied by `scripts/ledger/` (hook-health.sh,
efficacy.sh). The audit initially recommended a new `gcc::logging` cluster; on
grounding against NAMESPACE.md this collided with two recorded decisions —
`::ledger` (migration 0025) already labels the system-of-record family, and the
`::logs` boundary (operational exhaust) is deliberately not promoted. User decision
2026-07-07: extend `::ledger`'s artifact list instead of creating a new cluster.

## What changes

| From | To | Why |
|---|---|---|
| `::ledger` artifacts = atone/affirm/pinned/proposals/personas + ledger/ + scripts/ledger/ | + `~/.claude/scheduled/history.jsonl` | scheduler run/removal/missed ledger — a system-of-record stream with the same JSONL shape and reader needs |
| (same) | + `~/.claude/hooks/warn-events.jsonl` + `scripts/hooks/warn-log.sh` | hook fire/heed telemetry; its reader (hook-health.sh) already lives in scripts/ledger/ |
| (same) | + `~/.claude/hooks-feedback-domain/` | structured hook-feedback events (i-dream-ingested) |
| NAMESPACE "Under consideration" `::observability` entry | notes partial resolution via this migration | keeps the record honest; ::logs non-promotion stands |

## What does NOT change

- No files move. The facet's artifacts stay where they are (facets are
  deliberately distributed).
- `::logs` (wal.jsonl, metacog firehoses, i-dream operational logs + daily
  digests) stays unpromoted per the 0025-era decision.
- No new top-level directory, no new cluster name. `gcc::logging` is NOT created;
  if the user uses the term, it resolves to `::ledger` + the unpromoted ::logs
  boundary.

## Verification

- [x] `rg -n "warn-events|history.jsonl|hooks-feedback" ~/.claude/NAMESPACE.md` shows the three streams under ::ledger
- [x] NAMESPACE.md "Under consideration" ::observability entry references migration 0026
- [x] MIGRATIONS.md index carries row 0026 ✅

## Rollback

```bash
# Revert the two NAMESPACE.md hunks and delete this file + index row
cd ~/.claude && git checkout -- NAMESPACE.md && trash migrations/0026-ledger-facet-telemetry-streams.md
```

Rollback condition: if the ::ledger facet definition becomes contested (e.g., a
future telemetry consolidation wants these streams under a different label).

## Notes / followups

- The heed side of warn-events is wired for 1 of ~16 hooks (audit batch 4 §4) —
  extending heed coverage is a follow-up candidate for the top-3 firing hooks,
  filed in the audit report, not part of this migration.
- i-dream's own logs/digests were considered and left in the ::logs boundary.

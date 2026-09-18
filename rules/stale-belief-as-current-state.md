---
brief: A stored field that recorded a past belief (task blocked_on USER:, a cron payload, a decision row) is verified live before it is rendered as current state; a gate set before the owner's latest ruling is re-derived, never repainted. Instrument, not memory: task-table flags gates older than the last decision-page answer.
triggers:
  - topic:blocked-on
  - topic:owner-gate
  - topic:stale-state
  - tool:task-table.sh
  - phrase:"needs you"
  - phrase:"waiting on you"
related:
  - rules/owner-gate-means-actionable-today.md
  - rules/structural-claim-without-reading-code.md
  - rules/repeatedly-emphasizing-ops-setup-that-user-already-addressed.md
tier: 2
paths:
  - ~/.claude/scripts/task-table/**
  - ~/.claude/scripts/cron/**
  - ~/.claude/scripts/decision-page/**
category: rules
updated: 2026-09-18
stale_after_days: 180
---

# A recorded belief is not a current state

A field that was correct when written and is stale now is worse than a wrong
field, because it renders with the authority of a record. The shape, five
recurrences in one week of September 2026 (gcp lanes, `mist-20260901-105817-85`):
a task's `blocked_on: USER:` line, a cron heartbeat payload, a decision row, each
carrying a ruling the owner had already given, rendered back to him as something
he still owed.

## The rule

Before rendering any field that encodes an owner-required state, ask when it was
written and what has happened since. If the owner has ruled on the topic after
the field was set (a decision page answered, a message on the thread), re-derive
the state from the ruling before showing it. Never repaint the field.

Scope: user-facing output only. Internal passes may carry the raw field.

## The instrument

`task-table.sh` reads `~/.claude/assets/decision-pages/answers.jsonl`, which
`decision-page.sh answer` appends to on every answer read, and flags every
`USER:` gate whose `blocked_on_at` predates the newest ruling:

```
!! N gate(s) set before your last ruling (<slug>), re-derive before treating as open: #ids
```

That line is the check. An agent that sees it re-reads the ruling and clears or
rewrites the gate before the table reaches the owner. Owner ruling D3c,
2026-09-18: both the check and this rule, because the check covers task rows
only and the shape also lives in cron payloads and decision rows.

## Diagnostic signal

You are about to print a row, a payload, or a bullet that says the owner must
act, and the newest thing you have read about that topic is the field itself.

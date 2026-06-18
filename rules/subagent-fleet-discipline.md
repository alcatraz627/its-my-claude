---
brief: When a parallel sub-agent fleet hits a transient API throttle, salvage finished work, re-dispatch only the dead, and throttle to batches on a second outage.
triggers:
  - topic:subagent-fleet
  - topic:api-error-recovery
  - phrase:re-dispatch
  - phrase:fleet died
  - tool:Agent
  - tool:Workflow
related:
  - rules/sub-agent-outputs.md
  - rules/api-error-recovery.md
  - features/claudew.md
tier: 2
category: rules
updated: 2026-06-18
stale_after_days: 365
---

# Sub-agent fleet discipline under API throttling

A parallel `Agent` fleet is **both the most common trigger of a server-overload
429 and its biggest victim**: the burst of concurrent requests trips the per-org
rate throttle, and the agents that die get NO automatic recovery — verified, a
died-on-error sub-agent leaves its error as the last transcript line and
`SubagentStop` fires for it only ~19% of the time, so there is no reliable hook
to catch it. Recovery is therefore **parent-driven**: only the dispatching agent
sees the failed/empty results and can act.

Provenance: 48h transcript analysis 2026-06-18
(`assets/reports/20260618-api-error-48h-analysis/findings.md`) — a single 89-agent
fleet lost 11 agents to one throttle burst; 3 of them had already written usable
output to disk and did NOT need re-running.

## The rule — three moves, in order

### 1. Triage before you re-dispatch (salvage finished work)

When part of a fleet comes back failed/empty, **do not blindly re-run the whole
batch.** Run the triage helper against the parent session's sub-agent dir:

```bash
python3 ~/.claude/scripts/fleet-triage.py --latest [project-substr]
# or: fleet-triage.py <parent-transcript.jsonl>
```

It classifies every agent as `DONE` / `SALVAGED` (died but its output file
exists on disk → reuse it) / `REDISPATCH` (died with no usable artifact).
Re-dispatch **only** the `REDISPATCH` set; consume `SALVAGED` outputs as-is. This
is why [[sub-agent-outputs]] matters: an agent that wrote its file before dying
is salvageable; one that kept everything in its return string is not.

### 2. Re-dispatch the dead with backoff

Re-run only the `REDISPATCH` agents, after a short cooldown (the throttle is
transient — give it 15-30s). Re-issue the same task prompt and the same output
path so a second triage pass converges.

### 3. On a SECOND outage, throttle to batches

If a re-dispatch also hits the throttle, stop firing the fleet at full width.
Drop to **small batches** (e.g. 3-4 agents) dispatched sequentially with a gap
between batches, or switch to the `Workflow` tool (it caps concurrency at
~min(16, cores-2) automatically). Full-width re-fire into an already-throttling
org just reproduces the outage.

## Prefer Workflow for large fans

Raw parallel `Agent` calls have no concurrency cap — N agents fire at once. For
fleets larger than a handful, prefer the `Workflow` tool (built-in cap + the
pipeline/parallel primitives) or stagger `Agent` dispatch into batches yourself.
The sessions that suffered most (sys-monitor, Versable) used raw wide `Agent`
fans.

## What this rule does NOT mean

- A handful of agents (2-4) firing together is fine — the throttle is an
  aggregate-rate phenomenon, not a per-call one. Don't batch-of-1 everything.
- Don't re-dispatch a `DONE` or `SALVAGED` agent "to be safe" — that re-spends
  tokens and re-adds concurrency pressure for output you already have.

## Diagnostic signal

A fleet returned and several results are null/empty/error, OR you're about to
re-run a whole `parallel(...)` batch after a 429. Stop — triage first, re-dispatch
only the dead, batch if it's the second hit.

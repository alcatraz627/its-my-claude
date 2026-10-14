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
paths:
  # autoload opt-out trial (2026-07-05): disclosed on demand, not always-on. Niche
  # (only when a parallel Agent/Workflow fleet hits a throttle); the agent Reads it
  # from rules/00-index.md when a fleet dies. Sentinel below never matches a real file.
  # Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-06-18
stale_after_days: 365
---

# Sub-agent fleet discipline under API throttling

A parallel `Agent` fleet is **both the most common trigger of a server-overload
429 and its biggest victim**. The burst of concurrent requests trips the per-org
rate throttle, and the agents that die get NO automatic recovery. A
died-on-error sub-agent leaves its error as the last transcript line, and
`SubagentStop` fires for it only about 19% of the time, so no reliable hook
catches it. Recovery is therefore **parent-driven**: only the dispatching agent
sees the failed or empty results and can act.

Provenance: a 48h transcript analysis on 2026-06-18
(`assets/reports/20260618-api-error-48h-analysis/findings.md`). A single 89-agent
fleet lost 11 agents to one throttle burst. Three of them had already written usable
output to disk and did NOT need re-running.

## The rule: three moves, in order

### 1. Triage before you re-dispatch (salvage finished work)

When part of a fleet comes back failed or empty, **do not blindly re-run the whole
batch.** Run the triage helper against the parent session's sub-agent dir:

```bash
python3 ~/.claude/scripts/fleet-triage.py --latest [project-substr]
# or: fleet-triage.py <parent-transcript.jsonl>
```

It classifies every agent as `DONE`, `SALVAGED` (died but its output file
exists on disk, so reuse it) or `REDISPATCH` (died with no usable artifact).
Re-dispatch **only** the `REDISPATCH` set and consume `SALVAGED` outputs as-is. This
is why [[sub-agent-outputs]] matters: an agent that wrote its file before dying
is salvageable, and one that kept everything in its return string is not.

### 2. Re-dispatch the dead with backoff

Re-run only the `REDISPATCH` agents, after a short cooldown of 15-30s (the throttle is
transient). Re-issue the same task prompt and the same output
path so a second triage pass converges.

### 3. On a SECOND outage, throttle to batches

If a re-dispatch also hits the throttle, stop firing the fleet at full width.
Drop to **small batches** (for example 3-4 agents) dispatched sequentially with a gap
between batches, or switch to the `Workflow` tool, which caps concurrency at
about min(16, cores-2) automatically. Full-width re-fire into an already-throttling
org just reproduces the outage.

## Prefer Workflow for large fans

Raw parallel `Agent` calls have no concurrency cap, so N agents fire at once. For
fleets larger than a handful, prefer the `Workflow` tool (built-in cap plus the
pipeline and parallel primitives) or stagger `Agent` dispatch into batches yourself.
The sessions that suffered most (sys-monitor, Versable) used raw wide `Agent`
fans.

## What this rule does NOT mean

- A handful of agents (2-4) firing together is fine, because the throttle responds to
  aggregate rate and not to a single call. Don't batch-of-1 everything.
- Don't re-dispatch a `DONE` or `SALVAGED` agent "to be safe". That re-spends
  tokens and re-adds concurrency pressure for output you already have.

## Diagnostic signal

A fleet returned and several results are null, empty or error, or you are about to
re-run a whole `parallel(...)` batch after a 429. Stop: triage first, re-dispatch
only the dead, and batch if it is the second hit.

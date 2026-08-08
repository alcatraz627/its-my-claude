<!-- i-dream project brief · 2026-08-07T03:55:03.913230+00:00 · 6 patterns / 0 insights -->
## What this project is about
A data pipeline and reporting project involving multi-agent runs, domain-specific filtering, and multi-criteria recommendation/search features — with heavy use of sub-agents and structured output delivery.

## Things to do (or keep doing)
- **Spot-check filter output against real data before delivery** — if obviously out-of-scope items appear, the filter logic was never exercised; always scan results row-by-row before handing off
- **Enforce ALL criteria conjunctively** — when implementing multi-criteria filters or recommendations, verify each stated criterion is active, not just a subset
- **Handle null/missing fields explicitly before numeric ops** — never allow null to silently coerce to a numeric default; guard upstream before display or aggregation logic
- **Reconcile task list before stopping** — during multi-agent sessions with many file edits, task state drifts; sync it to actual work done before ending the session

## Things to avoid
- **Don't accept a sub-agent's scope reduction as settled** — when a steward or sub-agent proposes narrowing scope, independently probe feasibility before presenting it to the user as a decision
- **Don't wholesale absorb a dead peer agent's plan** — when triaging another agent's work for incorporation, evaluate selectively: show which parts are worth merging and why, not a bulk handoff

## Open questions / known gaps
- Recurring tension between sub-agent autonomy and scope integrity — agents narrow scope or miss criteria without the main agent verifying before user presentation
- Task list discipline breaks down under high file-edit volume in multi-agent sessions; no automatic reconciliation signal exists

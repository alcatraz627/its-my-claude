<!-- i-dream project brief · 2026-07-23T00:59:36.877719+00:00 · 20 patterns / 9 insights -->
## What this project is about
Multi-agent Claude IPC infrastructure — sessions communicating via aliases, coordinating task ownership, and driving a shared UI dashboard. Work is typically orchestrated across parallel agents with high edit velocity.

## Things to do (or keep doing)
- **Verify from the consumer's side**: for IPC, confirm the peer received the message (round-trip reply), not just that the send succeeded; for UI, check the rendered state, not the emit log
- **Resolve peer aliases against live IDs before sending**: aliases go stale across session restarts — fall back to bare sessionId for reliability-critical messages
- **Update the Task tool after each logical unit**, not at milestones or session end — parallelism is exactly when staleness hurts most
- **State your stopping condition explicitly** when pausing — blocker, decision needed, or genuine handoff; never silently halt and wait for a go-ahead

## Things to avoid
- **Don't treat send-success as delivery proof** — a successful send can mask non-delivery when the peer alias is stale or the session was cleared
- **Don't patch one instance when a correction exposes a class** — after any "this should be shared/consistent" correction, grep the full codebase and fix all callsites in the same response
- **Don't route rubber-stamp go-aheads through the user** — batch sequential autonomous work and halt only at genuine decisions with self-contained context (blocker, ≥2 concrete options, prior constraint stated)
- **Don't place runtime feature flags in env config** — the project treats runtime-adjustable globals as a separate config system; flag the distinction before implementing

## Open questions / known gaps
- **Coordination metadata durability under session churn**: peer aliases and orchestrator liveness are not checkpointed with the same discipline as task artifacts, causing orphaned sub-agents and stale address books after clears
- **Proxy-evidence creep**: test-pass, CSS class presence, and send-log success are repeatedly accepted as verification — no enforcement gate exists yet to force consumer-side confirmation

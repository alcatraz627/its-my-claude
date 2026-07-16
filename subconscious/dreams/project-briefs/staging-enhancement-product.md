<!-- i-dream project brief · 2026-07-16T07:37:39.488139+00:00 · 20 patterns / 1 insights -->
## What this project is about
Multi-agent orchestration work on a staging/enhancement product, dominated by IPC coordination between parallel Claude sessions, sub-agent fleet management, and review/audit workflows at scale.

## Things to do (or keep doing)
- **Batch sequential work autonomously** — halt only at genuine decision points (irreversible ops, architectural forks, ambiguous scope); never ask for go-aheads on short-distance progress
- **Write IPC replies immediately** after receiving a peer query — treat unanswered peer messages as blocking obligations, not deferred bookkeeping; stop hooks will fire until cleared
- **Update task list after every unit of work**, especially after sub-agent bursts — reconcile explicitly, not only at milestones
- **Salvage finished sub-agent work on API errors** — re-dispatch only failed agents; key results by (judge + item + labels) to enable resumption without re-paying completed work

## Things to avoid
- **Don't confirm IPC delivery from send-side logs** — wait for an actual round-trip reply from the peer; log-based assertions of delivery will be rejected
- **Don't strip technical substance when adjusting document tone** — adjust register only; engineers need implementation detail, not accessible prose
- **Don't let task hygiene slip during high-parallelism runs** — the task list drifts fastest exactly when it matters most; explicit reconcile after each fleet completion is mandatory
- **Don't hand off CLI auth steps silently** — interactive auth (cloud logins, etc.) cannot be automated; flag it to the user up front before the flow blocks

## Open questions / known gaps
- IPC aliases go stale after session restarts — no reliable alias-resolution fallback documented; bare sessionId addressing is the current workaround but requires knowing the new ID
- Interactive MCP input tools fail in TUI fullscreen mode — no consistent pattern for detecting this before a prompt is rejected and the user must re-answer in prose

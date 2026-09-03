<!-- i-dream project brief · 2026-08-28T01:25:29.086045+00:00 · 10 patterns / 0 insights -->
## What this project is about
A scratchpad/wake session in `/private/tmp`, focused on agent tooling, wake/beat cycles, and cross-session coordination infrastructure. Work is primarily agentic — sub-agents, IPC, task stores, UI dashboards.

## Things to do (or keep doing)
- Always cite file paths as absolute (`/` or `~`) in every user-facing reply; never bare basename or repo-relative.
- Verify sub-agent output files exist on disk before treating idle/done signals as completion; the signal alone is not the artifact.
- Run ignore-transparent searches (`rg --no-ignore` / `fd --no-ignore`) before claiming a file or module is absent.
- When the declared-ready gate fires on a docs-only turn, surface the false positive plainly and move on — don't retry the same turn or suppress it silently.

## Things to avoid
- Don't ship a file path immediately before a sentence period (the period gets absorbed into the terminal auto-link).
- Don't claim done/works/fixed without executing the changed code path; the gate fires correctly — fix the work, not the gate.
- Don't act on stale sub-agent idle notifications for agents already stopped earlier in the session; treat them as no-ops.
- Don't implement a UI element verbatim from a plan without checking whether the layout serves the plan's legibility goal at actual desktop width.

## Open questions / known gaps
- Task-store commands during wake checks must verify the store header matches the expected session ID; wrong-session reads have silently produced incorrect queues.
- UI table/wide-content changes lack a reliable one-command browser-open verification step; parity ledgers for table layout are not yet exercised.

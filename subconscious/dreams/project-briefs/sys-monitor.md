<!-- i-dream project brief · 2026-07-15T18:52:20.024003+00:00 · 20 patterns / 3 insights -->
## What this project is about

A system monitoring dashboard/service (sys-monitor) with multi-agent IPC coordination, live runtime exercise requirements, and a high bar for explicit state management over plausible defaults.

## Things to do (or keep doing)

- **Dispatch an adversarial reviewer sub-agent immediately after implementing any complex feature** — it reliably catches HIGH-severity bugs test suites miss.
- **Run the affected code path live before claiming done** — test coverage alone is not verification; runtime dogfooding is the bar.
- **Re-verify task list state after any burst of sub-agent work** — reconcile completed vs open before stopping or switching areas.
- **Push back with evidence on design decisions** — user explicitly values independent judgment over capitulation; debate with file:line citations.

## Things to avoid

- **Don't use zero-defaults (`bb.get('x', 0)`) for missing data** — fabricates plausible-looking values that corrupt downstream deltas; prefer explicit errors or None.
- **Don't assert IPC delivery from the sender's own logs** — confirm via actual round-trip reply from the peer; log-based delivery claims are rejected.
- **Don't let task list drift across multi-turn or high-parallelism periods** — update TaskCreate/TaskUpdate immediately after each unit of work, not batched at end.
- **Don't treat "I trust you" as authorization to remove safeguards** — social reassurance is not a removal mandate; gates stay unless explicitly revoked.

## Open questions / known gaps

- IPC reply discipline under stop-hook pressure is a recurring friction point — unanswered peer queries trigger repeated hook fires; establish a reply-before-stop habit.
- Task list hygiene degrades specifically during parallel sub-agent bursts; no mechanical enforcement yet prevents drift until reconciliation is explicitly triggered.

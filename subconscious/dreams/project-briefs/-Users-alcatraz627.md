<!-- i-dream project brief · 2026-07-16T07:35:18.603578+00:00 · 20 patterns / 2 insights -->
## What this project is about
A personal Claude Code harness and tooling environment (`~/.claude`) — infrastructure, scripts, hooks, and agents for the user's own dev workflow. Work is iterative, multi-agent, and frequently involves IPC between sessions.

## Things to do (or keep doing)
- **Ground before touching code**: explore the codebase and surface a recommendation first; jumping to edits without that grounding misses context
- **Dispatch an adversarial reviewer sub-agent** immediately after implementing any complex feature — it reliably catches HIGH-severity bugs the main agent misses
- **Prefer breadth-first v1 sweeps** across all surfaces before polishing individual items; pause a sweep to perfect one area only if the user explicitly redirects
- **Treat social reassurance as comfort, not authorization** — "I trust you" / "that's fine" does not remove safeguards or confirmations

## Things to avoid
- **Don't defer task updates** — update the Task tool after each completed unit, not at milestones; a drifted list caught by the stop hook at turn 20 is a failure, not a recovery
- **Don't patch specific instances of structural defaults** (one CLI added to a fallback list, one zero-default silenced) — fix the class of problem or the structural default regenerates
- **Don't verify delivery by inspecting send-side logs** — IPC and async delivery require an actual round-trip reply from the peer to count as confirmed
- **Don't batch sequential short-distance progress into confirmation prompts** — halt only at genuine decision points or destructive/irreversible actions

## Open questions / known gaps
- **Task list hygiene under parallel agents**: concurrent sub-agent bursts consistently cause task-list drift; no durable reconciliation ritual exists yet
- **IPC shell quoting**: backticks and special chars in message bodies produce zero-byte or corrupted IPC sends — a standing footgun with no automated guard

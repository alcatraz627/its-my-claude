<!-- i-dream project brief · 2026-07-16T07:36:22.651968+00:00 · 11 patterns / 1 insights -->
## What this project is about
Multi-agent IPC orchestration on macOS — coordinating Claude instances via a message-passing broker, with fleet dispatch, session aliasing, and context recovery as dominant working patterns.

## Things to do (or keep doing)
- **Verify IPC delivery by round-trip reply**, not send-side logs; a successful send is not a confirmed receive
- **Batch sequential work into autonomous runs**; halt only at genuine decision points or irreversible ops, not routine progress checks
- **Treat task updates, IPC replies, and commits as blocking obligations** — execute immediately after each unit of work, never defer as bookkeeping
- **Salvage finished sub-agent work on API errors**; re-dispatch only failed agents, keyed by (judge + item + labels) for resumable runs

## Things to avoid
- **Don't use shell `timeout`/`gtimeout` wrappers on macOS** — they orphan child processes and don't cap execution; use the pgid-kill pattern instead
- **Don't address IPC peers by registered alias in long-running sessions** — aliases go stale after session restarts; fall back to bare sessionId
- **Don't propose diverging names for sibling artifacts** in the same org; default to the established naming scheme before suggesting alternatives
- **Don't dispatch fewer high-cost agents for broad review coverage** — a fleet of lower-cost agents covering more items is preferred

## Open questions / known gaps
- No established pattern for detecting alias staleness proactively — sessions discover it at send time, not before
- CLI auth steps (cloud provider logins) block automation; no consistent handoff protocol documented for the human auth gap

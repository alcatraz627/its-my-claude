<!-- i-dream project brief · 2026-07-16T07:35:00.820490+00:00 · 11 patterns / 1 insights -->
## What this project is about
Multi-agent IPC coordination tooling on macOS, with heavy emphasis on fleet orchestration, cross-session messaging, and resumable batch jobs. Working style is autonomous, high-parallelism, coverage-over-depth.

## Things to do (or keep doing)
- **Verify delivery via round-trip reply**, not send-side logs — a successful send is not a successful delivery in IPC contexts.
- **Batch sequential progress autonomously**; halt only at genuine decision points or blocking external inputs, never for lightweight go-aheads.
- **Salvage and re-dispatch** on fleet API failures — finish what's done, re-run only what failed, never restart the whole fleet.
- **Key batch results by (judge + item + discriminating labels)** to enable mid-run resume without re-paying completed work.

## Things to avoid
- **Don't use shell `timeout` on macOS** — it orphans child processes silently; use the Perl process-group kill pattern from `rules/shell.md`.
- **Don't address IPC peers by alias after a session restart** — aliases go stale; fall back to bare sessionId for reliability.
- **Don't defer task updates, IPC replies, or commits as bookkeeping** — treat them as blocking obligations that execute immediately after completing each unit of work.
- **Don't suggest diverging names across sibling artifacts** in the same org — default to the established naming scheme.

## Open questions / known gaps
- IPC alias staleness after session restarts has no automatic detection; stale-alias failures surface late and are hard to distinguish from delivery failures.
- CLI auth steps (cloud logins, etc.) require interactive terminals — no automated path exists; hand-off discipline to the user must happen up front, not when the command blocks.

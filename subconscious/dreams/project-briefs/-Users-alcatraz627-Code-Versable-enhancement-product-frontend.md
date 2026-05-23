<!-- i-dream project brief · 2026-05-21T02:49:11.723261+00:00 · 20 patterns / 10 insights -->
## What this project is about

Frontend codebase for a multi-session product (Versable enhancement-product), worked in long autonomous sessions with heavy context compaction and session-continuity tooling. Dominant style: terse directives, scoped deep execution, continuous resumption via `/catchup` and `/core-dump`.

## Things to do (or keep doing)

- **Checkpoint proactively** — `/core-dump` at milestones and ~every 20 tools, not only at session end; user resumes via `/catchup` across compaction boundaries
- **Confirm task scope explicitly at session start** — execute autonomously within that boundary, touch nothing outside it
- **Treat terse directives as job-resumption signals** — reconstruct intent from WAL/checkpoint state, emit a one-line ack, then continue
- **Prefer reading existing patterns before writing new code** — scan for prior implementations before proposing helpers or modules

## Things to avoid

- **Never commit or push without fresh, explicit per-operation approval** — prior session approval, even from moments ago, does not carry forward; this is the highest-severity recurring violation in this project
- **Don't expand scope beyond the explicit request** — no "while I'm here" cleanups, no unrequested refactors, no speculative abstractions
- **Don't create helpers or module-level exports without a live callsite** — if you can't name the file:line calling it right now, don't create it

## Open questions / known gaps

- Pattern extraction produces heavy semantic duplicates (same WAL migration event recorded 4× independently) — the continuity tooling itself may need deduplication logic
- Tension between fully autonomous long sessions and the strict no-push-without-approval rule creates friction at natural commit points; no clear handoff protocol exists for when to pause mid-session and ask

<!-- i-dream project brief · 2026-07-08T16:43:30.741177+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM infrastructure suite (`q`/`see`/`review`/`imagine`/`lm fleet`/`lm index`) — research, tooling, and documentation for on-device model orchestration. Work alternates between exploratory sub-tasks and concrete deliverables; the user values decisive, focused execution over thorough peripheral coverage.

## Things to do (or keep doing)
- Always surface the **actual raw output** when claiming a test or feature succeeded — "it works" without evidence is treated as a failure, not a courtesy
- Translate research and design phases into **lean, behavior-focused implementation docs** — professional and direct, neither enterprise-heavyweight nor hacky
- Execute explicitly invoked skills (`/atone`, `/core-dump`, etc.) **immediately and completely** — deferring them mid-correction compounds the original mistake
- Use the **Task tool** (not a file) whenever updating todos; the TUI is the user's status surface

## Things to avoid
- Don't re-introduce deleted complexity or add unrequested features when the user asks for a simpler replacement
- Don't open docs with "why this matters" or motivational framing — use formal, direct, factually grounded language; no em-dashes, no AI-smell phrasing
- Don't use `rm` — `trash` only; this is hard-blocked and has no exceptions
- Don't complete peripheral exploratory work first and deliver the main task last — bias toward the primary deliverable

## Open questions / known gaps
- Recurring pattern: mandatory skills (`/atone`) skipped or silently deferred mid-session even after explicit invocation — treat the invocation as a hard interrupt, not a queued item
- Session focus discipline is fragile on multi-sub-task sessions; risk of peripheral completion crowding out the main deliverable

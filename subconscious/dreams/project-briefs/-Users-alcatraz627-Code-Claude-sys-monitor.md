<!-- i-dream project brief · 2026-05-30T17:04:19.723429+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitoring tool (likely Python backend + Node/TUI frontend) with pipeline architecture, circuit breakers, and worker processes. Work style is iterative with strong TUI/gum presentation conventions and precise commit communication.

## Things to do (or keep doing)
- **Always use gum/TUI tools** for tabular output in chat — raw markdown tables are a persistent compliance failure here (6+ recurrences)
- **State commit scope completely** — if the answer is "all of `backend/`", say that directly; partial file lists that force follow-up questions are rejected
- **Define constants inline** when introducing them in reports or docs — name + purpose + default + valid range, never name-drop without explanation
- **Scope circuit breakers per pipeline module**, not per shared external dependency — flag blast-radius when scoping to a shared resource

## Things to avoid
- **Don't use inline imports** — top-of-file only; this is a strong persistent frustration, not a style preference
- **Don't patch the definition namespace in Python tests** — patch where the consumer module looks up the name, not where the symbol is originally defined
- **Don't name a config constant in a doc without defining it** — "WORKER_MAX_DEFER_COUNT" with no explanation is worse than omitting it

## Open questions / known gaps
- Recurring gum/TUI compliance gap suggests the tool integration may not be consistently available or the detection heuristic is unreliable — verify gum is on PATH at session start before committing to TUI output

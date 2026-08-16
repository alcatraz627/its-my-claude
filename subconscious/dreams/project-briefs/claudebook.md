<!-- i-dream project brief · 2026-08-12T17:51:26.177904+00:00 · 6 patterns / 0 insights -->
## What this project is about
A data aggregation and scraping pipeline project with a filtering/dashboard UI layer. Work style is iterative planning-before-implementing, with emphasis on spec review before building.

## Things to do (or keep doing)
- Always spec underspecified features and hand the spec to the user for review before writing a line of implementation code
- For fan-out scraping: route raw collection to sonnet-high or gemini, reserve opus/main for analysis and judgment stages
- Run a skeptical-review or adversarial sub-agent on any aggregation pipeline plan before committing to implementation — it reliably catches real bugs
- Include a per-source filter for every actively-scraped data source in filtering UIs; partial coverage is immediately noticed and rejected

## Things to avoid
- Don't answer scoping or status questions with multi-section briefings; the user wants the direct answer in the first two lines, full stop
- Don't regenerate AI-smell prose (em-dashes, excessive bold, Label:fragment rows) after a stop-hook flags it — the hook fires because the tells are there; rewrite plainly before resending
- Don't invent acceptance criteria for underspecified features and silently implement them; surface the ambiguity first

## Open questions / known gaps
- Tension between "just answer directly" and "spec before implementing" — resolve by: answer status questions directly, spec *feature* questions before building
- AI-smell prose recurs even after correction within the same session; treat any hook fire as a hard rewrite signal, not a soft nudge

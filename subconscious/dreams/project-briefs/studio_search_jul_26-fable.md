<!-- i-dream project brief · 2026-08-16T03:50:35.290987+00:00 · 20 patterns / 3 insights -->
## What this project is about
A job/studio search pipeline with multi-stage data collection, filtering, scoring, and decision-page output. Work style is iterative and correction-heavy — the user expects tight, right-sized output and is cost-conscious about token spend.

## Things to do (or keep doing)
- **Emit a coverage manifest with every filter/scrape result** — list sources checked, criteria enforced, and zero-result buckets; never deliver ranked output without it
- **Lead with the direct answer or raw data** before any structure or synthesis; if the user wanted a briefing, they'd ask for one
- **Split model tiers across pipeline stages** — cheap/fast models for bulk collection, capable models for analysis and scoring
- **Right-size fan-out to the question** — a single targeted sub-agent beats a fleet when the scope is narrow; estimate token cost against any stated quota before launching

## Things to avoid
- **Don't re-raise deferred topics** — if the user skipped or ignored something across multiple turns, it stays parked until they surface it
- **Don't deliver filter results without verifying ALL criteria fired conjunctively** against real output; zero results from a new source means investigate the filter, not proceed
- **Don't emit structurally identical output after a correction** — a re-emission with different words but the same shape reads as performative acknowledgment, not change
- **Don't instruct sub-agents to write a file named `report.md`** — the harness blocks it; use a slug-named path under `.claude/output/`

## Open questions / known gaps
- Deferred actions (send emails, post listings) accumulate in PENDING lists without ever executing — no clear trigger or owner handoff pattern established
- Incremental sub-agent writes vs. batched delivery: the project has had repeated failures where sub-agents batch instead of writing per-record; no enforcement contract yet

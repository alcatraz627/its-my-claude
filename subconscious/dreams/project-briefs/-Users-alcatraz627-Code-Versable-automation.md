<!-- i-dream project brief · 2026-08-21T23:41:24.095222+00:00 · 20 patterns / 4 insights -->
## What this project is about
Versable automation — a multi-source data scraping and aggregation product with GitHub-integrated review workflows. Work is incremental, PR-driven, and scope-disciplined.

## Things to do (or keep doing)
- **Lead with the payload**: answer first, then context — never open with framing, structure, or a briefing preamble
- **Enumerate what you checked**: when any sweep returns zero or few results, list what was actually examined; absence of results is not evidence of absence
- **Convert blocks into handoff artifacts**: when hitting a scope boundary (auth, harness guard, product decision), write the exact action needed, who can take it, and what resumes after
- **Route multi-decision batches through `/decision-wizard`**: never post a numbered question list in chat

## Things to avoid
- **Don't regenerate AI-smell after a hook fires**: rewriting with the same em-dashes, bold-spam, or Label:fragment rows is a cosmetic pass — actually remove the tell before resending; re-check every 3–5 turns
- **Don't mark tasks done without verified completion**: a task is done when the code path ran and you read the result, not when the edit landed
- **Don't post to GitHub without an agent attribution marker**: all PR comments, reviews, or shared-platform posts via the user's account must self-identify as agent-generated — `(via 🤖claude)` on line 2+
- **Don't make structural claims without reading the source**: "this is not present" requires a citation or a grep result, not pattern-matching

## Open questions / known gaps
- Prose-smell corrections degrade within the same session — no durable enforcement between turns; check adherence explicitly after any prose correction
- Per-source filters for scraped data sources are expected but frequently missing from initial implementations; audit UI filter coverage against active scrapers before calling a filter surface done

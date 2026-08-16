<!-- i-dream project brief · 2026-08-12T17:53:54.678036+00:00 · 20 patterns / 2 insights -->
## What this project is about
A multi-source job-scraping and filtering pipeline with a data-driven UI — dominant work is fan-out collection, filter logic, and heterogeneous-source aggregation. Sessions tend to be long and multi-turn with many sequential edits.

## Things to do (or keep doing)
- Route raw scraping/collection to sonnet-high or gemini; reserve opus for analysis, judgment, and filter-logic verification.
- Run an adversarial review on any generated filter plan before executing — catches over-aggressive exclusion logic that silently exiles valid results.
- Implement per-source filters in the filtering UI for every actively-scraped source; a missing source filter is immediately noticed.
- Update task statuses every 2–3 subtasks during long autonomous sessions; the task list drifts badly across 50+ edits if not reconciled.

## Things to avoid
- Don't verify multi-criteria filters by spot-checking one representative row — enumerate the full output set and confirm ALL criteria are enforced conjunctively.
- Don't embed interactive auth flows (OAuth redirects, `gcloud auth login`) in deployment scripts; flag the blocker and stop gracefully rather than hanging.
- Don't claim "I read through the output" without actually acting on what was found; surface specific findings or drop the claim.
- Don't answer a direct scoping or status question with a structured multi-section briefing — answer the question first, then add context if needed.

## Open questions / known gaps
- Deferred user-named actions ("send these emails", "post this") accumulate in PENDING lists without executing — no clear handoff or escalation path when the agent can't complete them autonomously.
- External dependency failures (quota limits, resource locks, peer-agent death) have no systematic timeout-and-surface pattern; silent stalls recur.

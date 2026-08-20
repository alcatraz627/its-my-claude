<!-- i-dream project brief · 2026-08-18T17:49:23.091584+00:00 · 20 patterns / 3 insights -->
## What this project is about
Multi-source job-scraping and aggregation pipeline (Walmart-domain) with a filtering UI over heterogeneous data sources. Dominant working style: autonomous fan-out sessions with sub-agents, deployment scripts, and incremental UI builds.

## Things to do (or keep doing)
- Route raw scraping to sonnet-high or gemini; reserve higher-tier models for analysis and judgment seats
- Surface a concrete spec or acceptance criteria before implementing any underspecified feature — never invent scope
- Handle null/missing fields explicitly before any numeric operation or display logic; a suspicious default is a bug signal
- Reconcile the Task-tool list before stopping in high-activity sessions — 50+ edits with a frozen task list is an error state

## Things to avoid
- Don't regenerate AI-smell prose (em-dashes, excessive bold spans) after a stop-hook flags it — fix in the same reply, don't re-emit
- Don't omit a per-source filter for any actively-scraped source in a multi-source filtering UI; the user notices immediately
- Don't embed interactive auth flows (OAuth redirects, `gcloud auth login`) in autonomous deployment scripts — notify the user and stop gracefully instead
- Don't treat a correction as local — when fixing any pattern (prose, UI, filter logic), grep for sibling instances of the same class before declaring done

## Open questions / known gaps
- Autonomous pipeline stages keep stalling silently on synchronous human dependencies (credential prompts, subscription limits); no timeout/fallback wiring exists yet
- Pattern corrections reliably fail to propagate to sibling instances in the same session — the "treat co-occurring instances as independent" failure is unresolved

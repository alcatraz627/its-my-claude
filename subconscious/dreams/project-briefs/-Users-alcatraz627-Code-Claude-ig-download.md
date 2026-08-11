<!-- i-dream project brief · 2026-08-11T00:23:45.783776+00:00 · 20 patterns / 2 insights -->
## What this project is about
A multi-source social media scraping and download pipeline (Instagram-focused) with a filtering UI, fan-out collection agents, and GCP Cloud Build deployment. Working style is autonomous long-running sessions with sub-agent orchestration.

## Things to do (or keep doing)
- Route raw collection fan-out to sonnet-high or gemini; reserve opus/main for analysis and synthesis — model tier matters at scale here
- Surface per-source diagnostics on zero-result runs (which pages/endpoints were checked, not just the count)
- Write deploy strategy and pipeline config in project-visible locations, not `.claude/` internal dirs
- Pre-deploy: run an explicit constraint check against sub-agent output before merging — self-reported correctness is unreliable

## Things to avoid
- Don't build interactive-auth steps into autonomous deploy pipelines — browser-redirect OAuth blocks silently; pre-establish credentials before the session starts
- Don't let task status drift during long autonomous runs; update after each logical unit, not in batch at the end
- Don't omit per-source filter controls when the UI aggregates from multiple scraped sources — an actively-scraped source without its own filter is immediately noticed
- On GCP Cloud Build with a custom service account, always specify a logs bucket or `CLOUD_LOGGING_ONLY` — omitting it fails the build non-obviously

## Open questions / known gaps
- Model usage/rate-limit handling during autonomous sessions is unresolved: hitting a limit currently causes silent stall rather than graceful fallback with user notification
- UI edge states (empty scrape results, out-of-scope filter conditions) have not been exercised against real data — treat them as unverified gaps, not assumed correct

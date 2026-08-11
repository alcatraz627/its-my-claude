<!-- i-dream project brief · 2026-08-11T00:24:07.271808+00:00 · 7 patterns / 1 insights -->
## What this project is about
A multi-platform scraping and download pipeline (Instagram-focused) with a data aggregation UI. Work style is fan-out pipelines, browser MCP automation, and filter/display surfaces over heterogeneous sources.

## Things to do (or keep doing)
- Route raw collection steps to sonnet-high or gemini; reserve higher-tier models for analysis and synthesis passes
- Surface per-source diagnostics on zero-result scrapes — which pages/endpoints were checked, not just the count
- Always exercise pipeline output against the full actual dataset before delivery; shape-level spot-checks miss cross-source filter bugs
- Before large fan-out scraping operations, estimate whether the operation fits within the visible usage quota

## Things to avoid
- Don't dispatch a sub-agent with exclusive browser MCP access without first verifying no other session holds it — resource conflicts cause silent failures
- Don't build a source-filter UI that omits any actively-scraped platform; every live source needs a per-source filter control
- Don't emit prose with em-dashes or excessive bold spans — the stop-hook will flag it and force a re-emission cycle; write plain sentences from the start
- Don't declare a pipeline "verified" after shape-level checks alone; null coercions and out-of-scope items passing filters are real failure modes at scale

## Open questions / known gaps
- No established adversarial-review gate before large fan-out plans — recurring tension between shipping speed and catching the core flawed assumption early
- Pipeline verification discipline degrades as complexity grows; no standing one-command affordance to exercise the full dataset end-to-end

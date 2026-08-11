<!-- i-dream project brief · 2026-08-11T00:23:21.939257+00:00 · 17 patterns / 2 insights -->
## What this project is about

Multi-platform data scraping and automation pipeline for Versable, with GCP Cloud Build deploys and autonomous multi-agent orchestration. Work style is long-running autonomous sessions with fan-out sub-agents and frequent pipeline verification cycles.

## Things to do (or keep doing)

- Route raw scrape/collection steps to sonnet-high or gemini; reserve higher tiers for analysis and synthesis — explicit model plan per fan-out
- Before any large fan-out or scraping operation, estimate quota consumption against visible usage limits and surface the estimate before proceeding
- Run adversarial review sub-agents explicitly tasked with finding the core flawed assumption — not just functional review but constraint-compliance check against style rules before shipping
- Tag container images with commit SHA alongside `:latest` so every deploy is traceable back to a commit

## Things to avoid

- Don't embed browser-redirect OAuth or `gcloud auth login` in deploy scripts — autonomous sessions will stall silently; design for fully non-interactive credential flows
- When a pipeline produces zero results for any source, don't just report the count — surface which exact pages/endpoints were checked; shape-level spot-checks on heterogeneous pipelines miss real failures
- Don't omit a per-source filter in any data UI built over multiple scraped platforms — it is an immediate UX gap users notice
- Don't write deployment docs only into agent-scoped output dirs; place them in project-visible locations the team can find independently

## Open questions / known gaps

- Autonomous sessions have no graceful handling for external blocking events (auth prompts, quota exhaustion, orchestrator death) — failure mode is always silent stall; no established escalation path yet
- Pipeline verification degrades to shape-inspection as complexity grows; no enforced "exercise against full real dataset" gate before delivery

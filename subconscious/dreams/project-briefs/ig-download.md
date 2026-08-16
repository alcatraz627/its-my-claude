<!-- i-dream project brief · 2026-08-13T00:23:40.104349+00:00 · 15 patterns / 0 insights -->
## What this project is about
Instagram content downloader and multi-source scraping pipeline; work centers on data collection, filtering UIs, and sub-agent fan-out orchestration over heterogeneous platforms.

## Things to do (or keep doing)
- **Surface zero-result diagnostics proactively**: when any pipeline stage returns 0 items, report which endpoints/pages were checked before moving on — a zero count alone is not actionable
- **Estimate quota cost before fan-out**: if the user has mentioned a usage limit, compute whether the proposed scraping operation fits before launching; offer an explicit go/no-go
- **Tier models by stage**: route bulk collection/raw scraping to sonnet-high or gemini; reserve higher-tier models for analysis, synthesis, and judgment seats
- **Include per-source filters** in any filtering UI built over multi-platform aggregated data — omitting a source the pipeline actively scrapes is immediately noticed

## Things to avoid
- **Don't regenerate AI-smell prose after a hook flags it**: em-dashes, excessive bold spans, structured self-critical replies — rewrite plain on the first correction, not the third
- **Don't one-shot a fan-out without a browser MCP exclusivity check**: verify no other session holds the resource before dispatching a sub-agent with exclusive browser use
- **Don't answer indirect or verbose when the user asks a direct question**: state the point first; indirection reads as a communication failure here
- **Don't launch a large scraping job and report findings count only**: show the filtering logic path and what was skipped

## Open questions / known gaps
- Recurring tension between thoroughness (fan-out, adversarial review) and quota cost — user wants the value of broad review but reacts negatively when the token spend feels disproportionate to the question size

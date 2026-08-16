<!-- i-dream project brief · 2026-08-13T00:23:58.683075+00:00 · 8 patterns / 0 insights -->
## What this project is about
UI knowledge planning for the Versable builder product — a research/analysis pipeline that scrapes, filters, and synthesizes UI patterns, run in multi-stage fan-out workflows.

## Things to do (or keep doing)
- Split model tiers by stage: cheap/fast models for bulk collection and scraping, capable models for synthesis and analysis.
- Right-size fan-out to the question — a focused lookup beats a 10-agent sweep when the signal is narrow.
- Run skeptical/adversarial sub-agents on outputs; they catch real bugs and the user will ask for more when they deliver.
- Estimate token cost relative to the user's stated quota before launching expensive workflows; offer a go/no-go.

## Things to avoid
- Don't re-emit AI-smell prose after a hook correction — no em-dashes, excessive bold, or label:fragment rows; the rewrite must actually differ.
- Don't answer with structured self-criticism (numbered RCAs, formatted pattern lists) under pushback; run the check first, send the result.
- When a pipeline stage returns zero results, don't proceed — investigate the filter logic first; zero output signals misconfiguration, not absence.
- Don't mistake output volume (finding count, sub-agent count, process steps) for thoroughness; the user reads it as wasted cost.

## Open questions / known gaps
- Persistent tension between fan-out breadth and token budget — no standing heuristic for when quota pressure should shrink the fleet vs. block the run entirely.

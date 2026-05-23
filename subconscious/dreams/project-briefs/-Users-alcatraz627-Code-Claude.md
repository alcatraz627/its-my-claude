<!-- i-dream project brief · 2026-05-01T11:12:42.264333+00:00 · 15 patterns / 10 insights -->
## What this project is about
Large-scale geopolitical/game-theory simulation with globe visualization, multi-agent architecture, and complex UI. Sessions are long, tool-heavy (50–157 calls), and frequently continued across context boundaries.

## Things to do (or keep doing)
- Proactively run `/core-dump` before sessions end and after 40+ tool calls; user depends on WAL/checkpoint state for continuity
- On terse continuation commands (`keep going`, `move`, `started`), consult WAL/checkpoint first, then resume exact task scope at full speed — no clarifying questions
- Keep responses ≤15 words between tool calls in high-tool-count sessions to preserve context budget
- Commit to version control regularly as part of the normal workflow

## Things to avoid
- Don't expand scope on terse commands — `keep going` means "same task, more execution", never "and also improve nearby things"
- Don't emit long summaries or preamble; user communicates in minimal tokens and expects the same back
- Don't ask clarifying questions after a single-word directive; reconstruct intent from the last 3–5 WAL actions instead

## Open questions / known gaps
- Terrain/globe visualization has known blurriness/resolution issues that are actively being worked on but unresolved
- Scenario-switching dropdown bug in the simulation UI is a recurring open defect — check its status before touching that area

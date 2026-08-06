<!-- i-dream project brief · 2026-08-06T03:34:05.946337+00:00 · 2 patterns / 0 insights -->
## What this project is about
Search feature development ("studio_search_jul_26") using a structured two-agent peer-review workflow where independent plans are produced and cross-graded before any implementation begins.

## Things to do (or keep doing)
- In multi-agent review flows, execute each agent's plan independently and preserve both outputs — never collapse them into a merged recommendation
- When asked to compare two plans or outputs, produce a side-by-side contrast table; treat merging as a distinct operation requiring explicit user instruction
- Surface the plan before implementing; this project runs plan → peer-review → implement, not one-shot

## Things to avoid
- Don't merge or synthesize peer-review blueprints without explicit instruction — the dual-output is the artifact, not an intermediate step
- Don't confuse a comparison request with a synthesis request; "compare" means contrast, "merge" means merge
- Don't skip the cross-grading phase by treating one agent's plan as authoritative before the other has reviewed it

## Open questions / known gaps
- No signal yet on what the search feature covers (domain model, data sources, indexing strategy) — read project files before making structural claims
- _(no signal yet on test conventions or deployment surface for this project)_

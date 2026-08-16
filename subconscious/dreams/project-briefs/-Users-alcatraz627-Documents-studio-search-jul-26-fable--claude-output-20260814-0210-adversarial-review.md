<!-- i-dream project brief · 2026-08-14T00:35:29.799941+00:00 · 7 patterns / 0 insights -->
## What this project is about
Adversarial code review workflow in a studio/search context, with multi-stage automated pipelines and kanban tracking. Work is sequential and stage-gated, with the user as a manual checkpoint between phases.

## Things to do (or keep doing)
- Always run `git diff -w` before interpreting diff size — auto-formatting hooks rewrite on write, making whitespace noise look like substantive change
- Separate automated and manual phases visibly in any plan before executing; mixed sequences cause re-scoping interruptions
- Update the kanban board after each completed stage without waiting for the user to request it

## Things to avoid
- Don't claim success without exercising the code path — the declared-ready hook fires repeatedly because the pattern keeps recurring; run it, don't inspect it
- Don't answer adjacent deployment paths when the user asks about a specific one; answer the exact operational question asked
- Don't run simplification or refactor tooling that produces no meaningful output — a no-op tool run costs user attention and is treated as a defect, not neutral
- Don't proceed on ambiguous task references like "do #2" without confirming which item is meant

## Open questions / known gaps
- Declared-ready violations are recurrent within single sessions despite hook firing — something in the workflow keeps bypassing the exercise step; root cause unresolved
- Board sync cadence is unclear: user expects proactive updates but the trigger condition (per stage? per commit? on request?) is not established

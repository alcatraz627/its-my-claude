<!-- i-dream project brief · 2026-08-24T19:39:46.286388+00:00 · 20 patterns / 7 insights -->
## What this project is about
A multi-source job/content aggregation and search tool with a filtering UI, built using a two-agent mutual peer-review workflow where agents independently produce plans and grade each other's blueprints.

## Things to do (or keep doing)
- Prefer the two-agent peer-review pattern: produce independently, then contrast side-by-side — never merge without explicit instruction
- Always enumerate all axes of a multi-dimensional feature (filter criteria, data sources, visual modes) before declaring it complete
- Always include the derivation chain alongside any outcome report — which sources checked, which files read, what prior context applied
- Verify outcomes at the consumer's end (running app, actual output rows, receiving agent) not the producer's end

## Things to avoid
- Don't regenerate AI-smell prose (em-dashes, excessive bold spans) after the stop-hook flags it — the hook fires because the fix didn't land; treat the second flag as a generator problem, not an instance problem
- Don't re-raise a topic the user has deferred or skipped three or more times without explicit invitation
- Don't name a sub-agent output file `report.md` — the harness blocks this write; use a dated slug path
- Don't claim a filter, coverage, or verification is complete after checking only one criterion or source — conjunctive enforcement against real output is required

## Open questions / known gaps
- The declared-ready hook fires repeatedly within sessions, signaling a persistent habit of claiming success without exercising the code path — treat any "done" claim as requiring a run signal first
- Scope underspecification recurs: before implementing features whose acceptance criteria would have to be invented, surface a spec for the user to approve

<!-- i-dream project brief · 2026-07-27T20:05:47.548201+00:00 · 19 patterns / 3 insights -->
## What this project is about
A React/Node app (fiber-snatchers) with multi-surface UI and job creation flows. Primary working mode is iterative feature implementation against user-authored design mocks and product specs.

## Things to do (or keep doing)
- **Consult design mocks before writing any UI label, page name, or creation flow** — labels derived from code patterns always mismatch; mocks are the canonical source.
- **Survey the full affected surface (all sibling pages, sidebar, row expansion) before implementing** — breadth-first first, then depth.
- **Route completed non-critical items to the deferred review backlog automatically** — don't interrupt flow to seek immediate review unless user asks.
- **When user signals time pressure and explicit autonomy, proceed on reversible work without confirmation pauses.**

## Things to avoid
- **Don't declare a UI bug fixed without exercising the fix on the running dev server** — false assurance from inspection alone is a trust-damaging pattern here.
- **Don't produce gap tables or completion estimates without reading actual source files** — memory-based assessments consistently overestimate what's built.
- **Don't use agent-authored downstream definition docs as the authority** — when user-authored spec and agent formalization conflict, the user-authored source wins.
- **Don't halt for sequential progress confirmation on low-stakes next steps** — interrupt only when you need user-held information to make a real product decision.

## Open questions / known gaps
- Product-level behavioral decisions embedded in implementation (e.g. can users add files to an existing job?) must be surfaced as explicit questions rather than silently resolved from code patterns — recurring gap.

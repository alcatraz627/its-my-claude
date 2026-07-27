<!-- i-dream project brief · 2026-07-27T00:45:50.440869+00:00 · 14 patterns / 1 insights -->
## What this project is about
A React/Next.js fiber-snatcher dev tool with a multi-surface UI; dominant work is feature shipping under time pressure with design mocks as the authoritative source of truth.

## Things to do (or keep doing)
- Read design mocks before implementing any UI label, module name, or creation flow — internal naming conventions are not a substitute
- Read actual source files before producing gap tables or completion assessments; code beats inference
- When a bugfix pattern is confirmed working, extract it into a shared standard across all affected surfaces
- Proceed autonomously on reversible work when the user explicitly signals deadline pressure and grants autonomy

## Things to avoid
- Don't claim a UI bug is fixed without exercising the fix on the running dev server — false assurance cycles damage trust fast
- Don't resolve product-level behavioral decisions (e.g. "can users add files to existing jobs?") implicitly in code; surface them as explicit questions first
- Don't use agent-authored definition docs (concepts, formal specs) as the authoritative source when the user-authored upstream doc exists and conflicts
- Stop proceeding past a direct user question mid-stream; answer it before continuing other work

## Open questions / known gaps
- Recurring tension between "deferred review backlog" workflow and the agent's instinct to gate on immediate review — clarify the default trigger condition once and encode it
- Multi-surface UI features (page view, row expansion, sidebar) are consistently shipped incomplete; no pre-implementation surface enumeration step exists yet

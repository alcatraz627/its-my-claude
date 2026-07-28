<!-- i-dream project brief · 2026-07-28T01:05:35.064657+00:00 · 20 patterns / 5 insights -->
## What this project is about
A dream-tracking dashboard (i-dream) with a React/Next.js frontend and agent-driven backend; work is UI-heavy with recurring multi-page consistency requirements and sub-agent orchestration.

## Things to do (or keep doing)
- **Audit all sibling pages** before implementing any shared UI component (drawer, sidebar, pagination) — one-page fixes recur across the whole app.
- **Read design mocks before writing any UI label, flow, or module name** — internal naming conventions are wrong; the mocks are canonical.
- **Ground gap assessments in user-authored source docs**, not Claude-generated derivatives; read the actual files before producing a gap table.
- **When a sub-agent hits an auth/credential block**, surface the exact command the user must run and hold — never attempt workarounds.

## Things to avoid
- **Don't claim a UI or runtime bug is fixed without exercising it on the running dev server** — false-assurance cycles damage trust faster than honest gaps.
- **Don't generalize a scope directive** — when the user says "only for X, not Y," enforce it literally; no self-gating flexibility.
- **Don't re-enable or expand a disabled config** (CI trigger, feature flag) without first investigating why it was disabled.
- **Don't use pipe-delimited wire-format dumps or essay-length comments** — when the user flags an output format as bad, the correction applies to the entire class.

## Open questions / known gaps
- Recurring tension between breadth-first BUILD (cover all surfaces) and deferred-review (don't over-polish) — agents conflate the two phases and either over-polish during build or under-verify during review.
- Design mocks are not reliably discoverable at session start; agents repeatedly derive labels from code instead of checking mocks, suggesting mock locations need a canonical pointer in the project root.

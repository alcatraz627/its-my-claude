<!-- i-dream project brief · 2026-08-18T17:47:57.931412+00:00 · 20 patterns / 5 insights -->
## What this project is about
A dream-tracking dashboard (i-dream) with widgets, pm2 services, and Anthropic API integration. Dominant work style: multi-agent peer-review workflows, UI-heavy feature development, and frequent context-retention discipline.

## Things to do (or keep doing)
- **Audit all sibling pages/components before touching any UI shell** (drawer, sidebar, modal) — implementing per-page instead of globally is the single most common rework trigger here.
- **Consult design mocks before writing any label, page name, or creation flow** — internal naming conventions and code patterns are not substitutes; mocks are the contract.
- **Classify multi-agent output handling mode explicitly** before acting: keep-separate (peer-review/comparison), validate (cross-check against constraints), or triage (dead-agent recovery).
- **Preserve load-bearing constraints verbatim in every checkpoint** — applying line caps to summaries silently drops invariants; constraints survive truncation, everything else doesn't.

## Things to avoid
- **Don't claim a UI fix is done without visually exercising the rendered page on the running dev server** — compile passes and send-side logs are not destination-state proof.
- **Don't treat a prose-smell correction as resolved after one rewrite** — AI-smell (em-dashes, bold-spam, Label:fragment rows) resurfaces in multi-turn sessions; re-scan before every human-facing reply.
- **Don't proceed on a terse continuation when the next action involves a product-level behavioral choice** (user-visible label, feature scope, data model semantics) — pause one line, then execute.
- **Don't make structural claims about where functionality lives without reading the relevant source file first** — verified at file:line, not inferred from naming.

## Open questions / known gaps
- Tension between "proceed on terse continuation" and "surface product-level decisions explicitly" is unresolved — the boundary between an execution decision and a product choice needs per-case judgment, not a blanket rule.
- Prose-smell hook fires repeatedly on the same violations session after session; a durable fix (stricter self-scan before send, not just hook-triggered rewrite) has not landed.

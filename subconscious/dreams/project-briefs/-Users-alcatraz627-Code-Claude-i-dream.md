<!-- i-dream project brief · 2026-08-15T16:00:59.134008+00:00 · 20 patterns / 5 insights -->
## What this project is about
Active dream-tracking dashboard (i-dream) with widgets, pm2 services, Anthropic API integration, and light/dark mode. Work style is structured peer-review with two-agent mutual grading; design mocks exist and are authoritative.

## Things to do (or keep doing)
- **Audit sibling pages/components before writing any shared UI** — drawers, sidebars, pagination, and naming schemes already exist elsewhere; find the pattern first, then implement consistently across all instances in one response
- **Verify at the consumer boundary** — a rendered page in the running dev server, not a code edit or a "sent" signal, is the proof that a UI fix worked
- **Consult design mocks before implementing any label, flow, or module name** — derived naming from code conventions causes full reworks
- **Present independently-produced artifacts side-by-side** — never merge two peer plans or reviews; separation carries signal the user needs

## Things to avoid
- **Don't claim UI work done without visually inspecting the running app** — repeated false assurance cycles are the dominant trust-damage pattern here
- **Don't pause on terse continuations** ("proceed", "keep going", "yes") when context is under 70% and work is clearly pending — continue immediately
- **Don't skip mandatory skill gate phases** (adversarial validation, etc.) and mark tasks complete — silently skipping confirmed gates is a tracked mistake
- **Don't regress to default-LLM prose register** (em-dashes, Label:fragment rows, bold-spam) across turns — the prose-smell hook fires repeatedly here; watch for it actively

## Open questions / known gaps
- Prose-smell violations recur even after hook correction — the agent is not retaining the voice constraint turn-over-turn; no durable fix yet
- Deferred decision items frequently lack the prior constraint + concrete options, forcing follow-up questions; format discipline here is unresolved

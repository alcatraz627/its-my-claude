<!-- i-dream project brief · 2026-08-30T11:36:45.668241+00:00 · 11 patterns / 0 insights -->
## What this project is about
Slack automation infrastructure for a Versable developer, with recurring work involving CSS/Next.js frontend debugging, multi-agent research fan-outs, and architectural audits of agent routing lanes.

## Things to do (or keep doing)
- Complete all obvious sequential steps autonomously; don't checkpoint between steps the user hasn't flagged as decision points.
- After verifying a sub-agent's output on disk, immediately `TaskStop` that seat — idle agents get commandeered by board auto-dispatchers.
- Use a dedicated adversarial verifier seat in multi-stage research fan-outs; it reliably catches findings the primary seats miss.

## Things to avoid
- Don't silently pick a branch after an either/or question the user answered with a bare affirmative — re-confirm which branch they meant before executing.
- Don't treat a CSS custom property declared as empty (`--x: ;`) as a fallback provider; `var(--x, fallback)` substitutes the empty value, not the fallback — omit the declaration entirely.
- Don't register CSS custom properties with `inherits: false` if they need to reach `::before`, `::after`, or child elements — those are invisible to non-inheriting registered properties.
- Don't assume `node_modules/.cache` is cleared by a dev-server restart or `.next/cache` clear; explicitly delete it for a truly clean state.

## Open questions / known gaps
- Routing lane documentation diverges from actual usage data; stale lane rules remain uncorrected and mislead future agents dispatching work.

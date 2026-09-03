<!-- i-dream project brief · 2026-08-30T11:37:38.528250+00:00 · 11 patterns / 0 insights -->
## What this project is about
Local-models infrastructure and deep-research tooling for a Claude Code power user; work involves multi-agent fan-outs, model-tier routing, and CSS/UI debugging sessions.

## Things to do (or keep doing)
- After verifying a sub-agent's output on disk, immediately `TaskStop` that seat — idle agents get commandeered by board auto-dispatchers
- Use a dedicated adversarial verifier seat to cross-check research fan-out findings against ground truth before synthesizing the final report
- Complete all obvious sequential steps autonomously; do not checkpoint-confirm between them unless a decision only the owner can make is genuinely blocking

## Things to avoid
- Don't silently pick a branch when the user answers a bare "yes" to an either/or question — re-state which branch you're taking before proceeding
- Don't declare a clean dev state after restarting the server or clearing `.next/cache` alone — `node_modules/.cache` survives both and must be explicitly deleted
- Don't declare a CSS custom property as `--x: ;` and expect `var(--x, fallback)` to use the fallback — the empty value is substituted instead; omit the declaration entirely
- Don't register a CSS property with `inherits: false` if it needs to reach `::before`, `::after`, or child elements

## Open questions / known gaps
- Routing rule documentation and actual lane usage diverge; stale rules describe lanes differently than real-world invocations show — no resolution recorded

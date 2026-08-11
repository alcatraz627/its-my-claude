<!-- i-dream project brief · 2026-08-11T00:24:33.991819+00:00 · 20 patterns / 3 insights -->
## What this project is about
A multi-platform job/studio search tool with data scraping pipelines, multi-criteria filtering UI, and structured two-agent peer-review workflows. Dominant mode: pipeline correctness and autonomous session reliability.

## Things to do (or keep doing)
- **Execute the two-agent peer-review protocol** when requested: each agent produces an independent plan, then grades the other's blueprint — never skip the independent-production step.
- **Always produce side-by-side contrast** when asked to compare plans or outputs — merging is a separate operation requiring explicit user request.
- **Exercise filters against the full real dataset** before delivery and surface per-source diagnostics (which pages/endpoints were checked, counts per source) — shape-level verification is not enough.
- **Surface blocking events immediately** (auth prompts, usage limits, orchestrator failures) with the exact action needed; never stall silently.

## Things to avoid
- **Don't emit AI-smell prose** (em-dashes, heavy bold spans) — the stop-hook fires repeatedly here; clean it before sending, not after being caught.
- **Don't add unprompted background automation** (pm2 warm-up jobs, cron, ollama pre-loads) — user has explicitly rejected these; they must not reappear as implicit suggestions.
- **Never claim a filter or output is verified** without naming the specific observable result you read — "I checked and it looked fine" is not verification; cite the row, count, or artifact.
- **Don't accept a sub-agent's scope reduction as settled** without independently probing feasibility first.

## Open questions / known gaps
- **Filter conjunctiveness**: multi-criteria exclusions repeatedly ship enforcing only partial criteria; needs a checklist gate before delivery on any filter change.
- **Null coercion in pipeline**: missing fields silently default to suspicious values; no systematic null-guard pattern yet established for this codebase.

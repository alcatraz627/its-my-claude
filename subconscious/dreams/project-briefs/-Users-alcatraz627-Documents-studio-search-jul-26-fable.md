<!-- i-dream project brief · 2026-08-16T03:48:50.405326+00:00 · 20 patterns / 6 insights -->
## What this project is about
A multi-source job-search aggregation tool with scraping pipelines, filtering UI, and a two-agent mutual peer-review workflow where agents independently produce plans and grade each other's blueprints.

## Things to do (or keep doing)
- **Emit a coverage manifest** alongside every filter/scrape result — list every source checked, every criterion evaluated, every zero-result bucket; the user notices omitted sources immediately
- **Produce a side-by-side contrast** when asked to compare two plans or outputs — merging is a separate operation requiring explicit instruction
- **Classify any block as credential-gated (halt, surface exact command) vs work-gated (proceed autonomously if reversible)** — never stall silently on either
- **Exercise the changed path before claiming done** — the declared-ready hook has fired multiple times per session; run it, read the result line, then report

## Things to avoid
- **Don't regenerate AI-smell prose after a hook correction** — em-dashes, excessive bold, label:fragment rows; if the re-emission is structurally identical to what the hook flagged, the correction didn't land
- **Don't raise a deferred or skipped topic again without explicit user invitation** — three or more skip signals is a hard scope boundary
- **Don't accept a sub-agent's scope reduction as settled without independently probing feasibility** — present the narrowed scope to the user only after verifying it holds
- **Don't name a sub-agent output file `report.md`** — the harness blocks that write; use a slug or timestamped name

## Open questions / known gaps
- Autonomous execution stretches stall silently on usage limits or auth blocks — no wall-clock heartbeat discipline established yet
- Prose-style regressions persist across multi-turn sessions even after hook enforcement; a structural re-emission check (not just rewording) is not yet habitual

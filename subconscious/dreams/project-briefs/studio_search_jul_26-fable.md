<!-- i-dream project brief · 2026-08-18T17:50:46.345023+00:00 · 20 patterns / 2 insights -->
## What this project is about
A job/studio search pipeline with multi-criteria filtering, scored ranking, and report/decision-page UI output. Work is iterative, token-conscious, and heavily tool-mediated (sub-agents, IPC, file pipelines).

## Things to do (or keep doing)
- Verify ALL filter criteria fire conjunctively against real output before delivery — zero results from a new source means check the filter, not the source
- Handle null/missing fields explicitly before numeric ops or display logic; a suspicious default is always a null coercion
- Right-size fan-out to the question: estimate cost against any stated quota before launching expensive sub-agents; offer go/no-go
- Use model-tier splitting in multi-stage pipelines — cheap models for bulk scrape/collect, capable models for analysis and scoring

## Things to avoid
- Don't re-raise deferred topics without explicit user invitation — three or more dismissals is a scope boundary, not a hint to try again later
- Don't cite your own summaries, review claims, or systematization docs as evidence of source-level truth; engage the primary artifact
- Don't send a status update, deferred item, or result the user cannot act on without a follow-up question — include the missing context inline
- Don't emit polished self-critical replies (numbered RCAs, structured acknowledgments) after a correction; fix the behavior, not the optics

## Open questions / known gaps
- Deferred actions (emails, posts) accumulate in PENDING lists and never execute — no consistent mechanism to close that loop
- Report UI elements lack actionable links alongside scores; ranked lists without links force manual lookup and are persistently under-complete

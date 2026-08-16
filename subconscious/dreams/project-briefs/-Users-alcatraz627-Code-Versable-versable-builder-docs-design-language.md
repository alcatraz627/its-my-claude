<!-- i-dream project brief · 2026-08-13T00:27:22.191717+00:00 · 8 patterns / 0 insights -->
## What this project is about
Design language documentation for a versable-builder product; work centers on spec authoring, review sub-agents, and pipeline-based content generation.

## Things to do (or keep doing)
- Prefer plain declarative sentences: state the point first, stop — no preamble, no hedge.
- Right-size output to the question; one precise finding beats five uncertain ones.
- Split model tiers in pipelines: cheap models for bulk/scrape steps, capable models for analysis and synthesis only.
- When a pipeline stage returns zero results from a new source, treat it as a filter misconfiguration — investigate before proceeding.

## Things to avoid
- Don't regenerate prose with the same AI-smell tells (em-dashes, bold-spam, Label:fragment rows) after a stop-hook flags them — the hook catches the rewrite too.
- Don't respond to pushback with a numbered RCA or structured acknowledgment block; that reads as covering tracks, not correcting behavior.
- Don't launch a token-expensive fan-out when the user has mentioned a usage limit without offering an explicit cost estimate and go/no-go first.
- Stop treating high agent count or enumerated process steps as a signal of thoroughness — the user reads it as wasted cost.

## Open questions / known gaps
- Adversarial/skeptical review sub-agents have demonstrated concrete bug-catch value here; no standing pattern yet for when to invoke them proactively vs. on request.

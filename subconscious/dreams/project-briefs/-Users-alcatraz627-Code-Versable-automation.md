<!-- i-dream project brief · 2026-08-19T22:32:42.256100+00:00 · 20 patterns / 4 insights -->
## What this project is about
Automation tooling for Versable, likely involving multi-agent workflows, GitHub integration, and data-source aggregation pipelines. Work style is review-heavy with shared multi-agent directories and external platform surfaces.

## Things to do (or keep doing)
- **Read the source file before making any structural claim** ("this feature is missing", "this path does not work") — grep first, cite file:line, then assert
- **Verify at the receiver boundary**: after any prose rewrite, sub-agent output, or hook-driven correction, confirm the actual output is clean — not your intent to clean it
- **Attribute all agent-generated content posted to GitHub**: PR comments and any shared-platform posts through the user's account must include an explicit attribution marker (e.g., `(via 🤖claude)`)
- **Read before Write in all shared directories** — peer agents modify files between your turns; a Write without a prior Read in this repo is always a data-hazard

## Things to avoid
- **Don't regenerate prose-smell tells after a hook correction** — em-dashes, bold-spam, Label:fragment rows appearing in the rewrite of a flagged reply is the dominant failure pattern here; treat hook fire as a hard constraint, not a style nudge
- **Don't mark tasks done without verification** — false-complete reports are treated as reporting errors; only mark `completed` after the output artifact or behavior is confirmed
- **Don't raise deferred topics again** — if the user has skipped or ignored something three or more times, it is out of scope until they re-open it
- **Never name a sub-agent output file `report.md`** — the harness blocks this write; use a slug-specific name

## Open questions / known gaps
- Prose-smell corrections do not persist across turns — the rewrite prior reasserts default-LLM register in every multi-turn session; a per-session mechanical check (not just hook-fire) is needed but not yet wired
- Assessment and review outputs are consistently missing observation-boundary annotations (which files were read, which endpoints checked) — gap tables without this caveat are presented as complete when they are not

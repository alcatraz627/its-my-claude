<!-- i-dream project brief · 2026-08-15T01:39:30.791406+00:00 · 18 patterns / 2 insights -->
## What this project is about
Slack data-scraping and aggregation pipeline with multi-stage fan-out sub-agents, per-source filtering UI, and iterative deployment cycles. Work style is orchestration-heavy with frequent plan→implement→review sequencing.

## Things to do (or keep doing)
- Route raw collection/scraping to sonnet-high or gemini; reserve higher-tier models for analysis and synthesis stages
- Run a skeptical-review or adversarial gate sub-agent on any scraping/aggregation plan before implementing — it reliably surfaces real bugs
- Check `git diff -w` before interpreting diff size; auto-formatting hooks rewrite on write and inflate apparent change size
- When corrected on any behavior (prose style, code pattern, UI gap), treat the correction as class-scoped — find and fix all other instances of the same pattern immediately

## Things to avoid
- Don't regenerate AI-smell prose (em-dashes, excessive bold) immediately after a stop-hook block; the hook fires again and again until the root pattern is eliminated
- Don't claim a feature is done without exercising the code path; the declared-ready hook fires multiple times per session on this project
- Don't answer a scoping or operational question with a multi-section structured briefing — give the direct answer first, context second
- Don't treat checkpoint directives or documentation as authoritative across sessions; verify current code state before acting on any "completed" claim from a prior session note

## Open questions / known gaps
- Kanban board is never proactively updated during multi-stage work; treat board sync as a required step at each stage boundary, not an optional cleanup
- Ambiguous task references ("do #2") repeatedly cause direction corrections — confirm which item is meant before proceeding

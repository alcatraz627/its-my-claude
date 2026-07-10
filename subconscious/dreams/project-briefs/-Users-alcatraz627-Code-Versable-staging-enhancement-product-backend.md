<!-- i-dream project brief · 2026-07-10T08:29:39.379918+00:00 · 2 patterns / 0 insights -->
Now I have enough context. Writing the brief.

## What this project is about
An AI-powered product-copy enhancement pipeline (Versable staging backend) that generates grounded marketing descriptions for e-commerce parts using LLM agents (V2/V3), web research, and an Opus judge scoring factual_accuracy / brand_fidelity / marketing_quality / template_compliance. Work is benchmark-driven: prompt variants are evaluated against scored runs across model families (gpt-5.x, gemini, Opus).

## Things to do (or keep doing)
- **Fail loud on silent judge failures** — always check that judge dimension columns are non-zero before trusting composite scores; a plausible composite (~0.50) can mask a dead judge whose exceptions were swallowed silently.
- **Test only in the research-ON config** — research is always on in production; runs that disable it measure a state customers never see and produce irrelevant deltas.
- **Prefer fleet dispatch for cross-corpus research** — partition by category (rules/transcripts/config), run agents in parallel, consolidate after all agents return; this pattern has worked repeatedly for large analysis tasks.
- **Correct and retract conclusions when new data arrives** — don't massage a null result; name the prior wrong claim and replace it with the new reading.

## Things to avoid
- **Don't write file paths immediately before a sentence period** — Ghostty auto-links paths and swallows trailing periods; the stop hook fires on every instance. Always follow a path with a space, comma, or word before any punctuation.
- **Don't declare a benchmark "validated" off the composite alone** — read the per-dimension columns before reporting; rule + research scores can carry a composite while every judge dimension is dead zero.
- **Don't propose testing axes the user has already ruled out** — when a config flag is always-on in production, don't model a disabled-flag variant as useful; it wastes a run and misreads user intent.

## Open questions / known gaps
- **The new prompt hasn't beaten V2-existing** — across 12 variants on 30 Whiteline parts, deltas are within noise; the right prompt-level lever hasn't been found yet.
- **Judge truncation was a recurring blind spot** — two separate confound-chasing rounds before the real cause (judge couldn't see full research) was isolated; future judge bugs will likely follow a similar silent-failure pattern.

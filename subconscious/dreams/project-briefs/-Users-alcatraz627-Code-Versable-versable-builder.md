<!-- i-dream project brief · 2026-07-10T08:39:36.744032+00:00 · 11 patterns / 0 insights -->
## What this project is about
A customer-facing B2B product (Versable Builder) with iterative doc-writing and multi-agent review workflows. Working style mixes autonomous implementation bursts with explicit human feedback gates before terminal actions.

## Things to do (or keep doing)
- Always restructure sentences so file paths are never the final token before a period — place a word, comma, or space after every path reference to avoid Ghostty auto-link truncation
- Before implementing any mechanism to store/retrieve an ID or config value, scan `git log --oneline -10` for recent commits that may have already introduced it
- Check git history before suggesting any version change (upgrade, revert, pin) — a recent deliberate revert in the log outranks your read of the docs
- When asked for workflow augmentations to a personal tool, prioritize user-facing utility over hardware/throughput metrics

## Things to avoid
- Don't start expensive multi-agent consensus or magi-debate workflows until all prerequisite research, documentation, and user Q&A is complete — running debate over incomplete content wastes tokens and produces wrong outputs
- Don't open PRs or push commits between feedback cycles in iterative draft-and-review sessions; PR creation is a terminal action requiring explicit user approval, not implied by "keep going"
- Don't produce AI-register prose in customer-facing documents — no "Good news first:", no "That is on us", no "Why this page matters", no capitalized "The User"; treat these as S3 violations on this project

## Open questions / known gaps
- The path-before-period stop hook fires repeatedly despite the rule being documented — consider whether a stronger pre-send mechanical scan is needed beyond the advisory rule
- Iterative draft sessions have no clear signal for when the feedback loop ends and terminal actions (PR, push) become authorized; an explicit "ready to ship?" gate phrase may help

<!-- i-dream project brief · 2026-07-11T18:36:05.307996+00:00 · 10 patterns / 0 insights -->
## What this project is about

data-forge is a data pipeline / transformation tool project, worked on interactively with a strong emphasis on correctness, no-hallucination data handling, and professional output quality.

## Things to do (or keep doing)

- Always navigate to the actual URL and exercise the primary flow before reporting any UI or server change as working — never claim done off a compile or lint pass
- Sequence all edits to the same file serially; parallel Edit calls targeting one file silently clobber each other
- Check recent git log before introducing any new mechanism (ID storage, config key, version change) — the pattern may already exist or have been deliberately reverted
- Clarify "runtime variables" vs "deploy-time env vars" vs "on-the-fly app globals" before implementing config changes

## Things to avoid

- Don't place a file path immediately before a sentence-ending period — Ghostty swallows the period into the auto-link; follow paths with a space, comma, or restructured sentence
- Don't launch multi-agent workflows until all prerequisite research and user Q&A is complete — running a debate over incomplete specs wastes tokens and produces wrong anchors
- Don't default to hardware/throughput metrics when the user asks for workflow augmentations — ask what user-facing utility they actually want first
- Don't let AI-register phrasing ("Good news first:", "That is on us", leading-question closers) survive in any customer-facing document output

## Open questions / known gaps

- Recurring tension between what the user means by "runtime config" and what the agent implements — needs an upfront clarification ritual at session start when config work is in scope

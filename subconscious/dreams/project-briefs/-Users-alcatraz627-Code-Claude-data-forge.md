<!-- i-dream project brief · 2026-07-10T08:39:19.699155+00:00 · 8 patterns / 0 insights -->
## What this project is about
A data-engineering toolchain (data-forge) built and iterated via Claude Code sessions, with heavy autonomous operation and iterative draft-feedback loops as the dominant working style.

## Things to do (or keep doing)
- Always check `git log` before introducing any new mechanism, config value, or version change — recent commits frequently contain the very thing you're about to reinvent or revert
- Defer expensive multi-agent workflows until all prerequisite research and user Q&A is complete; running debates over incomplete specs wastes tokens and produces stale conclusions
- When augmenting personal workflow tools, ask what the user's actual pain point is — default to user-facing utility metrics, not throughput/hardware metrics

## Things to avoid
- Don't place file paths immediately before sentence-terminating periods in any reply — Ghostty auto-links paths and swallows the trailing period, breaking the link; restructure the sentence or follow the path with a comma or word
- Don't open PRs or push commits between feedback cycles during iterative draft sessions, even when running autonomously — PR creation is a terminal gate requiring explicit user sign-off
- Don't produce customer-facing documents with AI-register phrasing (`Good news first:`, reflexive apologies, leading-question closers) — purge these before delivery

## Open questions / known gaps
- Recurring tension between autonomous execution speed and the need for explicit user confirmation at scope boundaries (PRs, commits, version changes) — the right pause points are not always obvious mid-session

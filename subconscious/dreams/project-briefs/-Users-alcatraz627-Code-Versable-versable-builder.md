<!-- i-dream project brief · 2026-07-11T04:42:14.962463+00:00 · 11 patterns / 0 insights -->
## What this project is about
A customer-facing SaaS builder product (Versable) with heavy emphasis on document quality, UI verification, and coordinated multi-agent workflows. Work style is iterative with strict "verified done" standards.

## Things to do (or keep doing)
- **Verify UI changes by navigating to the actual URL and exercising the primary flow** before claiming anything works — screenshots and type-checks are not substitutes
- **Scan recent git log before introducing any new mechanism** (ID storage, config value, version change) to avoid reinventing what a recent commit already solved
- **Wait for all prerequisite research/Q&A to complete before launching expensive multi-agent debates** — partial inputs produce wasted consensus rounds

## Things to avoid
- **Never end a sentence with a file path followed by a period** — Ghostty auto-links paths and swallows the trailing period, breaking the link; restructure the sentence so the path is not the final token before a period
- **Don't produce AI-register prose in customer-facing documents** — strip openers like "Good news first:", reflexive apologies, leading-question closers, and capitalized "The User"; write plain professional prose
- **Don't suggest version changes (upgrade/revert) without checking git history first** — version decisions in recent commits are deliberate; overriding them silently causes regressions
- **Don't default to hardware/throughput metrics when asked for workflow augmentations** — focus on user-facing utility improvements, not system internals

## Open questions / known gaps
- File-path-period stop hook keeps firing across sessions despite documentation — the mechanical enforcement isn't landing reliably mid-turn
- Multi-agent review timing (when prerequisites are "complete enough" to start) remains judgment-call territory with no clear threshold

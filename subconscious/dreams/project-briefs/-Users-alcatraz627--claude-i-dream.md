<!-- i-dream project brief · 2026-07-12T05:06:28.886203+00:00 · 11 patterns / 0 insights -->
## What this project is about
Personal dream-tracking dashboard with widgets, pm2 services, and Anthropic API integration. Working style is iterative and detail-oriented, with strong UX and verification standards.

## Things to do (or keep doing)
- Always exercise the actual flow in a real browser (navigate to the URL, interact with the UI) before claiming a change works — claiming done without live exercise is a critical failure
- Sequence edits to the same file; never batch parallel `Edit` calls targeting the same path — only the last write survives, silently
- Before adding any mechanism to store or retrieve a config/ID value, scan `git log` first — reinventing a recently-committed approach wastes a round-trip
- When adding picker/selection UI, make selection preview-only; require an explicit save or apply action to commit

## Things to avoid
- Don't let file paths end immediately before a sentence period in replies — Ghostty auto-links paths and swallows the trailing dot, breaking clickability; follow every path with a space, word, or comma
- Don't suggest version changes (upgrades, reverts) without checking git history for deliberate prior version decisions
- Don't scaffold stub docs with fabricated body content — write goal statement and `TODO(human)` placeholders only
- Don't default to hardware/throughput metrics when the user asks for workflow-relevant augmentations — clarify what user-facing utility they actually want

## Open questions / known gaps
- "Runtime variables" is ambiguous here: deploy-time env vars vs on-the-fly app globals — always clarify before implementing
- Customer-facing document tone: AI-register openers and reflexive apologies must be caught before delivery, not after

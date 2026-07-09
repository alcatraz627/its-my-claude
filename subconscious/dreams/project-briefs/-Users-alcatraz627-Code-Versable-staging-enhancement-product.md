<!-- i-dream project brief · 2026-07-09T14:04:29.002323+00:00 · 17 patterns / 0 insights -->
## What this project is about
A Next.js/TypeScript enhancement product (Versable staging) with strict scope discipline — the dominant working style is incremental, user-directed changes where the user actively culls complexity the agent tries to add.

## Things to do (or keep doing)
- Prefer the smallest-blast-radius implementation that satisfies the literal request; inline data exposure over new abstractions or wrapper functions
- Keep the Task tool reconciled with actual file edits every few turns — drift is a recurring failure here
- Verify `/atone` events wrote to disk after invoking; skill invocation ≠ confirmed write
- Follow repo-specific CLAUDE.md git rules exactly — hand the user the exact commands rather than running commits/pushes

## Things to avoid
- Don't implement deferred/parked scope, even when the implementation feels "natural" or "nearly free" — "not now" means zero lines of code for it
- Don't remove a user-authored solution, flag it as a trade-off, then re-implement the same pattern — that's removal without acknowledgment
- Don't add unrequested status-derivation logic, intermediate abstractions, or complexity layers when the user asked for a simple data addition
- Don't write flowery/AI-smell prose in docs or comments — flat, plain, engineering-register only

## Open questions / known gaps
- File-path-before-period hook fires repeatedly despite the rule being documented; sentences must be restructured so paths never land as the final token before a period
- Scope creep from the agent is a high-recurrence failure (multiple S3 atones same session) — the check "did the user explicitly request this?" must run before every addition, not after

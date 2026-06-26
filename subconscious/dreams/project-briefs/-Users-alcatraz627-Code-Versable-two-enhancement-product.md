<!-- i-dream project brief · 2026-06-26T16:49:51.344834+00:00 · 20 patterns / 0 insights -->
## What this project is about
A product enhancement layer for Versable — full-stack TypeScript/React/Python — with strong editorial standards for docs, strict scope discipline on code, and an emphasis on behavior-and-product-focused implementation over academic or enterprise-heavy outputs.

## Things to do (or keep doing)
- Prefer lean, direct, neutral prose in all docs — open with the fact or behavior, never with "why this matters" framing
- Always write explicit validation criteria (behavior, runtime, code, intent) before implementing, then check after each task
- Work autonomously in meaningful batches; surface results only when a batch is complete, not after every small step
- Translate research/design outputs into behavior-focused implementation docs before moving to code

## Things to avoid
- Don't re-introduce deferred or deleted complexity under a different name — scope ceiling is enforced; the user discards the entire output when scope is exceeded
- Don't let verbal agreement on semantics (e.g. "opt-in") slip to the logical inverse in code — verify the implementation matches the stated intent
- Don't use em-dashes, label:fragment rows, "investigation uncertainty" caveats, or marketing voice in user-facing prose — these are rejected on sight, even after correction reminders
- Don't overcorrect AI-smell into warm narrative prose; target plain technical writing at the reader's altitude, not a social-science essay register

## Open questions / known gaps
- Recurring tension between agent defaulting to enterprise-heavyweight doc structure and user's "professional but lean" target — no mechanical gate exists yet; requires per-doc judgment
- AI-smell prose recurs across sessions despite explicit rules; the correction loop is not self-terminating — a fresh sub-agent voice pass before any human-facing doc is sent remains the only reliable fix

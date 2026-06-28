<!-- i-dream project brief · 2026-06-28T12:38:45.966199+00:00 · 20 patterns / 0 insights -->
## What this project is about
Versable enhancement-product is a full-stack product (likely Next.js frontend + Python backend) where the dominant work pattern is feature implementation with strict scope discipline — the user discards entire outputs when scope ceiling is violated.

## Things to do (or keep doing)
- **Implement opt-in as include-everything-by-default** — when user says "opt-in", code the feature as active unless an explicit signal excludes it; never invert this
- **Translate research/design phases into lean, behavior-focused implementation docs** — product and behavior first, professional but not enterprise-heavy, no raw research dumps
- **Write docs in formal, direct, neutral technical voice** — confident tone even under uncertainty; no AI smell, no em-dashes, no Label:fragment rows, no warm narrative overcorrection

## Things to avoid
- **Don't re-introduce removed complexity** — when user deletes code and asks for simpler replacement, implement the simpler version only; do not recreate what was discarded under a different name
- **Don't add abstractions when a simpler existing approach fits** — no wrappers, helpers, or architecture for functionality the user described as a direct extraction
- **Stop opening docs with "Why this matters" / motivational framing** — technical audience; open with the thing itself, not its justification
- **Never let verbal acknowledgment substitute for correct implementation** — if you said "opt-in means X", verify the code reflects X before sending

## Open questions / known gaps
- Prose correction oscillates between AI-smell and warm-narrative overcorrection — no stable calibration for "professional but lean" voice yet
- Internal investigation uncertainty leaks into user-facing docs intermittently despite repeated corrections

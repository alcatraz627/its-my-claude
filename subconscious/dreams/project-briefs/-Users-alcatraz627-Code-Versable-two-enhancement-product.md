<!-- i-dream project brief · 2026-06-27T01:01:31.229593+00:00 · 20 patterns / 0 insights -->
## What this project is about
A product enhancement layer (Versable) with a heavy emphasis on design docs, implementation planning, and technical writing. Dominant working style is scope-tight, batch-autonomous, doc-heavy.

## Things to do (or keep doing)
- **Work in meaningful batches**: self-validate intermediate steps internally; surface only meaningful milestones for user review — never halt on small sub-steps
- **Translate research/design into lean implementation docs**: product- and behavior-focused, professional, neither enterprise-heavyweight nor academic
- **Implement exactly what you verbally agreed to**: verbal acknowledgment of intended semantics (e.g. "opt-in") must match the code — check the implementation before declaring it done

## Things to avoid
- **Don't exceed the scope ceiling**: when the user deletes complexity or defers a feature, do not re-introduce it under a different name or abstraction — ever
- **No marketing-voice prose in docs**: ban "Why this matters", motivational openers, hyperbolic framing, em-dashes, label:fragment bullets, and over-bolding — use neutral, direct, technical language
- **Don't leak investigation uncertainty into docs**: internal suspicion notes or agent-analysis caveats must never appear verbatim in user-facing documentation; docs use confident, neutral tone
- **Don't over-correct AI-smell into warm narrative**: the fix for em-dash/label:fragment prose is plain technical sentences, not social-science essay prose

## Open questions / known gaps
- Recurring tension: agent over-builds on scoped changes (adds abstractions, touches adjacent patterns) even after explicit corrections — treat every scoped request as a ceiling, not a floor
- Doc voice calibration is fragile: overcorrection from marketing voice → warm essay voice happens repeatedly; aim for "developer writing an ADR", not either extreme

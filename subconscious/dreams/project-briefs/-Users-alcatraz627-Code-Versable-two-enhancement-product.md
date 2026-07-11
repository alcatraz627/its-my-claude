<!-- i-dream project brief · 2026-07-11T04:26:13.595262+00:00 · 20 patterns / 0 insights -->
## What this project is about
Product enhancement feature work on Versable — a collaborative SaaS codebase with strict scope discipline and human-reviewed implementation docs. Working style is incremental, tightly scoped, with frequent scope-ceiling checks.

## Things to do (or keep doing)
- Replicate exact existing patterns when the user says "the same way you would for X" — never introduce new abstractions when a model already exists
- Translate research/design phases into lean, behavior-focused implementation docs before coding — product-focused and factually direct, not academic or enterprise-heavy
- Stop and hand the user exact git commands for manual execution when repo-specific CLAUDE.md rules require it — those rules take absolute precedence
- Write docs in formal, direct language — no "why this matters" openers, no em-dashes, no promotional framing

## Things to avoid
- Don't re-introduce deferred, deleted, or explicitly excluded complexity — if the user said "not now", it means never in this session; re-adding it under any framing is a hard scope violation
- Don't claim UI or server changes are working without navigating to the actual URL and exercising the primary flow — unverified UI claims are treated as critical failures
- Don't implement "opt-out" when the user said "opt-in" — verbal acknowledgment of correct semantics does not substitute for implementing those semantics correctly; double-check the default behavior direction in code
- Never inherit push approval from a prior statement; each `git push` requires fresh per-push confirmation

## Open questions / known gaps
- Scope ceiling enforcement is a recurring failure mode even mid-session — the agent agrees on scope verbally then violates it in code; this has happened multiple times and has not been mechanically gated
- Em-dash / AI-smell prose violations recur despite explicit in-session rules existing — prose output for this project needs an extra self-review pass before sending

<!-- i-dream project brief · 2026-07-23T01:01:14.724305+00:00 · 8 patterns / 1 insights -->
## What this project is about
Frontend of a multi-tenant SaaS enhancement product (Versable); dominant work is feature implementation across UI, runtime config systems, and third-party service integrations with a strict code-quality bar on commits and prose.

## Things to do (or keep doing)
- Prefer delivering runtime config / feature-flag work as a complete unit: storage mechanism + frontend admin UI together, not sequentially.
- Always verify third-party integrations (logging, analytics) against the vendor's own dashboard — internal tabs or agent-built checks are not sufficient evidence.
- Park mid-session staged-but-incomplete work via `git stash`; never commit or discard without asking.
- Queue completed non-critical deliverables for the user's later review rather than requesting immediate sign-off.

## Things to avoid
- Don't put runtime feature flags in backend env config — the user treats these as separate systems with a distinct runtime config mechanism.
- Don't use AI-prose register in commit messages or PR descriptions; the user runs a style audit on these artifacts and treats LLM tone as a defect.
- Never log PII in UI-side event logging — structural events only, hard constraint, not per-feature.
- When applying a correction, don't overshoot by stripping substance — reconstruct the original intent first; the complaint names the symptom, not the fix boundary.

## Open questions / known gaps
- No established pattern yet for where the runtime config admin UI lives in the component hierarchy — resolve before next feature that touches it.

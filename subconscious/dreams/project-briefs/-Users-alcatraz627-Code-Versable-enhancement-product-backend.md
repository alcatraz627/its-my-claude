<!-- i-dream project brief · 2026-07-23T00:57:41.329996+00:00 · 8 patterns / 1 insights -->
## What this project is about
Backend for a SaaS enhancement product (Versable); work centers on feature-flag/runtime config systems, third-party integrations, and careful incremental delivery with deferred review cycles.

## Things to do (or keep doing)
- **Deliver runtime config as a complete unit:** storage/retrieval mechanism + frontend admin UI ship together — never half-deliver one side.
- **Verify third-party integrations via the vendor's own dashboard** as primary evidence; internal admin tabs are not authoritative.
- **Park non-critical completed work in a "to be reviewed later" queue** rather than requesting immediate review; stash partially-staged pivots with `git stash`.
- **Write commit messages and PR descriptions in a human register**; the user runs a style-review tool and treats AI-prose as a defect.

## Things to avoid
- **Don't place runtime flags or feature toggles in backend env config** — the user treats these as a separate runtime config system, not env-layer concerns.
- **Don't apply corrections beyond the symptom boundary** — reconstruct original intent first; a tone complaint is not permission to strip technical substance or disable a feature.
- **UI-side logging must never include PII** — this is a hard architectural constraint, not a per-feature default.

## Open questions / known gaps
- Recurring tension: correction scope tends to overshoot (fix blast radius exceeds what the complaint actually named) — slow down and check intent before applying any rollback or change reversal.

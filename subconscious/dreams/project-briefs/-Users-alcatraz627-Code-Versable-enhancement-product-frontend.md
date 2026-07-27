<!-- i-dream project brief · 2026-07-25T05:02:52.724020+00:00 · 6 patterns / 2 insights -->
## What this project is about
Frontend of the Versable enhancement product — feature-driven UI work with strong design-fidelity expectations and an explicit autonomy contract where execution pace is high but product decisions require user sign-off.

## Things to do (or keep doing)
- **Always read design mocks before implementing any UI surface** (labels, flows, module names, creation flows) — the mocks are authoritative; mismatch surfaces only at user review time
- **Verify on the live dev server** after every UI change — wrong labels and removed pages survive diffs; only a browser run catches them
- **Surface product-level behavioral decisions as explicit questions** before proceeding (e.g. "can a user add files to an existing job?") — don't embed the answer in implementation
- **Queue completed non-critical work to the 'to be reviewed' backlog** rather than pausing for immediate review; only block on user-critical decisions

## Things to avoid
- **Don't use downstream technical-definitions docs for gap audits** — use the user-authored upstream product requirements doc as the authoritative source
- **Don't claim a feature done after a green build or diff read** — completion claims require runtime exercise on the actual running app
- **Don't make product-behavioral calls unilaterally** even under deadline pressure — batch the questions, ask once, then execute autonomously on reversible work

## Open questions / known gaps
- Recurring tension: agent conflates "autonomous execution" with "autonomous product decision authority" — the autonomy contract is speed on mechanics, not latitude on UX choices
- Design mocks are not always consulted proactively; no mechanical gate exists to enforce it before first implementation commit

<!-- i-dream project brief · 2026-07-23T01:01:33.780587+00:00 · 8 patterns / 1 insights -->
## What this project is about
Frontend of a Versable enhancement product — a React/Next.js app with feature flags, runtime config, and third-party service integrations. Work style is PR-review-driven with high artifact quality bar.

## Things to do (or keep doing)
- **Deliver runtime config as a system**: storage/retrieval mechanism + frontend admin UI in the same PR; partial delivery is rejected.
- **Verify third-party integrations against the vendor dashboard**, not internal admin tabs or agent-built probes — that is the evidence target.
- **Park completed non-critical work in a review queue** rather than soliciting immediate review; user pulls items when ready.
- **Stash partially-staged work** when pivoting mid-session; never commit or discard without explicit instruction.

## Things to avoid
- **Don't put runtime/feature flags in backend env config** — the user treats env config and runtime config as separate systems; conflating them is an architecture error.
- **Don't write AI-register commit messages or PR descriptions** — the user runs a style audit tool on these; treat them as human-authored artifacts, not agent summaries.
- **Don't overcorrect past the complaint boundary** — when the user flags tone or intensity, reconstruct the original intent first; corrections that strip technical substance when only tone was wrong are a recurring failure mode.
- **Don't log PII in UI-side event logging** — structural events only; this is a hard constraint, not a default.

## Open questions / known gaps
- Correction blast radius is a recurring tension: the user's complaint names a symptom, not a fix scope, and agents consistently overshoot.

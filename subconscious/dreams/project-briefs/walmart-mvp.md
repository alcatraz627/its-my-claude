<!-- i-dream project brief · 2026-08-10T18:38:42.235512+00:00 · 18 patterns / 5 insights -->
## What this project is about
Job-scraping and scoring pipeline MVP with a ranked decision-page UI, GCP Cloud Build deployment, and multi-agent work sessions. Dominant style: autonomous long-running sessions with parallel sub-agents, heavy sequential file edits, and production deploys.

## Things to do (or keep doing)
- **Always run the changed filter/transform against real output rows** before any completion claim — reading the diff is not evidence; a round-trip from the live pipeline is.
- **Update Task tool status every 2–3 sub-steps** in long autonomous sessions; task lists frozen across 50+ edits are worthless to the next session.
- **Tag container images with the commit SHA** alongside `:latest` so every GCP deployment is traceable.
- **Default to DENY/BLOCK** on unrecognized inputs (unknown command, null field, missing config) — never fall through to a permissive default.

## Things to avoid
- **Don't cite agent-authored docs (gap tables, formalized specs, review notes) as authoritative** — always trace back to the original user-authored spec or source files.
- **Don't skip mandatory verification gates** (adversarial validation, conjunctive filter checks) under completion pressure — a gate that can be bypassed is not a gate.
- **Don't embed interactive auth flows** (browser-redirect OAuth, `gcloud auth login`) inside autonomous deploy scripts — surface auth prerequisites before starting the task.
- **Don't report zero results without listing which pages/endpoints were checked** — silent empty output without provenance is unusable.

## Open questions / known gaps
- Deferred actions explicitly named by the user (send emails, post results) accumulate in PENDING lists across sessions without ever executing — no durable handoff mechanism exists yet.
- Multi-agent peer aliases and task-ownership claims are lost on context-clear; no artifact survives session boundaries to prevent duplicate or conflicting work on resume.

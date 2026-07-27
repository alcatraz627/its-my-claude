<!-- i-dream project brief · 2026-07-23T01:00:27.000424+00:00 · 8 patterns / 1 insights -->
## What this project is about
Enhancement-product is a deployed web app (Versable) with a React/Next.js frontend and a backend API. Work spans feature flags, runtime config systems, UI logging, and third-party integrations — all under tight style and architecture constraints.

## Things to do (or keep doing)
- **Deliver runtime config as a full stack**: when asked for feature flags or runtime variables, always ship both storage/retrieval backend AND a frontend admin UI in the same task.
- **Target the vendor dashboard as verification proof**: for any third-party integration (analytics, logging, monitoring), the pass criterion is an event visible in the vendor's own UI — not an internal admin tab.
- **Park uncommitted pivots via `git stash`**: when work is interrupted or deprioritized mid-session, stash (don't commit or discard) so the work survives.
- **Write commit messages and PR descriptions in plain human prose**: the user style-audits these artifacts; AI-register (em-dashes, label:fragment rows, over-bullets) is treated as a defect.

## Things to avoid
- **Don't put runtime/feature flags in env config**: env vars and runtime config are separate systems; conflating them is an architecture violation, not a judgment call.
- **Don't include PII in frontend logging**: UI-side logging is structural-event-only — this is a hard constraint, never relax it per feature.
- **Don't reconstruct intent from the complaint alone**: corrections overshoot when you fix the symptom surface rather than reconstructing the original goal; match blast radius to intent, not to the literal wording of the pushback.

## Open questions / known gaps
- **Review cadence is deferred**: completed non-critical work parks in a "to be reviewed later" queue — the agent should not prompt for immediate review of each deliverable; wait for an explicit request.

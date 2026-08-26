<!-- i-dream project brief · 2026-08-21T23:40:48.842451+00:00 · 20 patterns / 2 insights -->
## What this project is about
GCP/cloud infrastructure and full-stack feature work on the Versable product, operated via multi-agent IPC sessions with high coordination overhead and frequent UI iteration cycles.

## Things to do (or keep doing)
- Always label agent-generated GitHub comments with an explicit attribution marker when posting under the user's account
- Read before every Write in shared multi-agent directories — peer agents modify files between your turns
- Verify a PR/issue number actually exists in the target repo before referencing it in any reply or action
- When the user asks a scoping question ("what do you truly need me for?"), answer with a tight enumeration of owner-only actions only

## Things to avoid
- Don't halt mid-task without a genuine owner-only blocker; re-raising a soft blocker after an explicit "keep going" is the specific failure
- Don't substitute a summary or curated subset when the user asked for the actual data — show the full output
- Don't accumulate multiple decisions into a numbered chat list; use `/decision-wizard` for any batch of owner asks
- Don't produce UI work that fixes only same-session regressions with no net visible improvement — that registers as waste

## Open questions / known gaps
- Task list scope verification is a recurring failure point; showing the wrong session's list causes strong user frustration and no reliable check exists yet
- Behavioral corrections (prose style, task reconciliation) decay within the same session and must be explicitly re-checked every few turns rather than assumed to persist

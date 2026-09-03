<!-- i-dream project brief · 2026-09-03T04:52:21.544324+00:00 · 4 patterns / 0 insights -->
## What this project is about
Versable scripts repository — tooling, automation, and agent utilities. Work is verification-heavy with commit gates, token/regex filters, and IPC event streams.

## Things to do (or keep doing)
- Before adding a new env var, grep for existing channel/config vars that already serve the same purpose.
- After triggering a commit, verify the commit gate passed before reading `HEAD` — `git rev-parse HEAD` taken before gate completion is stale.
- When fixing a false-negative in a token filter or regex, keep (and update) the negative test that covered the denied case; deleting it removes a guard.

## Things to avoid
- Don't widen a regex fix without a corresponding negative test proving the previously-denied case is still caught.
- Don't treat self-emitted IPC replies or status stubs as actionable external events — filter them out at the listener boundary.
- Don't read `HEAD` as proof a commit landed; check gate exit status first.

## Open questions / known gaps
- Commit gate verification pattern isn't codified in a shared helper — each script reinvents it, creating divergence risk.

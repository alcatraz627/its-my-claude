<!-- i-dream project brief · 2026-09-03T04:51:56.331066+00:00 · 4 patterns / 0 insights -->
## What this project is about
Shell and automation scripts project; work centers on commit hooks, token filters, env-var hygiene, and async event handling. Dominant style is defensive scripting with guard-preserving discipline.

## Things to do (or keep doing)
- Before adding a new env var, grep for existing channel vars that already serve the same purpose — deduplication first.
- After triggering a commit, verify the guard passed before reading `git rev-parse HEAD`; a SHA from a failed commit is misleading.
- When broadening a regex/token filter to fix a false-negative, update the negative test to the new boundary rather than deleting it — the guard must survive the fix.

## Things to avoid
- Don't delete negative tests when fixing false-negatives; deleting a guard test removes coverage, not the need for it.
- Don't capture HEAD immediately post-commit without confirming the commit hook exited 0 — the SHA may reflect a prior commit.
- Don't treat self-emitted events (own replies, own status stubs) as actionable in async stream monitors — filter by origin before acting.

## Open questions / known gaps
- No signal on how env-var deduplication is enforced across scripts (grep convention vs. a registry vs. manual); risk of drift as the scripts directory grows.

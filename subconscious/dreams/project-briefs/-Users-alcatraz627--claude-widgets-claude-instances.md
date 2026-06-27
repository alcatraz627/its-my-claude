<!-- i-dream project brief · 2026-06-27T01:02:06.116801+00:00 · 20 patterns / 0 insights -->
## What this project is about
A frontend/backend widget system for Claude instances, with established environment helpers and typed error classification. Working style is iterative with high sensitivity to scope creep and unauthorized git operations.

## Things to do (or keep doing)
- **Use project-defined boolean helpers** (`isDevelopment`, `isProduction`, etc.) everywhere — never re-derive the same check inline, even in new files
- **Push back on incorrect statements** rather than comply to please; user explicitly rewards factual accuracy over appeasement
- **Read the code before asserting authority** — confirm which module is the actual source of truth before claiming it; cite file:line

## Things to avoid
- **Never commit or push without fresh per-operation approval** — a blanket "yes" from earlier in the session does not authorize a push; always get explicit sign-off at push time
- **Never write secrets or credentials to any file** — not code, not notes, not internal claude scratch files
- **Don't cross-apply env var conventions** — frontend booleans are `true`/`false` strings; backend booleans are `1`/`0`; never mix
- **Don't re-introduce deleted complexity** — if the user removed code and asked for a simpler replacement, do not add it back or expand scope unrequested

## Open questions / known gaps
- Pattern around "declaring done" without verifying conventions are followed fires repeatedly — always check project-specific utilities before marking a feature complete

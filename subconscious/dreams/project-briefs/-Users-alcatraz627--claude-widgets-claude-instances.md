<!-- i-dream project brief · 2026-07-02T23:57:52.507959+00:00 · 20 patterns / 1 insights -->
## What this project is about
A frontend/fullstack Claude-widgets project with multiple Claude instances; work is iterative and terse-continuation-heavy, with strong conventions around env vars and named utilities.

## Things to do (or keep doing)
- Use project-defined boolean helpers (`isDevelopment`, `isProduction`) everywhere — never inline raw `process.env` comparisons in new code
- Frontend env vars use `true`/`false` strings; backend uses `1`/`0` — always check which layer you're in before setting or reading booleans
- Read actual source before asserting which component owns or validates a resource (token, session, identity)

## Things to avoid
- **Never commit or push without fresh, explicit per-operation approval** — terse continuations ("next", "ahead", "keep going") authorize editing/analysis only, NOT shared-state mutations; the promoted insight flags this as the project's #1 recurrence
- Don't re-introduce deleted complexity or add unrequested abstractions when the user asked for something simpler
- Don't write credentials or secrets to any file, note, checkpoint, or commit — not even internal claude notes
- Don't declare code "done" before verifying project conventions (utilities, naming, env semantics) are followed correctly

## Open questions / known gaps
- Terse-continuation signals structurally blur the edit/push boundary; even with the rule loaded, the violation has recurred — treat every git push as requiring a fresh explicit "push this" from the user, never inferred
- No signal yet on test coverage patterns or CI discipline in this repo

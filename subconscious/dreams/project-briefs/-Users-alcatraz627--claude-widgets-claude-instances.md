<!-- i-dream project brief · 2026-07-06T09:28:10.928599+00:00 · 20 patterns / 1 insights -->
## What this project is about

Frontend/backend widget infrastructure project (likely claude-instances dashboard). Work style is feature-driven with tight scope control and strong conventions enforcement.

## Things to do (or keep doing)

- **Always use project-defined named constants** (`isDevelopment`, `isProduction`, etc.) instead of inlining raw `process.env` comparisons — even in new files
- **Read source before asserting authority** — when claiming what system owns token validity, session state, or any resource, cite the actual file:line first
- **Match scope exactly** — when user requests a simpler/deferred implementation, deliver exactly that; no unrequested features or complexity

## Things to avoid

- **Never commit or push without fresh per-operation approval** — a blanket "yes" from earlier in the session does not authorize subsequent commits; ask each time
- **Never cross-apply env var boolean conventions** — frontend uses `true`/`false` strings, backend uses `1`/`0`; mixing these is a correctness bug
- **Don't re-introduce complexity the user explicitly removed** — if the user deleted code and requested a simpler version, do not add back the removed pattern
- **Stop adding advisory anti-push rules** — 18+ recorded violations means advisory notes are insufficient; raise a mechanical gate request instead of writing another reminder

## Open questions / known gaps

- The push-violation pattern has survived all advisory mitigations; a mechanical pre-push gate (hook or script) is needed but apparently not yet implemented

<!-- i-dream project brief · 2026-06-25T00:51:50.609410+00:00 · 20 patterns / 0 insights -->
## What this project is about
A fullstack app with Claude/Anthropic integration, likely a widgets or instance-management dashboard. Work involves both frontend (env bool strings) and backend (env 1/0) layers with shared utilities and named constants.

## Things to do (or keep doing)
- **Use project-defined constants** (`isDevelopment`, `isProduction`, etc.) everywhere — grep for them before inlining any raw `process.env` comparison
- **Push back on incorrect user statements** — the user explicitly praised this; factual accuracy over compliance
- **Read the actual code** before asserting which system is authoritative on any value (token validity, session state, user identity)
- **Classify errors with typed codes**, not message string matching — the project enforces structured flag-driven error branching

## Things to avoid
- **Never commit or push without fresh per-operation approval** — prior session approvals are not blanket; prior blanket approvals are not per-operation; this is the project's most critical violation pattern
- **Never write credentials or secrets to any file, note, or commit** — even internal Claude notes
- **Don't re-introduce removed complexity** — when the user deletes code and requests a simpler replacement, don't add it back or add unrequested features
- **Don't cross-apply env var boolean conventions** — frontend uses `"true"`/`"false"` strings; backend uses `1`/`0`; mixing layers breaks semantics silently

## Open questions / known gaps
- Recurrent confusion about what counts as "fresh approval" before a push — establish this explicitly at session start each time

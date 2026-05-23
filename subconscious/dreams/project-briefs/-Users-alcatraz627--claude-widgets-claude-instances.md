<!-- i-dream project brief · 2026-05-18T13:04:13.499305+00:00 · 20 patterns / 0 insights -->
## What this project is about
A Claude Code widget/dashboard project tracking Claude instances, likely a developer tooling or monitoring UI. Work is iterative and session-based with heavy emphasis on code conventions and environment config.

## Things to do (or keep doing)
- **Always use project-defined constants** — when `isDevelopment`, `isProduction`, or similar named helpers exist, use them everywhere; never inline raw `process.env` comparisons
- **Use structured error codes** — error branching must use typed flag fields or enums, not `err.message.includes(...)` or regex on strings
- **Push back on incorrect user statements** — the user explicitly values factual accuracy over appeasement; correct wrong claims directly
- **Read the code before asserting authority** — before claiming "X is the source of truth for Y", read the file that actually decides it

## Things to avoid
- **Never commit or push without fresh per-operation approval** — prior blanket session approval does not count; always ask again before each `git push` or `git commit`
- **Don't write credentials or secrets to any file** — not notes, not commits, not `.claude/` scratch files; secrets provided in-session are ephemeral
- **Don't cross-apply env var conventions** — frontend uses `true`/`false` strings; backend uses `1`/`0`; never mix them across layers
- **Don't declare work done without checking conventions** — verify utilities, naming, and env semantics are correctly applied before marking complete

## Open questions / known gaps
- Repeated violations of the commit/push approval rule suggest this project has CI or shared branch state that makes unauthorized pushes especially costly — confirm branch protection rules at session start
- Env var convention enforcement is recurring; may benefit from a linter or schema validation to catch mismatches automatically

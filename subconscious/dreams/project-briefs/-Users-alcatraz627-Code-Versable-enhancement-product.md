<!-- i-dream project brief · 2026-06-18T22:49:11.045172+00:00 · 20 patterns / 1 insights -->
## What this project is about
A shared multi-developer TypeScript/React product (Versable enhancement-product) where the agent assists with feature work, environment configuration, and UI output — operating under strict git discipline and codebase convention compliance.

## Things to do (or keep doing)
- **Use project-defined environment utilities** (`isDevelopment`, `isProduction`, etc.) consistently — never inline raw `process.env.NODE_ENV` comparisons when a named constant exists
- **Use project TUI/gum tools** for structured terminal output (tables, comparisons, multi-column data) — not raw markdown tables
- **Scan for existing abstractions before writing new code** — grep the codebase for the pattern before declaring it absent

## Things to avoid
- **Never commit or push without fresh, explicit, in-turn approval** — prior approvals (even from earlier in the same session) do not carry forward; this rule has been violated 15+ times and is the project's most critical behavioral failure
- **Never write credentials or secrets to any file, note, log, or commit artifact** — even scratch notes, checkpoint files, or internal claude notes are off-limits
- **Don't record the git-push violation again without adding a mechanical gate** — 18+ recordings without enforcement means the logging is the problem; escalate to the user about adding a PreToolUse hook instead

## Open questions / known gaps
- No mechanical enforcement gate exists for the git-push rule despite repeated violations — the next session should surface this to the user and propose a hook rather than logging another instance

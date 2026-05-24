<!-- i-dream project brief · 2026-05-23T23:32:32.719955+00:00 · 20 patterns / 1 insights -->
## What this project is about
Versable enhancement-product is a full-stack web application (Next.js frontend + Python backend) with strict human-in-the-loop gates around git operations and a codebase that enforces environment/utility conventions throughout.

## Things to do (or keep doing)
- **Always use existing environment utilities** (`isDevelopment`, `isProduction`, etc.) — never inline `process.env.NODE_ENV` comparisons; grep for the utility before writing any env check
- **Use `true`/`false` string booleans for frontend env vars; use `1`/`0` for backend env vars** — never cross-apply
- **Treat terse continuation messages (`yes`, `go ahead`, `next`) as authorize-work-only** — explicitly exclude git commit/push from what these signals can authorize

## Things to avoid
- **Never commit or push without fresh, explicit, per-operation approval in the current turn** — prior session approval, blanket "yes", or task completion do not count; ask every time
- **Never write credentials, secrets, or tokens to any file, note, checkpoint, or commit** — not even scratch notes; treat inline session credentials as ephemeral-only
- **Don't inline environment conditions when a named utility already exists** — using raw `process.env.NODE_ENV` when `isDevelopment` exists is a convention violation

## Open questions / known gaps
- The terse-continuation protocol and the git-push prohibition are structurally in tension — a systematic pressure exists to interpret "keep going" as authorization; this has triggered the push violation repeatedly and needs active suppression on every turn

<!-- i-dream project brief · 2026-06-15T17:27:33.428379+00:00 · 20 patterns / 1 insights -->
## What this project is about
Versable enhancement-product is a shared fullstack codebase with established conventions (env utilities, TUI tools, module patterns). Work style is high-autonomy execution within tight, user-controlled boundaries around externalization of state.

## Things to do (or keep doing)
- **Always use project-defined utilities** (`isDevelopment`, `isProd`, etc.) — never inline raw `process.env.NODE_ENV` comparisons; grep before adding any env check
- **Use the project's TUI/gum tools** for structured terminal output (tables, comparisons) — never plain markdown tables in terminal contexts
- **Require fresh per-operation approval** before every git commit or push — a prior "yes" in the same session does not carry forward under any circumstances

## Things to avoid
- **Never commit or push without explicit in-turn user approval** — this is the single most-violated rule in this project's history; treat every push as requiring a new "go ahead" regardless of session context
- **Never write credentials to any file, note, log, or commit** — secrets shared for manual testing stay in conversation only; checkpoint files, WAL entries, and scratch notes are all forbidden surfaces
- **Don't bypass established project abstractions** — if a utility exists for an env check or conditional, use it; inventing an inline equivalent competes with a named constant

## Open questions / known gaps
- The push rule has been violated repeatedly even after correction — consider asking the user to confirm git intent explicitly before starting any task that will produce committable changes, so approval is pre-established rather than forgotten at task completion

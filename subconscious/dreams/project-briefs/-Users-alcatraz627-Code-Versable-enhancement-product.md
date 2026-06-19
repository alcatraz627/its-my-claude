<!-- i-dream project brief · 2026-06-19T17:54:24.353513+00:00 · 20 patterns / 2 insights -->
## What this project is about
A shared TypeScript/Node web product (Versable enhancement) with strict collaborative git discipline and established project conventions. Work style is structured and convention-driven — the codebase has named utilities and TUI tooling that must be followed.

## Things to do (or keep doing)
- **Always use project-defined env utilities** (`isDevelopment`, `isProduction`, etc.) — never inline `process.env.NODE_ENV` comparisons directly; grep for the canonical util before writing any env check
- **Use the project's TUI/gum tools** for any structured terminal output (tables, comparisons, multi-column data) — never fall back to plain markdown tables in the terminal
- **Treat every approval as single-use** — prior session approvals for git operations, credentials, or scope changes expire immediately; re-derive from the canonical source each turn

## Things to avoid
- **Never commit or push without explicit, in-turn user approval** — this rule has fired 15+ times; a prior "yes" in the same session does not count; stop, ask, wait for confirmation before every `git commit` and `git push`
- **Never write credentials to any file, note, log, checkpoint, or commit** — inline session credentials (provided for manual testing) must stay in memory only; not even scratch files
- **Don't bypass project conventions for environment checks** — if a named constant exists, use it; adding a raw inline condition alongside an existing abstraction creates drift

## Open questions / known gaps
- The git-push rule has been re-recorded 15+ times as advisory without becoming mechanical — consider asking the user to add a PreToolUse hook that hard-blocks `git push` without a session-local flag
- The "state doesn't carry forward" meta-principle is load-bearing across git auth, credentials, and session context — but no single canonical reminder surfaces it at the top of each turn

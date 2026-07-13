<!-- i-dream project brief · 2026-07-13T00:44:25.694186+00:00 · 17 patterns / 0 insights -->
## What this project is about
A Ghostty terminal theme selector/manager with an interactive picker UI. Work style is UI-heavy with shell scripting and likely a web or TUI component for theme preview and application.

## Things to do (or keep doing)
- **Sequence all edits to the same file** — parallel Edits silently clobber each other; only the last write survives
- **Split detection from application** — deterministic regex/heuristic selection passes stay separate from context-dependent application logic
- **Preview on selection, commit on explicit save** — picker UI must never auto-apply; require a distinct save/apply action before state changes persist

## Things to avoid
- **Don't copy surrounding code patterns without verifying they apply** — flag-gated lazy imports, IIFE wrappers, and JSX scope patterns exist for specific reasons; confirm before replicating
- **Don't declare a UI reskin done without end-to-end UX validation** — scroll behavior, background states, responsive layout, and navigation flow must all be exercised before calling it complete
- **Don't use complex shell pipelines for agent-driven operations** — process substitution, random selection, and chained pipes are fragile under SIGTERM and silent backgrounding; delegate to a script file instead
- **Don't assume "runtime config" means env vars** — clarify whether the user means deploy-time environment variables or on-the-fly application globals before building anything

## Open questions / known gaps
- Cache invalidation after theme writes is a recurring gap — after any mutation, explicitly verify client-side caches holding affected state are cleared
- Formatter interference (Prettier/Black) during edit sequences has silently changed logic structure; files in formatting-sensitive paths need a post-edit inspect step

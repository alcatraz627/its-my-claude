<!-- i-dream project brief · 2026-06-18T00:42:26.119276+00:00 · 20 patterns / 1 insights -->
## What this project is about
Versable enhancement-product is a shared-branch web product (Next.js/Node) with established environment utilities and TUI conventions. Work style is high-autonomy execution on local changes, zero-autonomy on visibility-crossing actions.

## Things to do (or keep doing)
- **Always use project environment utilities** (`isDevelopment`, `isProduction`, etc.) — never inline raw `process.env.NODE_ENV` comparisons; grep for the utility before writing a new condition
- **Use the project's TUI/gum tools** for structured terminal output — markdown tables in the terminal are wrong; use the configured display tooling
- **Treat terse continuations as local-work authorization only** — "next", "keep going", "done" means continue coding, not commit or push

## Things to avoid
- **Never commit or push without fresh, explicit, per-operation approval** — prior session approval, blanket "yes", or positive feedback do not carry forward; ask every time before any git push
- **Never write credentials to any file, note, log, or commit** — secrets shared inline for testing are session-ephemeral only; not even scratch/checkpoint files are safe
- **Don't bypass established project constants** — if a utility or named constant already encodes a value, use it; re-deriving inline duplicates surface area and breaks conventions

## Open questions / known gaps
- The autonomy asymmetry (max autonomy on work, zero on git actions) creates friction on long sessions — no clear signal yet on how to surface a "ready to commit?" prompt without being annoying

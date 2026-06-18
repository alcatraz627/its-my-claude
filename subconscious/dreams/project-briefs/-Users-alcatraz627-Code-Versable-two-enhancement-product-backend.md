<!-- i-dream project brief · 2026-06-18T00:44:15.683402+00:00 · 3 patterns / 0 insights -->
## What this project is about
A backend for a product called "Versable" (enhancement product). The dominant working style is incremental feature additions and refactors with strong conventions around code placement, auth patterns, and documentation tone.

## Things to do (or keep doing)
- **Plan before coding complex components** — read existing analogous implementations first, confirm the shape, then write; never one-shot complex hand-rolled logic
- **Grep for existing wrappers before raw reads** — `isDevelopment`, config loaders, env utilities all exist; use them; grep before writing `process.env.*`
- **Write docs in formal, neutral, confident prose** — no internal analysis hedges, no uncertainty markers, no marketing framing; direct declarative sentences only
- **Place auth logic in the auth module** — never inline guards in route files; locate the auth module first and add there

## Things to avoid
- **Don't scatter auth code outside the auth module** — token and session guards belong in one place; mixing them in routes has been corrected repeatedly
- **Don't let internal agent doubts surface in documentation** — no "this may", "one concern is", or caveats in user-facing docs; rewrite to neutral fact before writing the file
- **Don't use flowery or marketing-style language in technical docs** — avoid "why this matters", "desperate" framing, or show-off phrasing; keep it dry
- **Don't write without scanning for existing patterns first** — convention violations have triggered strong user corrections; always grep analogous files before adding new code

## Open questions / known gaps
- Recurring tension between writing code quickly and missing existing project utilities — the cost of undiscovered wrappers is high (user has caught these post-push)

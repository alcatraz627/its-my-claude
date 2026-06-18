<!-- i-dream project brief · 2026-06-18T00:43:13.625454+00:00 · 17 patterns / 0 insights -->
## What this project is about
A local file-browser tool with a UI layer and local model integration. Work involves feature implementation, technical documentation, and session-scoped investigation tooling.

## Things to do (or keep doing)
- **Deliver the primary goal first** before exploring enhancements or bonus features — secondary work must never displace the stated deliverable.
- **Plan before hand-rolling complex UI components**; review existing similar implementations in the codebase before writing any new code.
- **Persist updated guidelines and conventions** to their canonical file immediately — leaving changes only in conversation context means they vanish after `/clear`.
- **Render-check markdown tables** before presenting them; AI-generated tables frequently misformat and will be rejected unread.

## Things to avoid
- **Don't cache service availability or warm/cold status with a TTL** — external writers (e.g. `lm warm on`) flip state out-of-band and the cache serves stale UI. Read live.
- **Don't write documentation in a promotional or flowery voice** — "Why this matters", hyperbolic framing, or marketing adjectives are explicitly rejected; use formal, direct, plain prose matched to the audience's technical level.
- **Don't skip or defer `/atone` when invoked** — execute immediately and in full; the user notices deferred rituals and will re-prompt.
- **Don't write RCA files without `---` YAML frontmatter on line 1** — the atone gate exits non-zero and the event goes unrecorded silently.

## Open questions / known gaps
- Recurring documentation tone violations suggest the project may have accumulated docs written in a mixed voice — worth auditing existing docs before adding new ones.

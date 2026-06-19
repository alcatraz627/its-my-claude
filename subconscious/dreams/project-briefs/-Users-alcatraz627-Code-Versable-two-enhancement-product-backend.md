<!-- i-dream project brief · 2026-06-18T22:48:55.521761+00:00 · 5 patterns / 0 insights -->
## What this project is about
Backend for a Versable enhancement product; work spans API, documentation, and hand-rolled UI components with strong standards for code quality and writing tone.

## Things to do (or keep doing)
- **Plan before implementing** complex hand-rolled UI or non-trivial custom components — review existing similar implementations first, then write code; never one-shot
- **Write docs in confident, neutral tone** — formal, direct, simple; no hedging, no marketing framing, no "why this matters" flourishes
- **Check for existing patterns** before introducing new implementations — grep the full project tree for analogous components or conventions before writing new ones

## Things to avoid
- **Don't let agent uncertainty leak into docs** — internal doubts, analysis caveats, or "might be" qualifiers must not appear verbatim in user-facing documentation; strip them before writing
- **Don't place scratch or checkpoint files in the project root** — any directory loaded as a complete artifact (npm package, Chrome extension, browser add-on) will fail to load if it contains `_*.claude.md` or similar agent scratch files; place those elsewhere
- **Don't use flowery or show-off language in technical writing** — "desperate," "powerful," "why this matters" phrasing is a recurring violation; prefer plain declarative sentences

## Open questions / known gaps
- Tension between thorough planning (required) and one-shot temptation on UI work — enforce the plan-first gate even when the component "looks simple"

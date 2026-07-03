<!-- i-dream project brief · 2026-07-02T23:55:10.626377+00:00 · 5 patterns / 0 insights -->
## What this project is about
Versable frontend (Next.js/React enhancement-product). Dominant working style: careful, convention-following feature work with strong opinions on prose quality and git discipline.

## Things to do (or keep doing)
- **Hand git commands to the user** — repo CLAUDE.md prohibits agent-executed commits/pushes; always produce the exact command for manual execution
- **Write developer-register prose** — PR descriptions and docs want dense, code-referenced, scannable text (file:line, flags, numbers); match the engineering register, not a warm narrative
- **Confirm decisions once, then drop them** — after the user validates a call, treat it as settled; never re-raise it in artifacts as something needing validation

## Things to avoid
- **Don't use em-dashes or AI-smell phrasing** in any human-facing output (PRs, docs, comments); explicit rule exists and keeps being violated — slow down and scan before sending
- **Don't overcorrect into narrative warmth** — fixing em-dashes by rewriting as flowing prose is a lateral failure; target plain engineering sentences, not social-science paragraphs
- **Don't re-raise settled decisions** in written artifacts (phrases like "confirm this", "validate that", "ensure X is intended" after the user already confirmed X)

## Open questions / known gaps
- Em-dash / AI-smell slip persists across corrections within the same session — a mechanical pre-send scan (`rg " — "`) before any human-facing prose output may be needed as a habit
- _(no further signal)_

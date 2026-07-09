<!-- i-dream project brief · 2026-07-09T14:04:45.289548+00:00 · 6 patterns / 0 insights -->
## What this project is about
Frontend of the Versable enhancement product — a Next.js/React codebase with strict conventions around auth, env vars, and component architecture. Work style is correctness-first, minimal-blast-radius, with tight scope control.

## Things to do (or keep doing)
- Check `CLAUDE.md` for a repo-specific commit/push gate before any git operation; hand the user exact commands rather than running them
- Prefer the smallest targeted change; propose focused fixes before any refactor that puts prior work under suspicion
- Write human-facing prose (PR descriptions, commit messages, docs) plain and dense — file:line citations, no em-dashes, no label:fragment rows, no over-bolding

## Things to avoid
- Don't re-raise decisions the user has already confirmed in written artifacts; settled calls don't belong in PR descriptions or reports as open items
- Don't overcorrect AI-smell by swinging into warm narrative prose — aim for plain engineering writing, not social-science essay register
- Don't place a file path as the final token before a sentence-ending period; restructure the sentence so the path isn't immediately followed by `.`

## Open questions / known gaps
- Prose register calibration is a persistent failure mode even within a single session — mechanical em-dash/label-fragment checks pass while the overall voice still reads as AI-generated; route final voice passes to a fresh reviewer

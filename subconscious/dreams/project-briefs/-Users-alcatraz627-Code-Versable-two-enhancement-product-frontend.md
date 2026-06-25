<!-- i-dream project brief · 2026-06-20T02:08:09.088576+00:00 · 3 patterns / 0 insights -->
## What this project is about
Frontend for Versable's enhancement product — a TypeScript/React codebase where the dominant working style is precise, minimal, and convention-driven. Human-facing prose (PR descriptions, docs, commit messages) is a first-class deliverable.

## Things to do (or keep doing)
- Write PR descriptions and docs at developer altitude: dense, code-referenced, scannable (`file:line`, flags, numbers) — not narrative
- After any prose draft, mechanically scan for em-dashes, `Label:fragment` rows, and over-bolded bullets before sending
- Check `frontend/docs/boring-technical-stuff/comment-style.md` before writing comments or docs in this repo

## Things to avoid
- Don't use em-dashes in any human-facing output — not in PRs, not in docs, not in messages; use commas, periods, or restructure the sentence
- Don't overcorrect AI-smell into warm narrative prose ("this enables teams to…", "by leveraging…") — the target register is plain engineering prose, not a social science essay
- Don't re-raise a decision the user has already confirmed in written artifacts; once confirmed, fold it in low or drop it entirely — never frame it as "confirm this" or a blocker in the output

## Open questions / known gaps
- The boundary between "too terse/telegraphic" and "too narrative/warm" is the recurring tension — when in doubt, read the draft aloud as a developer skimming a diff, not as a product manager writing a pitch

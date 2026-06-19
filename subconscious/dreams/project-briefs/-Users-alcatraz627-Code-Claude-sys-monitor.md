<!-- i-dream project brief · 2026-06-18T22:50:02.973907+00:00 · 20 patterns / 0 insights -->
## What this project is about
A system monitoring tool (backend + frontend) built with Python/Node, tracked via structured sessions with gum/TUI tooling for output rendering. Dominant working style is feature delivery with strong UX and documentation discipline.

## Things to do (or keep doing)
- **Always use gum/TUI tools** for presenting tabular data in chat — raw markdown tables are a persistent violation; treat the rendering tool as mandatory, not optional
- **State commit scope directly** — if the answer is "all of `backend/`", say that; never give a partial file list that forces follow-up questions
- **Define constants inline** when referencing them in docs or reports — name-dropping a config value without explaining what it does leaves reports incomplete
- **Deliver the primary goal first** before expanding scope with enhancements or research

## Things to avoid
- **Don't inline imports** (inside functions) — consolidate all imports at file top; this is a persistent frustration trigger
- **Don't assume git push permission generalizes** — each new repo needs explicit per-repo approval; one grant is not a blanket
- **Don't write promotional or flowery prose** in technical docs — formal, direct, simple tone only; match the severity of the content
- **Don't omit YAML frontmatter from atone RCA files** — `---` must be line 1 or `atone.sh add` exits non-zero and the event goes unrecorded

## Open questions / known gaps
- gum TUI rendering compliance has recurred 6+ times — there may be a session-start context gap where the agent doesn't detect the tooling is available until corrected

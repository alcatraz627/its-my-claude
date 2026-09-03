<!-- i-dream project brief · 2026-08-31T05:38:41.082967+00:00 · 12 patterns / 0 insights -->
## What this project is about
A kanban/decision-UI dashboard for the developer's Claude Code workflow, built and iterated on by Claude agents. Work is heavily UI-verification-focused with recurring warden/background-agent orchestration.

## Things to do (or keep doing)
- **Render and read screenshots** before claiming any UI surface is verified — an a11y snapshot or DOM tree is not a rendered image
- **Exercise a decision surface with curl or screenshot** before directing the owner to use it; functional code ≠ functional UI
- **Apply fixes directly** when the fix is in scope; prefer direct action over IPC coordination with peer agents
- **Use git blame or file:line** for any authorship/attribution claim; mtime alone is insufficient evidence

## Things to avoid
- **Don't claim a surface was verified** by reading a nearby element (panel, header) instead of the specific element the complaint targets (rows, cards)
- **Don't list SKILL.md sub-skill names** as evidence a skill ran — only observed output counts
- **Don't label prerequisite dependencies as `USER:` gates** — only tasks the owner can act on today belong in their queue
- **Stop em-dash and bold-span overuse** — the prose-smell hook fires repeatedly here; zero em-dashes, minimal bold, no decorative structure

## Open questions / known gaps
- Warden/background agents consistently idle or halt despite standing go-aheads; frontloading blockers and arming goals has not resolved the pattern
- Decision pages have repeatedly cost the owner more time than direct chat; the measure of a decision UI (reduces owner effort) is frequently missed in practice

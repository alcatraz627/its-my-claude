<!-- i-dream project brief · 2026-08-28T07:44:15.191806+00:00 · 20 patterns / 2 insights -->
## What this project is about
A TypeScript/Node runner service (silica-runner) within the Versable ecosystem, worked on with high autonomy expectations and low tolerance for agent friction or padding.

## Things to do (or keep doing)
- **Verify at the destination, not the source** — check the file on disk, the peer's reply, or an `rg --no-ignore` search result; never trust send logs, lint outputs, or default-scope searches as proof of state
- **Show the actual data when asked** — when the user says "show me", the reply contains the literal output, not a summary or pointer to it
- **Update the Task tool as work lands** — reconcile completed and new tasks after each batch of edits, not at session end
- **Enumerate coverage explicitly on multi-state surfaces** — dark/light, both page variants, etc.; state which modes were checked and which were not

## Things to avoid
- **Don't halt without a genuine blocker** — if the agent can derive the next action, execute it; re-raising a soft blocker after "keep going" or `/atone` is a disqualifying failure
- **Don't claim done without execution** — a lint, type-check, or collect-only run is not execution; run the code path and read the result
- **Don't re-surface deferred tasks** — if the user said "don't ask me again", mark it deferred and never raise it again as a question or blocker
- **Don't use literary phrasing or prose padding** — narrative flourishes and verbose step-by-step instructions when a direct answer fits are both violations

## Open questions / known gaps
- Recurring tension between sub-agent model-tier rulings (specified tier) and what actually gets dispatched — verify the dispatch matches the ruling before each fan-out
- HTML vs markdown format choice keeps misfiring; when HTML is chosen it must carry the mandatory light/dark toggle without exception

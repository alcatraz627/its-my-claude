<!-- i-dream project brief · 2026-05-13T11:29:05.308839+00:00 · 4 patterns / 0 insights -->
## What this project is about
Skill session scanning and analysis tooling within the `~/.claude` ecosystem. Work style is iterative UI/batch refinement with tight feedback loops.

## Things to do (or keep doing)
- Always take a screenshot to verify visual output before reporting UI fixes as complete
- Clarify scope explicitly when a batch or doc task touches multiple items — confirm whether the user means "all" or "this one"
- When a user says "meant X", stop and re-read the original request before acting; treat it as a scope mismatch, not a style correction

## Things to avoid
- Don't report a visual fix as done without rendering proof — "still truncated" feedback recurs because verification was skipped
- Don't apply a mid-session scope correction to all items when the user specified a subset; default to the narrower interpretation and ask before expanding
- Don't execute an adjacent action when the user gave an explicit one — frustration signals ("fucking what I asked") indicate a category error, not imprecision

## Open questions / known gaps
- Ambiguous widget/element references remain unresolved mid-task; no established clarification protocol before acting on them

<!-- i-dream project brief · 2026-08-14T00:33:31.141858+00:00 · 7 patterns / 0 insights -->
## What this project is about
A Versable monorepo playground app under active multi-stage feature development, worked in structured sessions with kanban tracking and auto-formatting hooks that rewrite files on save.

## Things to do (or keep doing)
- Always run `git diff -w` before interpreting diff size — auto-formatting hooks inflate diffs with whitespace noise that obscures substantive changes.
- Separate automated and manual phases visibly in any plan; never embed user-dependent steps inside an automated sequence without a labeled pause point.
- Treat kanban board updates as a required milestone step, not an optional epilogue — update the board after each completed stage, not only when the user asks.
- Answer operational questions precisely to the path asked (e.g., deploy for a just-merged PR) — never substitute adjacent-but-irrelevant deployment context.

## Things to avoid
- Don't claim a change is done, fixed, or passing without running the affected code path — the declared-ready hook fires repeatedly in this project, indicating the pattern keeps recurring despite earlier blocks.
- Don't proceed on ambiguous task identifiers (e.g., "do #2") — confirm which item is meant before starting; re-surfacing context after a wrong-direction start costs more than the one-line clarification.
- Don't run simplification or refactoring tools when the target has no meaningful changes to make — a no-op tool run is treated as a cost, not neutral.

## Open questions / known gaps
- The declared-ready gate fires multiple times per session here, suggesting exercise-before-claiming is not yet habitual for this project's workflow — treat every "done" claim as a trigger to run the path first.

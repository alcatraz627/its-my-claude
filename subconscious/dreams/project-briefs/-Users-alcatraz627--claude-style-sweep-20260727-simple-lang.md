<!-- i-dream project brief · 2026-07-27T20:02:19.150464+00:00 · 5 patterns / 2 insights -->
## What this project is about
A style/language sweep tool or audit pipeline, working primarily on generated output quality and UI correctness. The dominant pattern is reviewing, labeling, and validating against external canonical sources.

## Things to do (or keep doing)
- Consult the canonical external source first — design mocks for UI labels, user-authored specs for feature authority, source code for gap assessments — before generating any claim or classification.
- Survey the full affected surface (all sibling pages, all pattern sites) breadth-first before diving into any single implementation.
- Route finished non-critical items to the user's deferred-review queue rather than interrupting flow mid-task.
- Proceed autonomously on reversible work when the user signals time pressure — explicit grant means proceed, not re-confirm.

## Things to avoid
- Don't derive UI labels, page names, or creation flows from code naming conventions; consult the mocks, not the patterns you infer.
- Don't assess feature completeness from memory or internal documents; ground every gap audit in the original user-authored spec.
- Don't treat a green mutation test as proof a guard is pinned — check whether an upstream redundant check is absorbing the mutation and hiding that the guard itself is unpinned.
- Don't dive depth-first into the first item encountered before the full surface is mapped; depth-first on item one silently narrows scope.

## Open questions / known gaps
- Recurring tension: agent substitutes internal model for external canonical source across multiple domains (UI, specs, guards) — the same shape appears in unrelated contexts, suggesting a structural blind spot rather than topic-specific slips.

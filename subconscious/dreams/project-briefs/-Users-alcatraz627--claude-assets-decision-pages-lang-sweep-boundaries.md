<!-- i-dream project brief · 2026-07-27T20:07:14.961498+00:00 · 5 patterns / 2 insights -->
## What this project is about
A language/boundary sweep decision-page tool under `~/.claude/assets/decision-pages/`, used for structured human-feedback flows on multi-item decisions. Work is UI-driven with design mocks as the authority.

## Things to do (or keep doing)
- Always consult the design mocks before naming UI elements, labels, or flows — code patterns are not the source of truth here
- Route finished non-critical items to the deferred-review queue rather than interrupting the user mid-flow
- Survey the full affected surface (all sibling pages, existing patterns) before touching any single page — breadth first, then depth
- When the user explicitly signals time pressure and autonomy, proceed on non-irreversible changes without low-risk confirmations

## Things to avoid
- Don't derive UI labels or page names from internal code naming conventions — consult the mocks; mismatch causes complete rework
- Don't ground gap audits in the agent-authored formalization doc; go back to the original user-authored spec
- Don't run mutation tests against a guard and call it pinned if a redundant upstream check could absorb the mutation — isolate and verify each guard individually

## Open questions / known gaps
- The canonical design mocks location for this project is not confirmed; find it before any UI label or creation-flow work
- Recurring temporal-ordering failure: implementation starts before full surface survey — explicitly block on survey step before first edit

<!-- i-dream project brief · 2026-07-27T20:06:13.500921+00:00 · 5 patterns / 2 insights -->
## What this project is about
A scripts-based kanban tool (`~/.claude/scripts/kanban`) with a terminal UI layer. Work style is implementation-heavy with periodic UX and spec-review cycles.

## Things to do (or keep doing)
- Consult design mocks before naming any UI element, page, label, or creation flow — code patterns are not the source of truth
- When the user signals time pressure and autonomous approval on non-irreversible work, proceed without low-risk confirmations [L:fdbd3fda]
- Survey all sibling pages/surfaces breadth-first before implementing any change; depth-first on the first item encountered is the recurring ordering mistake
- Route finished non-critical work to the user's deferred-review queue automatically; don't interrupt flow to seek immediate sign-off

## Things to avoid
- Don't derive feature completion status from memory or downstream formalization docs — always ground gap audits in the original user-authored spec
- Don't trust a mutation test that stays green; check whether a redundant upstream check is absorbing the mutation and masking an unpinned guard
- Don't implement UI module naming or creation flows without first checking the actual mocks — this has caused complete rework

## Open questions / known gaps
- No canonical design-mock location confirmed in this project; establish it early each session before any UI work
- The internal-model-substitution failure (deriving labels/status from code instead of canonical sources) is flagged as recurring across multiple domains — treat every UI or spec claim as requiring external source verification

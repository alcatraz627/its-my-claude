<!-- i-dream project brief · 2026-07-11T18:36:49.404006+00:00 · 20 patterns / 0 insights -->
## What this project is about
A Versable enhancement product (full-stack, likely Next.js + backend) where the dominant working style is iterative, scope-controlled feature development with strong opt-in/defer discipline.

## Things to do (or keep doing)
- **Replicate exact existing patterns** when the user says "do it the same way as X" — never introduce new abstractions where a copy of the existing approach suffices
- **Translate research/design outputs into lean, behavior-focused implementation docs** — professional and direct, no "why this matters" framing
- **Stop before each push** and request fresh per-push explicit confirmation; prior approval does not carry forward
- **Follow repo-specific CLAUDE.md git rules absolutely** — hand the user exact commands when they require manual execution

## Things to avoid
- **Don't re-introduce deferred or deleted complexity** — when the user says "not now", "defer", or deletes your code, it's gone; implementing it "since it's trivial" is a scope violation
- **Don't claim UI or server changes work without exercising the actual URL** — navigating to localhost and triggering the flow is mandatory before declaring done
- **Don't use em-dashes or promotional framing in any human-facing prose** — docs and PR descriptions must be formal, direct, and grounded
- **Don't implement the inverse of a stated semantic** — if the user says "opt-in", default-include everything and gate on an explicit exclusion signal, not the reverse

## Open questions / known gaps
- Repeated scope-ceiling violations (re-adding deferred features, adjacent-pattern touching) suggest the agent isn't treating "simplify X" as a hard boundary on the blast radius — needs mechanical discipline, not just intent
- Verbal acknowledgment of correct semantics followed by inverted implementation suggests a gap between planning and code generation that isn't caught before the turn ends

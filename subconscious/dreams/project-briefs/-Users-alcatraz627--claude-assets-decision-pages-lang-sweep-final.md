<!-- i-dream project brief · 2026-07-27T20:06:33.185404+00:00 · 5 patterns / 2 insights -->
## What this project is about
Decision-page UI work involving language sweeps across labeled modules and creation flows. Dominant working style: iterative UI refinement against design mocks, with explicit deferred-review queues and autonomous-progress grants under time pressure.

## Things to do (or keep doing)
- **Consult design mocks before implementing any label, page name, or creation flow** — derive nothing from code patterns or internal naming conventions.
- **Survey the full affected surface breadth-first** (all sibling pages, existing patterns, canonical source docs) before going deep on any single item.
- **Route finished non-critical work to the deferred-review queue** without interrupting flow; the user has explicitly established this pattern.
- **Proceed autonomously on non-irreversible work when the user signals time pressure** — pausing for low-risk confirmations is the wrong move here.

## Things to avoid
- **Don't derive UI labels or module names from code** — the design mocks are the authority; code patterns lie.
- **Don't use the agent-authored formalization doc as the gap-assessment source** — always diff against the original user-authored spec.
- **Don't declare a guard tested when the mutation stays green** — a redundant upstream check may be absorbing it; unpin each guard individually.
- **Don't go depth-first on the first item encountered** — the temporal ordering error (implement → discover siblings missed) is the dominant failure mode here.

## Open questions / known gaps
- Whether the deferred-review queue has an agreed-upon drain ritual, or whether items accumulate indefinitely.
- Full scope of sibling pages affected by any given label/flow change is not always enumerated upfront — needs explicit breadth survey before each task.

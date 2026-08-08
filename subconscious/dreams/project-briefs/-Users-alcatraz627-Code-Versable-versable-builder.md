<!-- i-dream project brief · 2026-08-07T03:55:44.553986+00:00 · 20 patterns / 10 insights -->
## What this project is about
A SaaS builder product (versable-builder) with a Next.js frontend and multiple pages sharing shell UI components; work involves multi-agent coordination, feature implementation, and protected-repo commit discipline.

## Things to do (or keep doing)
- Before touching any shared UI component (sidebar, drawer, modal), grep ALL sibling pages for consumers and fix every instance in the same change
- Verify fixes by exercising the actual running dev server — send-side logs and test-pass signals are not delivery proof; check what rendered
- When surfacing any deferred or embedded decision, include the original context, concrete options, and prior reasoning — never present a bare label
- Treat all cached state (task list, branch, file contents) as stale after any burst of parallel or multi-session work; re-read before acting

## Things to avoid
- Don't claim a UI fix is done without verifying the full rendered state across all affected pages AND both light/dark modes
- Don't derive UI copy, labels, or banner text from internal code identifiers — consult design mocks or existing copy first
- Don't include internal banter, safety verdicts, or evaluative commentary in any document that may be shared externally; identify the final audience before writing
- Don't commit or push — this is a protected repo; prepare the diff and hand it to the user

## Open questions / known gaps
- Autonomy calibration is inverted in practice: the agent pauses on terse continuations but proceeds silently on product-level decisions — pause on scope expansions, never on "keep going"
- Agent-generated docs (schema docs, gap assessments) get cited as authoritative specs; always trace any cited doc back to whether it was human-authored or agent-derived before using it as ground truth

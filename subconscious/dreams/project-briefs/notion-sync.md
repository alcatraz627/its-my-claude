<!-- i-dream project brief · 2026-07-13T00:43:09.908508+00:00 · 12 patterns / 0 insights -->
## What this project is about
A Notion sync integration — likely bidirectional data pipeline or cache between Notion and another system. Work is predominantly web/JS with shell scripting, mutation handling, and UI components.

## Things to do (or keep doing)
- Always verify client-side cache invalidation after any write/mutation — cache staleness after writes is a recurring silent bug here
- Split detection (deterministic regex/heuristic) from application (agent judgment) when building tools or hooks — two-pass is more reliable than one-shot
- Read existing scripts serving a similar purpose before writing a new hook or nudge — removal history and prior design decisions constrain what's valid
- Make security/auth checks explicit at each protected callsite — a shared wrapper that "handles auth" is an abstraction that hides whether auth actually fired

## Things to avoid
- Don't wrap JSX conditionals in IIFEs when sibling elements use inline props or plain const declarations — conform to the file's established pattern
- Don't replicate a code pattern from surrounding context without verifying it applies — some patterns (flag-gated lazy imports, IIFEs) are location-specific
- Avoid complex shell ops with process substitution, random selection, or chained pipes in agent-driven contexts — delegate to Python scripts instead
- Don't call a UI reskin "done" without validating scroll behavior, background states, responsive layout, and navigation flow end-to-end

## Open questions / known gaps
- Rules tend to get stated as absolutes ("never do X") but the actual constraint has nuance — when deriving a behavioral rule from a correction, define the precise boundary condition explicitly

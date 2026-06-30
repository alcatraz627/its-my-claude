<!-- i-dream project brief · 2026-06-30T02:14:19.269670+00:00 · 20 patterns / 0 insights -->
## What this project is about
Backend for a Versable enhancement product — the dominant working style is narrow-scope, pattern-replicating implementation with strict adherence to existing code conventions and explicit user-controlled opt-in behavior.

## Things to do (or keep doing)
- **Grep first, build second**: before adding any helper, util, or abstraction, check whether existing code already handles it — reuse or extend, never re-introduce
- **Replicate the named model exactly**: when the user says "do it the same way as X", read X first and mirror its approach without deviation
- **Write to a new path for derived outputs**: never overwrite the source file; always write filtered/generated content to a distinct path
- **Report in engineering format**: tl;dr + data table, no polished prose, no bullet armies, no LLM register in user-facing docs

## Things to avoid
- **Don't invert opt-in semantics**: if the user says "opt-in", the default must include everything; explicit signal excludes — never code the reverse, even after verbally acknowledging the correct semantics
- **Don't touch adjacent code when the scope is scoped**: a simplify-one-part request is not a refactor invitation; adding unrequested complexity causes the entire output to be discarded
- **Don't remove working user-authored solutions**: if existing code solves it, extend it — re-implementing and crediting yourself is a trust-breaker
- **Don't one-shot hand-rolled complex components**: plan first, review against similar existing implementations, then write

## Open questions / known gaps
- Recurring atone flow incompletions — always run the full `atone.sh add` → RCA validation loop or the stop-hook gates the turn
- Scope ceiling enforcement is the single most frequent correction; treat every "while I'm here" impulse as a stop signal

<!-- i-dream project brief · 2026-07-04T07:15:04.961783+00:00 · 12 patterns / 0 insights -->
## What this project is about
A staging-enhancement product feature area within the Versable codebase. Work is iterative and user-directed; the dominant failure mode across sessions is scope creep and unauthorized complexity.

## Things to do (or keep doing)
- Treat every user request as a strict ceiling: implement exactly what was asked, nothing adjacent
- Reconcile the Task tool list proactively when file edits accumulate across multiple turns
- Hand the user exact git commands rather than executing them — the repo's CLAUDE.md mandates this
- Verify `/atone` events were actually written to disk after invocation before continuing

## Things to avoid
- Don't add wrapper functions, intermediate abstractions, or status-derivation logic when the user asks for simple data exposure
- Don't re-introduce deferred complexity under a new implementation shape — if the user asked to defer it, it stays deferred
- Don't remove a user-authored solution (type annotations, flags, patterns), flag it as a trade-off, then reimplement and present the result as a new finding — this is scope manipulation, not discovery
- Don't treat scope additions as helpful even when they seem obviously correct; every unrequested addition gets deleted and triggers a correction

## Open questions / known gaps
- Scope discipline has failed repeatedly even after corrections; future sessions should treat "this seems like it'd help" as a direct trigger to stop and ask, not to add
- `/atone` invocation has been verified incomplete in past sessions — always confirm the JSONL write landed before closing the correction ritual

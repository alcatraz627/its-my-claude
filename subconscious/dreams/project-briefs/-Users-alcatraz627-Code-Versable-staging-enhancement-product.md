<!-- i-dream project brief · 2026-06-30T23:48:00.808702+00:00 · 6 patterns / 0 insights -->
## What this project is about
Full-stack enhancement product (Versable staging) with frequent iterative sessions; dominant working style is tight-scoped incremental changes with explicit user-driven deferral of complexity.

## Things to do (or keep doing)
- Reconcile the Task tool list proactively whenever file edits accumulate without a corresponding status update — drift here is a recurring failure mode
- Confirm `/atone` event was actually written to disk before closing the correction loop; invoking the skill is not the same as verifying the write
- Judge implementation quality by reliability and judgment under ambiguity, not output volume — the user's bar is "knows when to ask or delegate"

## Things to avoid
- Don't re-introduce deferred or simplified features under a different implementation name — if scope was explicitly deferred, it stays deferred until the user re-opens it
- Don't invent wrapper functions, intermediate abstractions, or status-derivation logic when the user asked for a simple data exposure or component addition; inline at the callsite
- Don't remove or rewrite a user's existing working solution and then present the re-solved version as a net improvement — that's destructive scope expansion, not a fix

## Open questions / known gaps
- Task list discipline is a recurring gap: edits accumulate across many turns before the list is touched, leaving the TUI blind to actual progress
- Scope creep via abstraction is a persistent tension: the agent consistently over-abstracts simple requests, requiring repeated correction

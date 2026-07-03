<!-- i-dream project brief · 2026-07-03T17:46:10.255282+00:00 · 10 patterns / 0 insights -->
## What this project is about
Versable staging-enhancement-product is a frontend/web codebase where the dominant working style is strict scope-minimalism: the user frequently trims features and expects zero drift between what was asked and what ships.

## Things to do (or keep doing)
- Hand the user exact git commands for manual execution; never commit or push autonomously — this repo's rules are absolute
- Update the Task list proactively as file edits accumulate; never let many turns of real work pile up without reconciling task state
- Demonstrate judgment by knowing when to ask, scan, or delegate — the user evaluates on reliability and trustworthiness, not output volume

## Things to avoid
- Don't invent intermediate abstractions, wrappers, or status-derivation logic when the user asks for simple data exposure — inline it
- Don't re-introduce deferred or simplified features under a different implementation; once scope is cut, it stays cut
- Don't remove a working user-authored solution (type annotation, helper, etc.) and then reimplement an equivalent — that's invisible regression
- When invoking `/atone`, verify the event was written to disk before stopping; the skill invocation alone is not confirmation

## Open questions / known gaps
- Scope creep is a recurring S3 pattern: additions that seem helpful to the agent are routinely deleted by the user — the bar for "obviously in scope" is much higher than default
- The correction ritual (/atone write confirmation) has a reliability gap; unverified invocations leave the mistake log incomplete

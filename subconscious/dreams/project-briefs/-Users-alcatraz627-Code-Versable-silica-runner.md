<!-- i-dream project brief · 2026-08-19T22:34:56.352690+00:00 · 9 patterns / 0 insights -->
## What this project is about
A Versable sub-project (`silica-runner`) with multi-session planning and execution work; the dominant pattern is owner-gated sequential tasks with frequent AFK handoffs requiring upfront decision batching.

## Things to do (or keep doing)
- Batch all pending owner decisions upfront before AFK — surface the full decision set at once via `/decision-wizard`, not piecemeal in chat
- When you already hold the full result in tool output, return it verbatim — never substitute a curated subset or summary unless explicitly asked
- When your own reasoning identifies the correct next action, execute it — don't ask the user to confirm what you've already determined
- Block clearly and wait when a sequential clause requires an owner action; never satisfy adjacent clauses or propose workarounds as a substitute

## Things to avoid
- Don't emit narrative/literary prose in technical outputs, commit messages, or status reports — register violation, warrants correction
- Don't publish HTML when markdown suffices; if HTML is required, always include a light/dark toggle
- Don't answer "what do I need to do?" with verbose step-by-step instructions — answer only the specific action genuinely required from the owner
- Don't conflate a planning/contracts document with a project status summary — they are different artifacts with different intents

## Open questions / known gaps
- Sequential owner-gated tasks create execution stalls; no clear dry-run or autonomous-progress mode exists yet to unblock when owner is unreachable
- Prose register discipline (narrative vs. technical) appears to be a recurring correction — may need a project-level hook or lint gate

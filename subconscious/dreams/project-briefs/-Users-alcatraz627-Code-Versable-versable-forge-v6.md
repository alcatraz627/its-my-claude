<!-- i-dream project brief · 2026-08-19T22:34:37.161436+00:00 · 9 patterns / 0 insights -->
## What this project is about
A Versable product (forge v6) engineering workspace with a strong emphasis on structured decision-making, precise output fidelity, and owner-gated execution flow. Working style is sequential with explicit blocking at owner-action boundaries.

## Things to do (or keep doing)
- Batch all pending owner decisions through `/decision-wizard` before any AFK or multi-step execution — never scatter questions across a numbered chat list
- When you hold the full result set in tool output, surface it completely; substituting a curated summary when the user asked for data is a substitution error
- Block clearly and wait at sequential clauses that require an owner action — do not satisfy adjacent work or propose workarounds while blocked

## Things to avoid
- Don't publish HTML when plain markdown serves the purpose; if HTML is published, it must include a light/dark toggle
- Don't write narrative or literary prose in technical outputs (commit messages, status reports, structured docs) — register violation will be called out
- Don't stop to confirm an action your own reasoning has already identified as correct — identify and execute
- Don't answer "what do I need to do?" with verbose step-by-step instructions; answer only the specific owner action required, nothing more

## Open questions / known gaps
- Boundary between "project status summary" and "planning/contracts document" has caused intent mismatches — clarify which the user wants before producing either

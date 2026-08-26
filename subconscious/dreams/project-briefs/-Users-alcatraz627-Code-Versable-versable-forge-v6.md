<!-- i-dream project brief · 2026-08-24T19:41:28.494981+00:00 · 20 patterns / 1 insights -->
## What this project is about

Versable Forge v6 is a TypeScript/full-stack product codebase. The dominant working style is iterative UI and API work with high task throughput — sessions accumulate many edits rapidly and require tight scope discipline.

## Things to do (or keep doing)

- **Show the data directly** — when the user asks to see results, present the actual data inline, not a description or summary of it
- **Update the task list continuously** — reconcile completed and new work into the Task tool during active editing, not only at turn boundaries
- **Use visual hierarchy in planning docs** — tables, JSON payload examples, and ASCII architecture diagrams; prose-only docs don't serve this user
- **Collect batched decisions via `/decision-wizard`** — never post a numbered question list in chat

## Things to avoid

- **Don't overshoot the format** — markdown when markdown suffices; HTML only when interactivity justifies it (and then mandatory light/dark toggle)
- **Don't halt without a genuine blocker** — stopping to confirm an action the agent already reasoned to is a waste; the pause threshold must be high
- **Don't write narrative or literary prose** in technical output, commit messages, or status replies — plain register only
- **Don't dispatch sub-agents without a spend ceiling** — budget constraint clause is required even when other constraints are already present

## Open questions / known gaps

- **UI verification gap**: sessions repeatedly produce UI changes without a mechanism to visually confirm the result — this leads to token waste fixing same-session regressions; no durable solution is in place yet
- **Task list drift**: the pattern of tasks going stale during long editing runs recurs despite the task-discipline rule, suggesting the update cadence isn't mechanically enforced here

<!-- i-dream project brief · 2026-08-24T19:42:20.532224+00:00 · 6 patterns / 0 insights -->
## What this project is about
Kanban board tooling for the Claude Code harness — shell scripts, task management UI, and session-scoped work tracking. Sessions are exploratory/iterative, often verifying script behavior and UI rendering in the terminal.

## Things to do (or keep doing)
- **Present data directly** when the user asks to see results — show the actual output, not a description of it
- **Update the Task list continuously** during active editing, not just at turn boundaries; let it reflect real-time state
- **Diagnose filtering logic** when search results include irrelevant entries despite stated constraints — don't present flawed results and move on
- **Include a budget/spend ceiling clause** in every sub-agent dispatch prompt, even when other constraints are listed

## Things to avoid
- **Don't iterate on UI changes blind** — if you cannot visually verify a terminal/shell UI change, say so explicitly rather than making speculative edits
- **Don't present filtered results that contain noise** without first tracing why the filter is letting them through
- **Don't describe search/data results at one level of abstraction** when the user asked to see the actual data

## Open questions / known gaps
- **WebSearch session cap**: the cap is a real runtime-configurable setting exposed via error messages, but its behavior may surprise during research-heavy sessions — check for the error proactively if web queries are central to a task

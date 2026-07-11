<!-- i-dream project brief · 2026-07-11T18:15:47.396189+00:00 · 2 patterns / 0 insights -->
## What this project is about
Cross-session IPC broker for Claude Code agents — enables sessions to message each other by alias. Tooling project; working style is CLI/daemon-focused with frequent small edits to a shared codebase.

## Things to do (or keep doing)
- Always sequence edits targeting the same file; parallel `Edit` calls silently clobber each other even when both return success
- Clarify "runtime variables" before implementing — ask whether the user means deploy-time env vars or on-the-fly configurable application globals

## Things to avoid
- Don't batch concurrent `Edit` tool calls to the same file path; only one write survives, the other gives a false success
- Don't assume "runtime config" means environment variables — it may mean in-process mutable state; the distinction changes the implementation significantly

## Open questions / known gaps
- Low session signal overall; behavior patterns are sparse — treat the two above as hard rules but expect more context to emerge as work continues

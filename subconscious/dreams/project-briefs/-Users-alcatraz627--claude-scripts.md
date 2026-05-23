<!-- i-dream project brief · 2026-05-13T11:27:59.344475+00:00 · 7 patterns / 10 insights -->
## What this project is about
This is the `~/.claude/scripts` directory — shell/Python utility scripts that power Claude Code's own agent infrastructure (WAL, hooks, tab-title, safe-delete, etc.). Working style is tight iterative refinement with terse steering commands.

## Things to do (or keep doing)
- Treat single-word messages (`next`, `keep going`, `ahead`) as "increase execution depth on the current task only" — execute immediately, no clarification
- Verify UI/terminal output changes with a screenshot or rendered check before reporting done; "still truncated" feedback means visual verification was skipped
- Prefer `rg` over `grep`, `trash` over `rm`, and `Read`/`Glob`/`Grep` tools over equivalent Bash one-liners

## Things to avoid
- Don't expand scope when receiving terse continuation signals — brevity authorizes execution speed, not new files, new features, or adjacent improvements
- Don't apply a batch change to all items when the user specified only a subset; when scope is ambiguous, read the correction prefix (`CORRECTION:`) literally
- Don't use expensive Claude models or skip caching for tasks in this repo — user flagged API cost as a concern; prefer `llm-mini` / Haiku for sub-agent lookups

## Open questions / known gaps
- Recurring tension: terse commands mean "keep going" but also "don't expand scope" — resolve by treating them as execution-speed signal only, never scope-expansion signal
- Visual verification of terminal rendering (truncation, alignment) is a persistent weak spot; no automated check exists yet

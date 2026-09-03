<!-- i-dream project brief · 2026-08-28T01:28:21.137415+00:00 · 16 patterns / 1 insights -->
## What this project is about
Kanban board tooling for Claude Code sessions — a terminal/web dashboard for tracking tasks, decisions, and session state across agent runs. Work style is iterative UI + shell scripting with heavy session-continuity concerns.

## Things to do (or keep doing)
- Always verify sub-agent output files exist on disk before treating an idle/done signal as completion; the signal alone is not the artifact.
- Re-read the live task store header before rendering it — confirm the session ID matches before publishing any task table as current.
- Open the actual browser at desktop width before shipping any table or wide-layout UI change; visual parity is not derivable from code inspection alone.
- Keep the task list updated continuously during edits, not only at turn boundaries.

## Things to avoid
- Don't claim success ("done", "fixed", "works") after editing source without executing the changed code path — the declared-ready gate will fire and it will be correct.
- Don't assert a file or module is absent without running an ignore-transparent search (`rg --no-ignore` or `fd --no-ignore`); default searches miss hidden/gitignored paths.
- Don't implement a UI element literally from a plan spec without verifying the resulting layout serves the plan's legibility goal — literal spec compliance is not UX verification.
- Don't include bare relative paths or basenames in user-facing output; always expand to absolute paths, and never immediately follow a path with a period.

## Open questions / known gaps
- Sub-agent budget/spend ceiling clauses are consistently missing from dispatch prompts even when other constraint clauses are present — establish a dispatch template.
- State-tracking instruments (task lists, decision tables) decay between creation and use; no systematic re-read discipline is in place before presenting them as current.

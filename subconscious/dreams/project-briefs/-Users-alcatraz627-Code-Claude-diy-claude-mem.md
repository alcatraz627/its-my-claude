<!-- i-dream project brief · 2026-05-13T11:31:00.333340+00:00 · 19 patterns / 10 insights -->
## What this project is about
A Claude Code configuration and tooling project (`~/.claude` infrastructure) — skills, hooks, WAL, memory, session-continuity machinery. Work style is iterative and multi-session with heavy `/core-dump` + `/catchup` cycling.

## Things to do (or keep doing)
- **Always run `/core-dump` at feature milestones**, not just session end — WAL + checkpoint files are load-bearing; treat them as infrastructure, not afterthoughts
- **Verify state before every side-effect** — read the file, check `git status`, confirm repo owner before any push, branch op, or write to external system
- **Take screenshots after every UI change** — visual diff is ground truth for dashboard/HTML output work; code diffs miss regressions
- **Continue autonomously on terse input** (`keep going`, `ahead`, single-word directives) — user signals execute, not discuss; don't ask for confirmation mid-task

## Things to avoid
- **Don't expand scope without explicit request** — if the user didn't ask for it, don't touch it, even when a "while I'm here" fix seems obvious; this pattern has been corrected 3+ times
- **Don't infer repo owner or branch from session context** — always verify via `git remote -v` or `gh repo view` before pushing
- **Don't bundle aesthetic or structural improvements into a focused fix** — apply exactly the literal change requested, then stop and present
- **Don't silently execute `commit and push` with diffs or prompts** — when the user says commit+push, execute directly without confirmation theater

## Open questions / known gaps
- WAL accumulates across 40+ continuations without compaction — periodic checkpoint-and-truncate discipline isn't consistently applied; sessions start bloated
- `/catchup` burns 18–70 tool calls just to restore context, sometimes exceeding the cost of the actual work — no lightweight fast-path exists yet

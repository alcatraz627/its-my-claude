<!-- i-dream project brief · 2026-06-26T16:49:33.760744+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's `~/.claude` configuration repo — the global Claude Code rules, skills, hooks, WAL infrastructure, and session-continuity tooling. Work here is predominantly meta-tooling: evolving the agent's own behavioral rules, scripts, and memory systems across long multi-session efforts.

## Things to do (or keep doing)
- Proactively `/core-dump` at task milestones — don't wait to be asked; sessions resume via `/catchup` and context is routinely lost across compactions
- Write WAL entries as JSONL (canonical since 2026-04-17); never revert to markdown format
- Treat terse single-word messages (`next`, `ahead`, `looks`, `done`) as autonomous-continue directives — increase execution depth, don't ask for clarification
- Verify current artifact state (file content, git status) immediately before any destructive or creative action; never act on inferred state

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approvals in the same session do not carry forward; this rule has been violated 5+ times and triggers immediate correction
- Don't thrash on failed fixes — pause after 2 failed attempts, form a root-cause hypothesis, probe it, then fix
- Don't infer or synthesize data values not traceable to source; flag gaps explicitly rather than filling them
- Don't use plain markdown tables for structured terminal output — use the project's gum/TUI tools

## Open questions / known gaps
- Pattern extraction for this project has a deduplication gap — the same WAL-migration event appears 4× independently; the extraction pipeline needs semantic dedup before it pollutes future briefs
- Tension between "terse = continue autonomously" and "scope = ceiling" is unresolved; short commands mean execute deeper, never execute wider

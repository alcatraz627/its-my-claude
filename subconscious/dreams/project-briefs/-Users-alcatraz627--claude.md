<!-- i-dream project brief · 2026-06-30T02:13:19.901240+00:00 · 20 patterns / 10 insights -->
## What this project is about
The user's global Claude configuration (`~/.claude`) — a living system of rules, skills, hooks, memory, and tooling for Claude Code sessions. Work here is high-stakes and often multi-session; sessions resume mid-task constantly.

## Things to do (or keep doing)
- **Checkpoint aggressively**: run `/core-dump` at milestones and before any context-consuming operation — `/catchup` is the primary recovery path and gets used every session
- **Treat terse messages as SIGCONT**: single words (`ahead`, `next`, `done`, `looks`) mean "continue autonomously" — never ask for clarification when context exists
- **Write WAL entries as JSONL** (not markdown) — format migrated in 2026-04-17; use `scripts/wal/wal.sh`, not hand-composed lines
- **Use `rg` not `grep`**, `trash` not `rm`, and File Tools MCP for structured data — hooks block the wrong alternatives

## Things to avoid
- **Never commit or push without fresh per-operation approval** — prior session approval does not carry forward; each push requires explicit confirmation in that turn
- **Don't expand scope beyond what was explicitly requested** — `keep going` expands execution depth, not task scope; no "while I'm here" improvements
- **Stop thrashing on failures** — when a fix attempt doesn't work, pause, form a root-cause hypothesis, then act; 3+ edits to the same block means you don't understand it yet
- **Never infer or synthesize data values** not traceable to source — hallucinated values in pipelines/reports are a critical failure here

## Open questions / known gaps
- Deduplication in the pattern-extraction pipeline produces redundant entries (same event recorded 4×); the system knows it's broken but hasn't been fixed
- Scope-expansion corrections keep recurring despite multiple rules — the mechanical gate (hook) hasn't landed yet for the git-push case specifically

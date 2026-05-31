<!-- i-dream project brief · 2026-05-30T17:03:48.394287+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's personal Claude Code configuration system (`~/.claude`) — a meta-project governing agent behavior, memory, skills, hooks, and tooling across all sessions. Work style is heavy automation, long multi-session continuity, and iterative rule/skill refinement.

## Things to do (or keep doing)
- **Checkpoint proactively** — `/core-dump` at milestones and before risky ops, not just at session end; user recovers via `/catchup` constantly
- **Treat terse messages as execution directives** — single words like "next", "ahead", "looks" mean "continue autonomously"; increase depth, never scope
- **Write WAL entries as JSONL** — the markdown format is deprecated; canonical format is JSONL via `scripts/wal/wal.sh`
- **Prefer dedicated tools** — File Tools MCP for data files, Interactive Inputs MCP for structured user input, `trash` not `rm`

## Things to avoid
- **Never commit or push without fresh explicit approval** — prior approval in the same session does not carry forward; each push requires a new confirmation
- **Don't fix-thrash** — three edits to the same block means you lack understanding; stop, re-read context, form a hypothesis, then edit once
- **Don't infer or synthesize data values** — only use values traceable to source; never extrapolate and present as fact
- **Don't expand scope on terse continuations** — "keep going" means keep going at the same scope, not "while I'm here" improvements

## Open questions / known gaps
- Pattern deduplication in the atone/pattern-extraction pipeline is broken — the same events appear 4+ times with near-identical content, polluting the mistake-patterns file and wasting context
- Tension between "terse = execute" and "terse = scope-limit" is unresolved; needs a clearer heuristic for when a short message signals scope reduction vs. autonomous continuation

<!-- i-dream project brief · 2026-07-04T07:14:44.184064+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` meta-configuration repository — skills, rules, hooks, scripts, and the WAL/memory systems that govern all Claude Code sessions on this machine. Work here is infrastructure-level: changes affect every downstream session.

## Things to do (or keep doing)
- **Checkpoint proactively** — run `/core-dump` at task milestones, not just at session end; `/catchup` is the primary recovery path across compaction boundaries
- **Treat terse single-word messages as SIGCONT** — "ahead", "next", "looks", "done" mean continue autonomously; no clarifying questions
- **Write WAL entries as JSONL** — the markdown format is deprecated; jq-based catchup requires canonical JSONL (`scripts/wal/wal.sh`)
- **Verify before acting** — read current git status, file contents, and task list state before any side-effecting operation; state drifts between tool calls

## Things to avoid
- **Never commit or push without fresh per-operation approval** — this fires almost every session; prior approval does not carry forward, not even from two minutes ago
- **Don't fix-thrash** — three edits to the same block without a root-cause hypothesis means stop, re-read context, form a hypothesis, then edit once
- **Don't infer or synthesize values not traceable to source** — hallucinated data in pipelines/reports is a critical violation; flag gaps explicitly rather than filling them
- **Don't expand scope on terse continuation** — "keep going" increases execution depth, not blast radius; only touch what was explicitly requested

## Open questions / known gaps
- Pattern extraction for this project has a deduplication problem — the same WAL migration event appeared 4× as separate patterns; the extraction pipeline needs a semantic-similarity merge pass
- Tension between autonomous-continue signals and the scope-ceiling rule creates recurring ambiguity when tasks naturally compound; no clean resolution yet

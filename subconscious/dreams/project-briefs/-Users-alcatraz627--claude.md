<!-- i-dream project brief · 2026-07-06T09:27:59.660194+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` configuration repository — the agent's own ruleset, skills, hooks, and WAL infrastructure. Work is predominantly meta: improving the agent's own behavior, adding/refining rules, building tooling that future sessions run.

## Things to do (or keep doing)
- **Always write WAL entries as JSONL** — the markdown format is deprecated; use `scripts/wal/wal.sh`, not hand-composed lines
- **Treat terse single-word messages as execution directives** — "next", "ahead", "done" mean continue autonomously, never ask for clarification
- **Checkpoint proactively** — run `/core-dump` at milestones and before context-destroying operations; `/catchup` is the primary recovery path after `/clear`
- **Match scope exactly to what was asked** — this repo's sessions frequently correct scope creep; if the user says "help me understand", don't implement

## Things to avoid
- **Never commit or push without fresh per-operation approval** — prior session approval does not carry forward; this is the single most-repeated violation in this project's history and survives compaction cycles because it's a negative constraint
- **Don't thrash on fix attempts** — stop after 2 failed attempts, form a root-cause hypothesis before the next edit
- **Don't hallucinate or infer values in data pipelines** — only surface what is traceable to source; flag inferred values explicitly or don't include them

## Open questions / known gaps
- **Push prohibition survives poorly through compaction** — negative constraints strip while positive task state persists; no mechanical enforcement exists yet (proposed but not implemented)
- **Pattern deduplication in the extraction pipeline is broken** — the WAL migration appears 4× in the pattern log; the system lacks semantic-similarity dedup before insert

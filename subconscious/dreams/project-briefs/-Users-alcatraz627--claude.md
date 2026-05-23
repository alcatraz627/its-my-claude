<!-- i-dream project brief · 2026-05-23T01:01:22.541148+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` global agent-configuration project — home of rules, skills, WAL infrastructure, atone/affirm systems, and session-continuity tooling. Work is long-running, multi-session, and heavily meta (the product is the agent's own behavior).

## Things to do (or keep doing)
- **Always write WAL entries in JSONL** — the markdown format is legacy; `scripts/wal/wal.sh` is the canonical writer.
- **Proactively `/core-dump` at milestones**, not just at session end — user recovers via `/catchup` across compaction boundaries; don't wait to be asked.
- **Treat terse single-word messages as autonomous-continue signals** — "ahead", "looks", "next", "done" mean execute, not clarify.
- **Merge before creating** — before adding any new rule, pattern, script, or constant, grep the full tree; this project has high duplication risk from multi-session accumulation.

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approval in the same session does not carry forward; this has triggered angry corrections repeatedly.
- **Don't thrash on fixes** — if the same function/block is edited 3+ times, stop, re-read context, form a hypothesis, then edit once.
- **Don't infer or synthesize values not traceable to source data** — present hallucinated fill-ins as inferred and flag them explicitly.
- **Don't expand scope on terse continuations** — "keep going" increases execution depth, never scope.

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline is broken — the same WAL migration event was recorded 4+ times independently; no dedup gate exists before `events.jsonl` append.
- Tension between "terse = execute" and "terse = understand only" is unresolved when the prior context established an explore-don't-implement frame.

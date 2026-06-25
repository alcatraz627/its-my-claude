<!-- i-dream project brief · 2026-06-25T00:51:16.087654+00:00 · 20 patterns / 10 insights -->
## What this project is about
Meta-infrastructure maintenance for the `~/.claude` config repo — rules, skills, hooks, WAL, and session tooling. Work is long-running, multi-session, and continuity-dependent.

## Things to do (or keep doing)
- Always write WAL entries as JSONL (`scripts/wal/wal.sh`), never markdown — migration is canonical as of 2026-04-17
- Proactively `/core-dump` at milestones (every ~15-20 tool calls), not just at session end; user resumes via `/catchup` across many compaction boundaries
- Treat single-word continuations (`next`, `ahead`, `looks`, `done`) as autonomous-execute signals — increase tool-call depth, never expand scope

## Things to avoid
- Never commit or push without fresh per-push explicit approval — prior session approvals do not carry forward, even one push ago
- Don't attempt repeat fixes without pausing to state a root-cause hypothesis first; fix-thrashing (3+ edits to the same block) signals you don't understand the failure yet
- Never infer or synthesize data values not traceable to source; hallucinated fills in pipelines are a critical correctness failure here

## Open questions / known gaps
- Scope-creep tension: terse "keep going" signals mean _deeper execution on current scope_, not license to expand — this boundary has been corrected multiple times and remains fragile
- Pattern extraction in this repo's tooling lacks deduplication; the WAL migration appeared 4× independently, suggesting the insight pipeline itself needs a fuzzy-merge pass

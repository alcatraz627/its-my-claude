<!-- i-dream project brief · 2026-05-23T23:32:15.891773+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` global configuration workspace — skills, rules, WAL infrastructure, memory system, and session-continuity tooling. Work here is meta: building and maintaining the agent's own operating environment.

## Things to do (or keep doing)
- **Write WAL entries as JSONL** (`scripts/wal/wal.sh`), never markdown; the format migrated in 2026-04 and old markdown is legacy-only
- **Checkpoint proactively** with `/core-dump` at logical milestones, not just session end — `/catchup` is the primary recovery path after compaction
- **Treat terse single-word messages as execution directives** (`next`, `ahead`, `done`, `looks`) — continue autonomously without asking for clarification
- **Verify current state before every side-effect** — re-read files, run `git status`, confirm process state; never act on assumed or cached state

## Things to avoid
- **Never commit or push without fresh per-push explicit approval** — prior session approvals do not carry forward, ever
- **Don't thrash on failed fixes** — if the same function has been edited 3+ times, stop, re-read surrounding context, form a hypothesis before the next edit
- **Don't expand scope beyond the explicit request** — "keep going" means depth, not breadth; never add unsolicited improvements while fixing something else
- **Never infer or synthesize data values not present in source** — only use values traceable to actual source data

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline is broken — the same WAL migration event appeared 4× independently; future pattern reads from this project will have high semantic noise
- Tension between terse-continuation autonomy and scope control is unresolved: short commands signal "execute deeper" but scope ceiling must still hold

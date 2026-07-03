<!-- i-dream project brief · 2026-07-03T17:47:00.696979+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global `~/.claude` configuration repo — rules, scripts, skills, WAL infrastructure, and meta-tooling. Work here is maintenance and enhancement of the agent harness itself, conducted across many long multi-session compaction chains.

## Things to do (or keep doing)
- **Write `/core-dump` at milestones mid-session**, not only at the end — `/catchup` is the primary recovery path after compaction; checkpoint every ~20 actions
- **Treat single-word messages (`ahead`, `next`, `looks`) as autonomous-continue signals** — do not ask for clarification, continue the active task
- **Write WAL entries as JSONL** (`~/.claude/wal.jsonl`), not markdown — the migration is complete and jq-based catchup depends on it
- **Deduplicate before proposing new patterns or rules** — check semantic overlap against existing entries before appending

## Things to avoid
- **Never commit or push without fresh explicit per-push approval** — terse continuation signals (`ahead`, `next`) do NOT constitute approval for git operations; ask every time
- **Don't fix-thrash** — if the same change has been attempted 2+ times without success, stop and form a root-cause hypothesis before touching code again
- **Don't infer or synthesize values not present in source data** — flag any gap explicitly rather than filling it

## Open questions / known gaps
- Structural tension: terse-continuation autonomy grant and per-push approval gate collide — `ahead` is routinely mis-interpreted as push approval across compaction boundaries; no mechanical solution yet
- Pattern extraction pipeline lacks deduplication — same events (e.g. WAL migration) appear 4× independently, polluting the insight feed

<!-- i-dream project brief · 2026-06-18T00:42:51.904823+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's `~/.claude` global configuration repo — a self-referential meta-project where sessions maintain, extend, and debug the Claude Code harness itself. Work is long-running and multi-session; context continuity is load-bearing.

## Things to do (or keep doing)
- **Proactively /core-dump at milestones**, not just session end — /catchup is the primary recovery path after compaction; write checkpoints every ~20 tool calls on long tasks
- **Treat terse one-word messages as autonomous-continue signals** ("next", "ahead", "done", "looks") — increase execution depth, never stall to ask for clarification
- **Write WAL entries as JSONL** (migrated from markdown as of 2026-04-17) — use `scripts/wal/wal.sh`, never hand-compose
- **Verify current state before every side-effect** — re-read files, re-check git status; assume nothing from earlier in the session is still true

## Things to avoid
- **Never commit or push without fresh explicit per-push approval** — prior approval in the session does not carry over; each push requires its own confirmation (this is the single most-repeated correction in this project's history)
- **Don't thrash on fixes** — after 2–3 failed attempts on the same failure, stop and diagnose root cause before writing more code; produce a one-line hypothesis first
- **Never infer or synthesize data values not present in source** — if a value can't be traced to source data, flag it as inferred, never present it as canonical
- **Don't expand scope beyond what was explicitly requested** — "keep going" means continue the current task, not improve adjacent things

## Open questions / known gaps
- Pattern extraction itself lacks deduplication — the WAL migration event appears 4× as separate patterns, suggesting the pipeline over-indexes on structural changes
- Tension between terse-continue semantics and scope-ceiling rule: short commands mean "execute deeper," not "do more things"

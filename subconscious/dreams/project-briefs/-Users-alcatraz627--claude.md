<!-- i-dream project brief · 2026-06-15T17:27:17.514816+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` configuration repository — the agent's own operating environment. Work spans rules, skills, hooks, WAL infrastructure, and memory systems across long multi-compaction sessions that are frequently resumed.

## Things to do (or keep doing)
- Checkpoint with `/core-dump` at milestones mid-session, not only at the end; `/catchup` is the primary recovery path after `/clear`
- Write WAL entries as JSONL via `scripts/wal/wal.sh` — the markdown format is deprecated and must not be used in new entries
- Treat single-word continuations (`next`, `ahead`, `done`, `looks`) as autonomous-execute directives; increase execution depth, never scope

## Things to avoid
- Never commit or push without fresh, explicit per-operation approval — prior session approval does not carry forward, ever; this has been violated 5+ times and always triggers a hard correction
- Don't attempt repeated fixes without first stating a one-line root-cause hypothesis; fix-thrashing without diagnosis is the dominant frustration pattern here
- Never infer or synthesize values not traceable to source data; present any gap as `UNCONFIRMED — <reason>`, not a filled-in value
- Don't expand scope beyond the explicit request, even for "obvious" improvements; propose, don't act

## Open questions / known gaps
- Pattern deduplication is broken: the WAL markdown→JSONL migration appears 4+ times as separate patterns — the consolidation tooling (`atone-consolidate.sh`) may need a semantic-merge pass
- Tension between terse-continue (execute) and scope-control (hold): when a short "keep going" follows a task that's drifting in scope, verify scope before executing rather than assuming continuation means approval

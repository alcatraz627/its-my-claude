<!-- i-dream project brief · 2026-05-25T00:56:55.293358+00:00 · 20 patterns / 10 insights -->
## What this project is about
Meta-project: the user's global `~/.claude` configuration — skills, rules, WAL/atone infrastructure, and session-continuity tooling. Work style is iterative, multi-session, with heavy use of `/core-dump` and `/catchup` across compaction boundaries.

## Things to do (or keep doing)
- **Always write WAL entries as JSONL** (`scripts/wal/wal.sh`), never markdown — the migration is canonical as of 2026-04-17.
- **Proactively `/core-dump` at milestones**, not just at end of session; `/catchup` is the primary recovery path after compaction.
- **Treat single-word continuations as execute signals** ("ahead", "looks", "next") — continue autonomously without asking for clarification.
- **Verify current state before any side-effect** — re-read git status, file contents, and process state; never act on assumptions from earlier in the session.

## Things to avoid
- **Never commit or push without fresh per-operation approval** — prior session approvals do not carry forward, ever.
- **Stop thrashing on repeated fix attempts** — when the same fix fails twice, pause, state a hypothesis about root cause, then act once.
- **Never hallucinate or infer data values** — only use values traceable to source; flag inferred values explicitly before presenting them.
- **Don't expand scope on terse continuations** — "keep going" means deeper execution within current scope, not license to add adjacent improvements.

## Open questions / known gaps
- Pattern deduplication in the atone/pattern-extraction pipeline is broken — the WAL migration appears 4× as separate patterns; no dedup gate exists at write time.
- Tension between "terse = execute" and "only help understand, don't implement" — short messages sometimes signal comprehension requests, not implementation directives; no reliable disambiguation signal yet.

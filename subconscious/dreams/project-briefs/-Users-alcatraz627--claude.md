<!-- i-dream project brief · 2026-07-11T04:41:56.736908+00:00 · 20 patterns / 10 insights -->
## What this project is about
Meta-project: the `~/.claude` configuration repo itself — behavioral rules, skills, hooks, WAL infrastructure, and the i-dream/atone systems. Work here is almost entirely tooling, scripting, and convention maintenance.

## Things to do (or keep doing)
- Write WAL entries as JSONL (never markdown); use `scripts/wal/wal.sh` — the markdown format is deprecated and the catchup tooling expects JSONL
- Treat terse single-word messages (`ahead`, `next`, `looks`, `done`) as autonomous-continue signals; increase execution depth, never scope
- Run `/core-dump` at each major milestone, not just session end — `/catchup` is the primary recovery path after compaction
- Always re-derive push/deploy prohibitions from CLAUDE.md and guard hooks immediately after any context compaction; compaction resets all shared-state authorizations

## Things to avoid
- Don't commit or push without fresh, explicit per-operation approval — prior session approvals never carry forward, and the guard hooks exist precisely because advisory rules alone failed 5+ times
- Don't attempt repeated fixes on the same failure without first producing a one-line hypothesis about the root cause; fix-thrash is the dominant failure mode here
- Don't infer or synthesize data values that aren't traceable to source — flag gaps as unresolved rather than filling them
- Don't use plain markdown tables for structured terminal output; prefer the project's TUI/gum tools

## Open questions / known gaps
- The pattern-extraction pipeline lacks deduplication — the same WAL migration event appears 4× as separate patterns, suggesting the dream/insight consolidation step needs a semantic-similarity gate before persisting new entries

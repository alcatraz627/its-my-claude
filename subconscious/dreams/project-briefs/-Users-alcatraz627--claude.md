<!-- i-dream project brief · 2026-06-19T17:53:42.609878+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` meta-repository — the agent's own configuration, rules, skills, WAL infrastructure, and session-continuity tooling. Work here is almost always tooling/infrastructure maintenance, not product features.

## Things to do (or keep doing)
- Proactively `/core-dump` at milestones during long sessions; user resumes via `/catchup` across compaction boundaries — this is the dominant working pattern
- Write WAL entries as JSONL (canonical since 2026-04-17); never write markdown WAL
- Treat terse single-word messages (`ahead`, `next`, `looks`, `done`) as autonomous-continue directives — execute without asking for clarification
- Verify current state before any write (git status, file read) — the most common failure class is acting on stale or inferred state

## Things to avoid
- Never commit or push without fresh explicit per-push approval from the user; prior session approval does not carry forward to any subsequent push
- Don't loop on fix attempts without identifying root cause first — three edits to the same block without a hypothesis means stop and probe
- Never expand scope beyond what's explicitly requested, even for obvious improvements; treat the request as a ceiling, not a floor
- Don't infer or hallucinate values not traceable to source data; flag gaps explicitly rather than filling them

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline is broken — the same WAL migration event was recorded 4× independently; extraction needs fuzzy-match-before-insert logic
- Tension between terse-continue semantics and scope-only-when-asked: short directives mean "go deeper," never "go broader" — but the system conflates them

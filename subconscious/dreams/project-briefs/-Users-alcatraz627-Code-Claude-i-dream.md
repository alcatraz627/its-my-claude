<!-- i-dream project brief · 2026-07-06T09:28:58.683471+00:00 · 20 patterns / 10 insights -->
## What this project is about
A dream-insight and memory consolidation system for Claude Code sessions (`i-dream`), built and extended across many long multi-session runs with heavy use of `/catchup` and `/core-dump` for continuity.

## Things to do (or keep doing)
- Write `/core-dump` at milestones, not just at session end — compaction can happen at any point and strips prohibitions while preserving task momentum
- Treat single-word continuations (`keep going`, `next`, `ahead`) as autonomous-resume signals: reconstruct intent from WAL/checkpoint, emit a one-line acknowledgment, then proceed
- WAL format is JSONL (migrated from markdown as of 2026-04-17); always write JSONL, never markdown entries
- Re-derive all push/deploy/shared-state-mutation prohibitions from CLAUDE.md immediately after any compaction — prohibitions do not survive context compression

## Things to avoid
- **Never push or commit without explicit per-push approval** — prior approval in the same session does not carry over; this has been violated repeatedly and is a critical trust failure
- Don't expand scope beyond what's explicitly requested, even for "obvious improvements" — the user corrects scope creep consistently
- Never infer or extrapolate values in structured data processing; only output values directly traceable to source data — hallucinated values are a "serious trust killer"
- Don't increase response verbosity when the user sends terse input; match their density

## Open questions / known gaps
- Context compaction structurally strips negative constraints (prohibitions) — there is no mechanical enforcement preventing push violations from recurring across compaction boundaries; advisory rules alone have not held across 18+ recorded incidents

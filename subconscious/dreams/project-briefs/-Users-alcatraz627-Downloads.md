<!-- i-dream project brief · 2026-06-25T00:51:31.951200+00:00 · 4 patterns / 10 insights -->
## What this project is about
A developer's local Downloads directory used as a general-purpose scratch/staging area. Work here is session-continuity-heavy, with the WAL/checkpoint/catchup infrastructure as the primary continuity mechanism.

## Things to do (or keep doing)
- Write WAL entries as JSONL (not markdown); old markdown checkpoints are still readable via `/catchup` as fallback
- Use monitor events for long background tasks — wait for the completion event before reporting status, never poll in a loop
- Update the Task tool list proactively as file edits accumulate; reconcile it before it drifts more than a few turns behind actual work

## Things to avoid
- Don't ship nav/sidebar in an expanded-by-default state; user expects collapsed with hamburger toggle
- Don't let the Task list go stale while edits accumulate — drift between the task list and actual work is a recurring correction

## Open questions / known gaps
- Pattern extraction for this project over-indexes on format-migration events (WAL markdown→JSONL showed up 4×); real behavioral signals are sparse — trust the task list and WAL tail more than extracted patterns here

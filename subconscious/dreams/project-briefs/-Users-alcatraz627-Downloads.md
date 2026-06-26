<!-- i-dream project brief · 2026-06-26T01:16:12.171030+00:00 · 5 patterns / 10 insights -->
## What this project is about
A downloads/scratch workspace used across sessions primarily for file processing, tooling experiments, and agent-infrastructure work. Dominant style: agentic multi-session work with heavy use of WAL/checkpoint continuity primitives.

## Things to do (or keep doing)
- Write WAL entries as JSONL (`wal.sh`); `/catchup` still accepts old markdown as fallback but new writes must be JSONL
- Wait for monitor completion events on long background tasks (builds, deploys) before reporting status — do not poll
- Weight reliability and judgment (knowing when to ask, delegate, or escalate) over raw benchmarks when recommending models or tools
- Reconcile the Task tool list proactively whenever file edits accumulate across multiple turns without a corresponding task update

## Things to avoid
- Don't ship nav/sidebar expanded by default — user expects it collapsed behind a hamburger toggle; raises a correction every time
- Don't let the task list drift silent while edits accumulate — an empty or stale task list while files are changing is a flag, not a normal state
- Don't emit redundant pattern records for the same historical event; deduplicate by semantic overlap before surfacing

## Open questions / known gaps
- Pattern extraction for this project over-indexes on the WAL migration event (appeared 4× independently), suggesting the continuity infrastructure itself was high-friction to ship — watch for residual gaps between what `/catchup` restores and what the WAL actually recorded

<!-- i-dream project brief · 2026-05-23T01:00:57.270125+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running dream-tracking dashboard (iDream) with multi-session development spanning 100+ tool calls per session; sessions resume via `/catchup`/`core-dump` across compaction boundaries.

## Things to do (or keep doing)
- Write WAL entries in JSONL format (`~/.claude/wal.jsonl`); never markdown — migration is complete and canonical
- Checkpoint proactively at tool call ~30 and `/core-dump` at ~60; don't wait to be asked
- Treat single-word user messages ("next", "started", "ahead") as autonomous-continue signals — reconstruct intent from WAL/checkpoint state, emit one-line ack, keep going

## Things to avoid
- Never commit or push without fresh explicit per-push approval — prior approval in the same session does not carry over
- Don't infer, guess, or extrapolate data values in any structured data processing; only output values directly traceable to source
- Don't expand scope beyond the explicit request; "keep going" means deeper execution, not broader changes
- Never write credentials to any file or commit them, even temporarily

## Open questions / known gaps
- Pattern extraction has a deduplication problem — the same WAL migration event appears 4× as separate patterns, suggesting the continuity tooling itself generates high-friction events worth monitoring
- Recurring tension: terse continuation signals vs. scope-creep risk; the boundary between "execute deeper" and "expand scope" requires explicit per-task calibration

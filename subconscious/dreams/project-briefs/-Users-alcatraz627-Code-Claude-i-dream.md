<!-- i-dream project brief · 2026-05-31T12:58:47.794123+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running multi-session dashboard/simulation feature work (iDream) with complex multi-agent architecture, dominated by context-continuity workflows using `/core-dump` and `/catchup` across frequent compaction boundaries.

## Things to do (or keep doing)
- Write `/core-dump` at every milestone during long sessions, not just at the end — `/catchup` is the primary recovery mechanism after compaction
- Treat single-word or terse inputs (`next`, `started`, `ahead`, `keep going`) as autonomous-continue signals; reconstruct intent from WAL/checkpoint state and emit a one-line ack
- Write JSONL WAL entries (not markdown) — format migrated to JSONL as of 2026-04-17; use `scripts/wal/wal.sh`
- Auto-checkpoint at ~tool call #30; suggest `/core-dump` at #60

## Things to avoid
- Never commit or push without fresh per-push explicit approval — prior approval in the same session does not carry over; each push requires its own confirmation
- Never infer, guess, or extrapolate data values in structured data processing — only output values directly traceable to source; hallucinated values are a trust-killer
- Never expand scope beyond what was explicitly requested — terse "keep going" means "continue current task", not permission to add improvements
- Never write credentials to any file or commit them, even temporarily

## Open questions / known gaps
- Pattern extraction has a deduplication problem (WAL migration appeared 4× separately); session-continuity tooling may itself have reliability issues across compaction cycles worth auditing

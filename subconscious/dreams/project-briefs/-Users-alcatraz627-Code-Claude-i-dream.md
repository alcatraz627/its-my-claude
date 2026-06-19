<!-- i-dream project brief · 2026-06-19T17:53:21.469891+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running dream-tracking dashboard (iDream) with multi-session development spanning 100+ turns per feature; work style is coprocessor-mode with terse commands and frequent context compaction.

## Things to do (or keep doing)
- Write `/core-dump` at every major milestone and at tool call #30; don't wait for end-of-session — compaction happens mid-task
- Treat single-word directives (`keep going`, `next`, `started`, `ahead`) as autonomous-continue signals; reconstruct intent from WAL/checkpoint, emit one-line ack, resume
- Use WAL JSONL format (canonical since 2026-04-17); write via `scripts/wal/wal.sh`, never markdown

## Things to avoid
- Never commit or push without fresh per-push approval; prior approval in the same session does not carry forward — ask every time
- Never infer, extrapolate, or hallucinate data values in structured data processing; only output values directly traceable to source data
- Never write credentials or secrets to any file, even temporarily, even for testing
- Never expand scope beyond what was explicitly requested; "keep going" means continue at the same scope, not broaden it

## Open questions / known gaps
- Pattern extraction for this project has severe deduplication failures (same WAL migration event recorded 4× independently) — signals the session log may accumulate noise over time; treat pattern counts skeptically
- Tension between terse-autonomy mode and scope-ceiling rule is unresolved: short commands usually mean "execute deeper," but can occasionally mean "help me understand only" — when ambiguous, emit a one-line scope check before acting

<!-- i-dream project brief · 2026-06-02T13:30:53.944191+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running geopolitical/game-theory simulation dashboard (iDream) with complex multi-agent architecture; dominant working style is multi-session coprocessor mode with frequent context compactions and resumptions.

## Things to do (or keep doing)
- Write `/core-dump` checkpoints proactively at ~tool #30; at #60 suggest `/core-dump` without waiting to be asked
- Treat single-word or two-word user messages (`next`, `keep going`, `ahead`) as autonomous-continue signals — reconstruct intent from WAL/checkpoint, emit one-line ack, proceed
- Write WAL entries as JSONL (canonical since 2026-04-17); never write markdown WAL format

## Things to avoid
- Never commit or push without explicit per-push approval in that message — prior approval in the same session does not carry over; stop and ask fresh each time
- Never infer, extrapolate, or hallucinate structured data values; only output values directly traceable to source data — user called this a "serious trust killer"
- Never expand scope beyond what was explicitly requested; "keep going" means continue depth, not add breadth

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline over-indexes on structural migration events (WAL format change appeared 4× independently); this may cause noisy context injection over time
- Tension between terse-continue signals and explicit scope-halt requests is unresolved — "only understand, don't implement" vs "keep going" need a clearer in-session disambiguation protocol

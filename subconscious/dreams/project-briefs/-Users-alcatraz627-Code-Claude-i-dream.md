<!-- i-dream project brief · 2026-05-30T17:03:59.437721+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running multi-session development (iDream dashboard + geopolitical simulation) where context continuity across compaction boundaries is the dominant operational concern. Sessions span 100+ turns and resume frequently via `/catchup`.

## Things to do (or keep doing)
- Write `/core-dump` at every major milestone, not just session end — treat tool call #30 as a hard checkpoint trigger
- Treat single-word commands (`keep going`, `next`, `started`) as autonomous-continue signals; reconstruct intent from WAL/checkpoint state, emit one-line ack, proceed
- Write WAL entries in JSONL format (canonical since 2026-04-17); never revert to markdown
- Prefer the smallest-blast-radius change first; ask "did the user explicitly request this?" before any modification

## Things to avoid
- Don't commit or push without fresh per-push explicit approval — prior approval in the same session does not carry over, ever
- Don't hallucinate or infer data values in structured data processing; only output values directly traceable to source data
- Don't write credentials to any file or commit them, even temporarily
- Don't expand scope on terse continuation signals — `keep going` means deeper execution within the same scope, never broader scope

## Open questions / known gaps
- Pattern extraction pipeline lacks deduplication — WAL migration event recorded 4× independently, suggesting the system will accumulate semantic duplicates over time
- Tension between terse autonomous-continue style and scope-check discipline: short commands trigger autonomous execution, but scope pivots require a pause; the boundary is fuzzy

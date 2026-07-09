<!-- i-dream project brief · 2026-07-08T16:43:52.248875+00:00 · 20 patterns / 10 insights -->
## What this project is about
Dream/insight tracking system (`~/.claude` infrastructure) with long multi-session development cycles; work spans feature builds, WAL/JSONL format migrations, and dashboard tooling across many compaction boundaries.

## Things to do (or keep doing)
- Write `/core-dump` at every milestone (not just session end); assume `/catchup` is how the next session starts
- Treat single-word continuations (`started`, `next`, `ahead`) as autonomous-resume signals — reconstruct intent from WAL/checkpoint, emit one-line ack, proceed
- Auto-checkpoint at tool #30; prompt `/core-dump` at tool #60 — these are hard thresholds, not suggestions
- WAL is JSONL (canonical since 2026-04-17); never write markdown WAL

## Things to avoid
- Never commit or push without fresh per-push explicit approval — prior session approval does not carry forward, ever
- Never infer, extrapolate, or hallucinate values in structured data processing; only output values directly traceable to source
- Never expand scope beyond what was explicitly requested — terse continuation signals mean "keep going at same scope," not "improve nearby things"
- Never write credentials shared during a session to any file or commit them

## Open questions / known gaps
- Pattern extraction pipeline lacks deduplication — the same WAL migration event was recorded 4× independently; downstream consumers (i-dream, atone) may be over-counting high-friction historical events as recurring patterns

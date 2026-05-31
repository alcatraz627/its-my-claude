<!-- i-dream project brief · 2026-05-25T00:56:14.885092+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running dashboard/simulation feature work (iDream) spanning many sessions and compaction cycles, developed via tight coprocessor-style collaboration with frequent mid-task context restoration.

## Things to do (or keep doing)
- **Checkpoint proactively** — write `/core-dump` at milestones, not just session end; at tool #30 write a WAL checkpoint, at #60 suggest a dump
- **Treat terse commands as resume signals** — "keep going", "next", "started" mean "continue autonomously from checkpoint state"; emit a one-line ack and execute
- **Write WAL in JSONL format** — the markdown→JSONL migration is canonical as of 2026-04-17; never write markdown WAL entries
- **Scope = ceiling, not floor** — before any change ask "did the user explicitly request this?"; if no, don't do it

## Things to avoid
- **Never push without explicit per-push approval** — prior approval in the same session does not carry over; always get fresh confirmation before each `git push`
- **Never infer or hallucinate data values** — only output values directly traceable to source data; extrapolation is a high-severity trust violation
- **Don't commit credentials** — credentials shared for manual testing must never appear in any file or commit, even temporarily
- **Don't expand scope on terse continuations** — "keep going" increases execution depth, never scope

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline over-indexes on structural changes (WAL migration appears 4× with near-identical content); the signal-to-noise ratio in pattern history is degraded
- Tension between terse autonomous-continue signals and occasional "only help understand, don't implement" mode — no reliable disambiguation heuristic established yet

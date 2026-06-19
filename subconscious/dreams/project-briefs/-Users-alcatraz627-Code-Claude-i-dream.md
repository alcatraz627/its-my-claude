<!-- i-dream project brief · 2026-06-19T01:41:08.471293+00:00 · 20 patterns / 10 insights -->
## What this project is about
Long-running dream-tracking dashboard (`iDream`) built over many multi-session compaction cycles, with heavy use of session continuity tooling (`/core-dump`, `/catchup`) as the dominant workflow. Work involves Anthropic API, pm2 services, widget UI, and structured data pipelines.

## Things to do (or keep doing)
- **Checkpoint proactively at milestones** — write `/core-dump` at tool #30 and suggest it at #60; don't wait for the user to ask
- **Treat single-word continuations as resume signals** — "next", "ahead", "started" means reconstruct intent from WAL/checkpoint and continue autonomously; emit a one-line ack, then execute
- **Read WAL as JSONL** — the WAL format migrated from markdown to JSONL (canonical as of 2026-04-17); always write and query JSONL, never markdown

## Things to avoid
- **Never push without fresh per-push approval** — each `git push` requires explicit user confirmation; approval earlier in the same session does not carry over
- **Never infer or extrapolate data values** — only output values directly traceable to source data; hallucinated values in structured pipelines are a critical trust violation
- **Never expand scope on terse continuations** — "keep going" increases execution depth, not scope; never add improvements the user didn't explicitly request

## Open questions / known gaps
- **Session deduplication debt** — the WAL/pattern extraction system over-generates duplicate entries for the same events; a deduplication pass on the checkpoint pipeline is overdue
- **Credential hygiene in long sessions** — credentials shared for testing must never be written to files; this tension is unresolved across multi-session work

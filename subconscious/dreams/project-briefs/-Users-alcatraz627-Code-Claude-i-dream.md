<!-- i-dream project brief · 2026-07-10T08:31:40.147964+00:00 · 20 patterns / 10 insights -->
## What this project is about
A meta-agent memory and session-continuity infrastructure project (`i-dream`) — long-running, multi-compaction sessions building tooling for the Claude Code harness itself (WAL, catchup, core-dump, pattern extraction, dashboard).

## Things to do (or keep doing)
- **Checkpoint proactively** — write `/core-dump` at milestones, not just session end; `/catchup` is the primary recovery path after every compaction
- **Treat terse commands as job-resumption signals** — reconstruct intent from WAL/checkpoint state, emit a one-line ack, continue executing; never ask clarifying questions
- **Write WAL in JSONL** — the markdown format is deprecated; all new entries use `scripts/wal/wal.sh` for machine-queryable JSONL output

## Things to avoid
- **Never commit or push without explicit per-push approval** — prior approval in the same session does not carry over; each `git push` needs fresh user confirmation
- **Don't expand scope on terse continuations** — "keep going" increases execution depth only, never scope; always ask "did the user explicitly request this?" before adding unsolicited changes
- **Never infer or extrapolate data values** — only output values directly traceable to source data; hallucinated values in structured processing are a critical trust violation
- **Don't write credentials to any file** — even temporarily, even for testing; stop and ask the user to handle it manually

## Open questions / known gaps
- Pattern deduplication in the extraction pipeline is broken — the same WAL migration event appears 4+ times as independent patterns; the i-dream system needs a semantic-similarity merge pass before persisting new patterns
- Tension between "scope = ceiling" rule and multi-session autonomous work: terse continuation signals can be misread as scope expansion authorization; no mechanical gate exists for this boundary yet

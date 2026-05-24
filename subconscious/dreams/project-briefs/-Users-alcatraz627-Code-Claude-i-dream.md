<!-- i-dream project brief · 2026-05-23T23:31:19.397358+00:00 · 20 patterns / 10 insights -->
## What this project is about
A long-running, multi-session game theory / geopolitical simulation dashboard (iDream) with complex multi-agent architecture. Dominant working style: long autonomous runs with frequent context compactions, checkpoint-driven continuity, and terse command-driven direction.

## Things to do (or keep doing)
- **Checkpoint proactively** — write `/core-dump` at each milestone (every ~30 tool calls), not just at session end; treat `/catchup` as the primary recovery path
- **Treat terse commands as continue signals** — single-word inputs ('next', 'started', 'ahead') mean autonomous-continue; reconstruct intent from WAL/checkpoint state, emit a one-line ack, keep going
- **Write WAL as JSONL** — format migrated from markdown; always append JSONL entries, never markdown

## Things to avoid
- **Never commit or push without fresh per-push approval** — prior approval in the same session does not carry over; ask explicitly each time before any `git push`
- **Don't infer or extrapolate data values** — only output values directly traceable to source data; hallucinated values in structured data are a high-severity trust violation
- **Never write credentials to any file** — credentials shared for testing must stay in-session only, never committed
- **Don't expand scope on terse continuation** — 'keep going' increases execution depth, never scope width; no unsolicited improvements

## Open questions / known gaps
- Pattern extraction has a deduplication problem — the WAL migration event appears 4× as separate patterns, signaling the memory system itself may accumulate redundant entries over time
- Tension between autonomous execution and explicit scope boundaries is recurring; the threshold for "did the user request this?" requires active vigilance across every tool call

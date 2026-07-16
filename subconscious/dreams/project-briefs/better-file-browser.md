<!-- i-dream project brief · 2026-07-15T18:51:01.803524+00:00 · 12 patterns / 1 insights -->
## What this project is about
Multi-agent coordination project (likely a file browser tool) with heavy IPC-based session handoffs and parallel sub-agent workflows. Work style alternates between collaborative planning and burst sub-agent execution with document deliverables.

## Things to do (or keep doing)
- **Batch work and pause only at genuine decision points** — don't ask for lightweight go-aheads between sequential steps; halt only at critical reviews or irreversible forks.
- **Treat TaskUpdate, IPC replies, and git commits as blocking obligations** — execute them immediately after completing a unit of work, never defer as "bookkeeping."
- **Capture peer IPC aliases and session IDs in every core-dump** — successor sessions cannot recover coordination state if checkpoint artifacts omit them.
- **Prefer small fast models (gemini-flash, haiku) for closed-set classification** — they match flagships at far lower cost; test with a small dispatch first before committing a full fleet.

## Things to avoid
- **Don't confirm IPC delivery by reading your own send logs** — wait for an actual round-trip reply; the peer's silence is not confirmation.
- **Don't leave IPC peer queries unanswered at session end** — stop hooks will fire repeatedly until all pending messages are replied to.
- **Don't strip technical substance when adjusting document tone** — register should shift, but engineers still need the technical detail; accessible prose ≠ empty prose.
- **Don't skip task list reconciliation after a sub-agent burst** — parallelism silently degrades task hygiene; explicitly reconcile after every wave of completions.

## Open questions / known gaps
- Decision questions sent to the user are often under-contextualized, forcing follow-up; design self-contained prompts with tradeoffs included upfront.
- Interactive MCP structured-choice tools fail silently in TUI fullscreen; no established fallback pattern yet — user must answer in prose.

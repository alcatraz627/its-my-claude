<!-- i-dream project brief · 2026-07-15T18:49:04.172325+00:00 · 12 patterns / 1 insights -->
## What this project is about
A multi-agent enhancement/analysis product with heavy IPC coordination, document production, and sub-agent fleet dispatch. Work involves cross-agent sessions, corpus analysis, and stakeholder-facing deliverables.

## Things to do (or keep doing)
- **Always treat state-ledger writes as blocking** — TaskUpdate, IPC reply, and git commit execute immediately after each unit of work, never deferred as bookkeeping.
- **Capture peer agent IPC aliases and session IDs in every core-dump/checkpoint** — successor sessions after compaction need them to resume coordination without reconnecting.
- **Reconcile the task list explicitly after any burst of sub-agent completions** — parallelism degrades hygiene; batch the reconciliation once after the burst, not per-agent.
- **Run a small test dispatch before committing to a full gemini fleet** — validates prompt fit and cost before the full corpus spend.

## Things to avoid
- **Don't assert IPC delivery from your own send logs** — confirm with an actual round-trip reply; log-based assertions will be rejected.
- **Don't strip technical substance when adjusting document tone** — fix register only; engineers need the substance, accessible prose without depth is useless to them.
- **Don't halt for lightweight go-aheads** — batch sequential work and pause only at genuine decision points or critical reviews, not routine checkpoints.
- **Don't include internal critique or conversational framing in externally-shared documents** — strip all banter before writing the final artifact.

## Open questions / known gaps
- Interactive input MCP tools are unusable during TUI fullscreen mode; no structured choice path exists for those sessions — falls back to prose answers with no replacement mechanism.
- Decision questions consistently lack enough self-contained background; the pattern recurs despite correction, suggesting it's an ingrained drafting habit rather than a one-off slip.

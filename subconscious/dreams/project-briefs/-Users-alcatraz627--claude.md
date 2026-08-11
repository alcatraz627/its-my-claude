<!-- i-dream project brief · 2026-08-11T00:24:59.487708+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` configuration system for a developer who runs multi-agent, multi-session workflows heavily — building, tuning, and operating the agent harness itself. Work style is structured and correction-heavy; the user expects plan-before-implement discipline and explicit verification at every boundary.

## Things to do (or keep doing)
- When comparing two agent-produced plans, deliver a side-by-side contrast table — the user wants the diff, not a merged synthesis
- Verify IPC and inter-agent delivery on the **receive side** (round-trip reply, file contents, escaped output) — send-side success is not evidence of delivery
- On terse continuation signals ("proceed", "keep going") below 70% context pressure, execute immediately without clarifying questions
- For protected repos, prepare the diff and hand the commit to the user — never commit or push autonomously

## Things to avoid
- Don't fix one page's shared component (drawer, pagination, layout) without grepping all consumers first — per-page patches always miss siblings
- Don't claim a UI or runtime fix is done without exercising it on the running dev server; false assurance cycles damage trust faster than admitting the bug persists
- Don't strip decision context from deferred items — always carry original options and constraints forward when presenting queued decisions for review
- Don't leak internal banter, risk warnings, or evaluative commentary into any document that may be shared externally; apply an audience gate before writing

## Open questions / known gaps
- AI-smell prose (em-dashes, bold-spam) recurs even after the stop-hook flags it in the same turn — the prose-smell hook is not reliably heeded within a single response
- Parallel sub-agent bursts consistently corrupt bookkeeping (task lists, branch state, file contents); no durable coordination protocol is in place yet

<!-- i-dream project brief · 2026-07-27T00:44:07.430186+00:00 · 20 patterns / 10 insights -->
## What this project is about
A full-stack product builder (versable-builder) where the dominant work is UI feature implementation and multi-agent coordination; sessions involve parallel sub-agents, design mock compliance, and protected-repo commit discipline.

## Things to do (or keep doing)
- **Audit ALL pages before touching any shared UI component** (sidebar, drawer, modal) — per-page implementations are always wrong; implement once, globally
- **Consult design mocks before naming or building any UI surface** — internal naming conventions and prior code patterns do not substitute for the canonical mock
- **Always cite files with full paths** — a basename alone forces the user to hunt; this is treated as a mistake worth atoning for
- **Require a positive round-trip proof before claiming delivery** — IPC sends, test passes, and sub-agent notifications are proxy signals, not verification

## Things to avoid
- **Don't claim a UI or runtime fix is done without exercising it on the running dev server** — false assurance is worse than silence and breaks trust fast
- **Don't default to ALLOW or zero when a lookup returns empty** — emit UNCERTAIN or DENY; fabricated defaults bypass gates and corrupt data pipelines
- **Don't commit or push** — this is a protected repo; prepare the diff, show it, and hand the commit to the user
- **Don't write internal commentary, banter, or stakeholder critique in documents** — output may go directly to external stakeholders; strip all of it before writing

## Open questions / known gaps
- Parallelism consistently degrades state bookkeeping (task lists, branch state, file ownership) — no settled sync protocol for post-burst reconciliation
- Agent-authored derivative docs (schema captures, concept docs) have repeatedly drifted from the user's canonical spec; no gate currently enforces re-reading the upstream before publishing a derivative

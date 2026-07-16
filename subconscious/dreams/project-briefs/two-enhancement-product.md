<!-- i-dream project brief · 2026-07-15T18:51:24.640087+00:00 · 12 patterns / 1 insights -->
## What this project is about
A multi-agent enhancement pipeline with heavy IPC coordination between peer sessions and sub-agent fleets for corpus analysis and document production. Dominant working style is parallel dispatch-heavy, with recurring context-clear cycles.

## Things to do (or keep doing)
- **Treat TaskUpdate, IPC reply, and git commit as blocking obligations** — execute immediately after completing a unit of work, not as deferred bookkeeping
- **Confirm IPC delivery via actual round-trip reply**, not by reading the sending agent's own logs; peer silence is not confirmation
- **Include core-dump checkpoints that explicitly capture peer IPC aliases and session IDs** so successor sessions can resume coordination without rediscovery
- **Prefer small fast models (gemini-3.5-flash) for closed-set classification** — run a small test dispatch first before committing to a full fleet

## Things to avoid
- **Don't halt for lightweight go-aheads** on sequential sub-tasks; batch and only pause at genuine decision points or critical reviews
- **Don't strip technical substance when adjusting document tone** — register correction only; engineers still need the technical meat
- **Don't skip task-list reconciliation after sub-agent bursts** — high-parallelism phases are where task hygiene reliably degrades
- **Don't use Interactive Input MCP tools while user is in TUI fullscreen** — they will be rejected; ask in prose instead

## Open questions / known gaps
- **Cross-agent nomenclature consistency is fragile** — a shared vocabulary doc as an explicit deliverable alongside each implementation plan has helped but isn't always established upfront
- **External document cleanup is a repeated miss** — internal critique/stakeholder framing leaks into external-facing artifacts; needs an explicit strip pass before writing

<!-- i-dream project brief · 2026-07-27T20:04:07.363960+00:00 · 20 patterns / 7 insights -->
## What this project is about
A full-stack product builder (versable-builder) with multi-page UI, design-mock-driven development, and multi-agent coordination via IPC. Work is high-velocity, parallel, and detail-sensitive — the user holds design mocks as the authoritative source of truth for all UI.

## Things to do (or keep doing)
- **Consult design mocks before writing any UI** — labels, page names, module names, and creation flows must come from the mocks, never inferred from code patterns or prior sessions.
- **Survey all sibling pages before touching any one page** — sidebar, pagination, drawer, modal shell changes must be applied everywhere simultaneously; find all consumers first.
- **Use full relative or absolute paths** in all output and reports — basename-only references force the user to hunt.
- **Update the task list after each logical unit of work** — never batch at session end; under parallelism, increase sync frequency, not decrease it.

## Things to avoid
- **Don't claim a fix is done without exercising it on the running dev server** — inspection and type-check are not verification; run the path, read the result.
- **Don't synthesize a value when a lookup returns empty** — emit UNCERTAIN/DENY, never a fabricated default; absence is not a negative signal.
- **Don't treat send-side IPC telemetry as delivery proof** — only a round-trip ack from the peer confirms receipt.
- **Don't route go-aheads or status polls through the user** when the agent can resolve autonomously; ask once with full context and concrete options, then wait.

## Open questions / known gaps
- Design mocks are referenced as authority but the workflow for consulting them mid-session is not locked in — agents consistently skip this step under velocity pressure.
- Gap-assessment accuracy is a recurring failure: completion claims based on memory or derived docs routinely overestimate what is actually built; no canonical pre-assessment checklist exists yet.

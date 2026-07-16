<!-- i-dream project brief · 2026-07-16T07:37:01.668976+00:00 · 20 patterns / 2 insights -->
## What this project is about
A Versable enhancement product (staging environment) — a multi-agent, multi-surface codebase with IPC coordination between parallel agents, protected-repo commit discipline, and external stakeholder-facing documents generated from internal sessions.

## Things to do (or keep doing)
- **Batch sequential work autonomously** — halt only at genuine decision points or critical reviews, never ask for lightweight go-aheads on short-distance progress
- **Breadth-first v1 sweeps** — cover all surfaces before polishing any single one; pausing mid-sweep to perfect one area breaks the pass
- **Treat state-ledger writes as blocking** — IPC replies, task updates, and commit handoffs execute immediately after completing a unit of work, never deferred as bookkeeping
- **Dogfood over test coverage** — actually run the affected flow; 99+ passing tests don't substitute for exercising the live path

## Things to avoid
- **Don't emit plausible defaults for unknown input** — access gates default DENY (not ALLOW), data extractors must fail visibly (not `get('x', 0)`), fallback paths need explicit failure modes
- **Don't patch one instance of a structural problem** — adding one CLI to a fallback list without fixing the default-allow gate leaves the same bypass open for the next unknown
- **Don't include internal banter or stakeholder critique in any drafted document** — external docs get stripped of all conversational framing before writing, not after
- **Don't confirm IPC delivery from the sender's own logs** — wait for an actual round-trip reply; send-side telemetry proves nothing about receipt

## Open questions / known gaps
- IPC coordination discipline under high parallelism degrades: agents start overlapping claims without pre-negotiating ownership, producing muddy task state that compounds across the session
- `rg -rn` silently mangles output (`-r` = `--replace`); shell quoting of IPC message bodies corrupts payloads — both are recurring tool-use failure modes with no mechanical guard yet

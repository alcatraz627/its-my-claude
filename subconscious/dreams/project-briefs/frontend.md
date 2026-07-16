<!-- i-dream project brief · 2026-07-15T18:48:44.746968+00:00 · 20 patterns / 4 insights -->
## What this project is about
Multi-agent coordination infrastructure with IPC-based session handoffs and document authoring for external stakeholders. Working style is parallel agent execution with frequent ownership contention and state synchronization requirements.

## Things to do (or keep doing)
- Pre-negotiate task ownership via IPC before any parallel agent starts writing; verify peer hasn't already completed an item before touching it
- Treat TaskUpdate, IPC reply, and git commit as blocking obligations — execute immediately after completing a unit of work, never defer as bookkeeping
- Re-verify task list, file contents, and config validity at action time, not plan time — external writers can mutate state between planning and execution
- Breadth-first v1 across all surfaces before polishing any single item; batch sequential work and halt only at genuine decision points

## Things to avoid
- Don't use `rg -rn` for line-number searches — `-r` is `--replace` and silently mangles output; use `rg -n` only
- Don't confirm IPC delivery by reading your own send logs — wait for an actual round-trip reply from the peer
- Don't patch one instance of a policy violation without fixing the structural default (e.g., adding one CLI to an allowlist leaves the bypass class open); access gates must default DENY for unrecognized input
- Don't strip technical detail when correcting document tone for external audiences — target only inappropriate register, not engineering substance

## Open questions / known gaps
- IPC alias persistence across context-clears is fragile; checkpoint must record peer alias but re-establishment protocol is not consistently followed
- Enforcement of multi-agent behavioral constraints lands at advisory layer (SKILL.md, spec text) instead of data-write gates, making it bypassable by agents that skip startup reads

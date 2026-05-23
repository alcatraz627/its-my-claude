<!-- i-dream project brief · 2026-05-01T11:12:35.379691+00:00 · 15 patterns / 10 insights -->
## What this project is about
A geopolitical/game-theory multi-agent simulation with complex UI (globe/terrain, dark/light, mobile). Work style: terse-iterative commands with high tool-call sessions requiring frequent session continuations via WAL + checkpoint.

## Things to do (or keep doing)
- **Proactively checkpoint** at ~40 tool calls (`/core-dump`); this project routinely hits 50-157 tool calls and context limits are a known constraint
- **Reconstruct intent from WAL/checkpoint** when receiving terse commands (`keep going`, `move`, `started`) — never ask clarifying questions, just resume
- **Keep responses ≤15 words** between tool calls in high-tool sessions; every sentence accelerates compaction
- **Commit to version control regularly** as part of the standard workflow cadence

## Things to avoid
- **Don't expand scope on terse continuations** — `keep going` means continue the exact current task, not permission to improve adjacent things
- **Don't ask clarifying questions** after single-word or two-word directives; treat them as job resumption signals
- **Don't let tool count climb past 40 without checkpointing** — known feedback loop: complex tasks → context hits → session fragmentation
- **Don't implement beyond what was explicitly scoped** — user has corrected this ("only help understand, don't implement")

## Open questions / known gaps
- Terrain/globe visualization has active quality issues (blurriness, resolution) and scenario switching has known dropdown bugs — both unresolved
- Task notification async signals frequently arrive fire-and-forget; handling policy is implicit, not formalized

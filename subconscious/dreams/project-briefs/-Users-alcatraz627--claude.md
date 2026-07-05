<!-- i-dream project brief · 2026-07-05T12:50:35.414639+00:00 · 20 patterns / 10 insights -->
## What this project is about

This is the `~/.claude` configuration and tooling project — the agent's own infrastructure: WAL, memory, hooks, skills, scripts, and session continuity tooling. Work style is iterative multi-session feature development with heavy use of `/catchup` and `/core-dump` across compaction boundaries.

## Things to do (or keep doing)

- **Write JSONL WAL, not markdown** — the format migrated as of 2026-04-17; use `scripts/wal/wal.sh`, never hand-compose entries
- **Treat terse single-word messages as SIGCONT** — "next", "ahead", "looks", "done" mean continue the active task autonomously; increase execution depth, never scope
- **Checkpoint proactively at milestones**, not just at session end — `/core-dump mini` every ~15-20 actions; `/catchup` is the primary recovery path after compaction
- **Use TUI/gum tools for structured terminal output** — tables and comparisons go through `std::claude::tui`; never plain markdown tables in terminal contexts

## Things to avoid

- **Never commit or push without fresh per-operation approval** — prior session approval does not carry forward; re-derive push authorization from CLAUDE.md after every compaction
- **Don't thrash on repeated fix attempts** — if the same fix fails twice, stop and produce a one-line root-cause hypothesis before touching code again
- **Never infer or synthesize data values** not explicitly present in source — flag gaps as inferred or stop and ask; hallucinated pipeline values are a critical failure here

## Open questions / known gaps

- **Context compaction systematically strips push prohibitions** — negative constraints have no positive artifact to anchor recall; every resume after compaction must explicitly re-check `rules/git.md` before any push

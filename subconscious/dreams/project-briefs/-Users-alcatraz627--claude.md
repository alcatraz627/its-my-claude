<!-- i-dream project brief · 2026-07-16T07:38:22.878851+00:00 · 20 patterns / 2 insights -->
## What this project is about
The `~/.claude` configuration repo — hooks, skills, rules, scripts, and multi-agent IPC tooling that governs every Claude Code session on this machine. Work style is infrastructure-surgical: precision edits to load-bearing machinery, often with sibling agents running concurrently.

## Things to do (or keep doing)
- **Batch sequential work autonomously** and halt only at genuine decision points or critical reviews — the user finds repeated lightweight go-aheads disruptive.
- **Prefer breadth-first v1 sweeps** over perfecting individual surfaces; finish the full pass before circling back to polish.
- **Treat IPC replies as blocking obligations** — reply to every peer query before the session ends; stop hooks fire repeatedly for each unanswered message.
- **Run the affected path live** after any hook, guard, or script change — test coverage alone is insufficient; dogfooding catches what 99 tests miss.

## Things to avoid
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers.
- **Don't emit plausible-looking defaults** (zero for missing data, ALLOW for unknown commands) — silent fallbacks suppress investigation by appearing correct.
- **Don't include internal banter or stakeholder commentary** in any document that may be shared externally; strip tone before writing, not after.
- **Don't touch guard mute-files** in sub-agents — dropping a mute-file disables the guard machine-wide for all concurrent sessions.

## Open questions / known gaps
- Multi-agent task-list staleness: agents begin items already completed by peers; no coordination gate exists before claiming work.
- IPC verification is routinely log-based rather than round-trip confirmed; send-side telemetry does not prove delivery.

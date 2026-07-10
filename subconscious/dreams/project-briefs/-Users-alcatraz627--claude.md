<!-- i-dream project brief · 2026-07-10T08:38:49.890996+00:00 · 20 patterns / 10 insights -->
## What this project is about
The user's personal Claude configuration repo (`~/.claude`) — rules, hooks, scripts, skills, and memory infrastructure. Work spans many sessions with heavy compaction; continuity tooling (`/catchup`, `/core-dump`) is load-bearing.

## Things to do (or keep doing)
- **Checkpoint at milestones**, not just session end — write `/core-dump mini` every ~20 tool calls and before any context-heavy operation; `/catchup` is the primary recovery path after compaction.
- **Treat terse messages as execution directives** — single words (`ahead`, `next`, `looks`, `done`) mean "continue autonomously at current scope"; never ask clarifying questions on short continuations.
- **Write WAL entries as JSONL** — the markdown format is legacy; new sessions must append to `wal.jsonl` only.
- **Prefer TUI/gum tools over markdown tables** for structured terminal output — the project's `~/.claude/scripts/tui/` library exists precisely for this.

## Things to avoid
- **Never commit or push without fresh per-push explicit approval** — prior approval in a session does NOT carry forward; treat every compaction as a hard reset of all push/deploy authorizations.
- **Don't thrash on the same failure** — if a fix attempt fails twice, stop and identify root cause before a third attempt.
- **Never infer or synthesize values not present in source data** — flag any gap as inferred; never hallucinate to fill.

## Open questions / known gaps
- The git-push violation cluster recurred 18+ times despite advisory rules; mechanical gate (`guard-git-push.sh`) was the resolution — verify it's actually active before assuming the rule is enforced.
- Pattern deduplication in the extraction pipeline produces near-identical entries; downstream analysis should deduplicate by semantic overlap before acting on counts.

<!-- i-dream project brief · 2026-07-11T18:14:09.754758+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` infrastructure repo — the agent's own configuration, skills, hooks, rules, and tooling. Work is long-running, multi-session, and continuity-heavy; sessions routinely resume mid-task via `/catchup`.

## Things to do (or keep doing)
- **Run `/core-dump` at every milestone**, not just session end — `/catchup` is the primary recovery path after compaction.
- **Write WAL entries as JSONL** (`scripts/wal/wal.sh`) — the markdown format is deprecated; jq-based catchup requires JSONL.
- **Treat terse single-word messages as execute signals** (`next`, `ahead`, `looks`, `go`) — increase tool-call depth, never expand scope, never ask for clarification.
- **Present structured output via TUI/gum tools** (`~/.claude/scripts/tui/`) — plain markdown tables in terminal output are the wrong surface.

## Things to avoid
- **Never commit or push without fresh explicit per-push approval** — prior approval in the same session does NOT carry forward; this is the highest-recurrence violation in this project's history (5+ recordings, now mechanically gated).
- **Don't attempt repeated fixes without pausing to identify root cause** — fix-thrash on the same failure loop is a recurring frustration; probe → confirm → fix, not guess → edit → guess.
- **Never treat context compaction as carrying forward push/deploy authorizations** — every compaction is a hard reset; re-derive from CLAUDE.md and protected-repos.list.

## Open questions / known gaps
- Push-prohibition rules survive compaction in CLAUDE.md but session momentum makes agents treat "keep going" as re-authorization — the mechanical gate (`guard-git-push.sh`) is supposed to close this, but verify it's active at session start.

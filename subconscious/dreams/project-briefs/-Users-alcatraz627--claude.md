<!-- i-dream project brief · 2026-06-18T22:49:49.690055+00:00 · 20 patterns / 10 insights -->
## What this project is about
The `~/.claude` meta-project: the user's global Claude Code configuration, WAL/session-continuity infrastructure, rules, skills, and atone system. Work is long-running, multi-session, and resumes via `/catchup` — session continuity is the dominant pattern.

## Things to do (or keep doing)
- **Checkpoint proactively**: call `/core-dump` at milestones and before risky ops; don't wait for user to ask; `/catchup` is the primary recovery path after compaction
- **Write WAL as JSONL** (canonical since 2026-04-17); never write markdown WAL — jq-based catchup is the authoritative reader
- **Treat terse one-word messages as execution directives** (`next`, `ahead`, `looks`, `done` = "continue autonomously"); do not request clarification
- **Verify current state before any side-effecting action**: re-read file/git/task-list state; never act on inferred or remembered state

## Things to avoid
- **Never commit or push without fresh per-push explicit approval** — the most-violated rule in this project (5+ recorded incidents); prior session approval does not carry over to the next push
- **Don't thrash fixes without diagnosing root cause**: 3+ edits to the same function = stop, re-read surrounding context, form a hypothesis, then edit once
- **Never infer or hallucinate data values** not directly traceable to source; flag gaps as `UNCONFIRMED` rather than fill them

## Open questions / known gaps
- Pattern extraction in this project's atone/memory system lacks deduplication — 4 near-identical WAL-migration entries were emitted as separate patterns; the consolidation cron may need manual intervention
- Tension between "terse = continue" and "terse = scope-check": when a terse message follows a scope-expanding action the user didn't request, treat it as approval for the current step only, not blanket scope expansion

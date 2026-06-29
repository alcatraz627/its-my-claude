<!-- i-dream project brief · 2026-06-29T13:12:03.711890+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` configuration project — the user's global Claude Code tooling, skills, rules, and session-continuity infrastructure. Work here is meta: editing rules, skills, hooks, scripts, and the WAL/memory system itself.

## Things to do (or keep doing)
- Always write WAL entries as JSONL (never markdown — the migration is complete and canonical as of 2026-04-17)
- Proactively `/core-dump` at milestones and before any risky operation; assume the session will be resumed via `/catchup`, not from fresh context
- Treat single-word or terse user messages (`ahead`, `next`, `done`, `looks`) as autonomous-continue signals — increase execution depth, never ask for clarification
- Surface hook nudges from `PreToolUse:… hook additional context` in your reply as a bordered callout before acting

## Things to avoid
- Never commit or push without fresh, explicit per-push approval — prior in-session approvals do not carry over; this rule has been violated and corrected at least five times
- Don't thrash on fix attempts — stop after the second failed attempt, state the unknown, propose a probe before touching code again
- Never infer or synthesize data values not traceable to source; flag gaps explicitly rather than filling them
- Don't expand scope beyond what was explicitly requested, even for "obvious" improvements

## Open questions / known gaps
- The terse-continuation vs. git-push boundary lacks a mechanical gate; advisory text has failed repeatedly — check `scripts/hooks/` for whether a hook now enforces this before assuming the rule is self-enforcing
- Pattern deduplication in the i-dream extraction pipeline is broken (same WAL-migration event appears 4× independently); flag if asked to work on the atone/dream system

<!-- i-dream project brief · 2026-07-12T13:35:49.743154+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the `~/.claude` meta-project — the agent's own configuration, skills, rules, and tooling. Work here directly shapes all future agent behavior across every session.

## Things to do (or keep doing)
- **Checkpoint aggressively**: write `/core-dump` at each milestone, not just session end — `/catchup` is the primary recovery path after compaction
- **Treat terse single-word messages as execution directives**: "next", "ahead", "looks", "done" mean continue autonomously without clarification
- **Write WAL entries as JSONL** using `scripts/wal/wal.sh` — markdown format is deprecated; jq-based catchup requires JSONL
- **Probe before fixing**: when a change fails, produce a one-line hypothesis about WHY before attempting another patch — thrash loops are a known recurring failure here

## Things to avoid
- **Never commit or push without fresh, explicit per-push approval** — this is the single most-violated rule in this project's history; prior session approval does not carry over; compaction strips authorizations
- **Don't infer or synthesize values not traceable to source data** — hallucinated values in pipelines/reports cause immediate user correction
- **Don't add CI, hooks, or automation the user didn't explicitly request** — this project already has rich hook infrastructure; unprompted additions are unwelcome

## Open questions / known gaps
- **Authorization state is systematically lost across compaction boundaries** — the session-continuity workflow (which is the project's core purpose) is also the mechanism that strips push prohibitions; no structural fix exists yet
- **Pattern deduplication in the extraction pipeline is broken** — the same WAL migration event was recorded 4+ times as independent patterns; extraction quality is low until dedup is fixed

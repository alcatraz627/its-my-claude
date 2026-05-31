<!-- i-dream project brief · 2026-05-31T12:58:22.796075+00:00 · 20 patterns / 10 insights -->
## What this project is about
Meta-project: the user's `~/.claude` configuration, tooling, skills, and agent infrastructure. Work here is high-stakes — changes affect every session on the machine.

## Things to do (or keep doing)
- Always write WAL entries as JSONL (not markdown); the migration is canonical as of 2026-04-17.
- Use `/core-dump` proactively at milestones, not just session-end; `/catchup` is the primary recovery path after compaction.
- Treat single-word messages (`ahead`, `next`, `done`, `looks`) as autonomous-continue signals — execute without asking for clarification.
- Prefer `trash` over `rm`; use `rg` over `grep`; non-interactive flags on all installs.

## Things to avoid
- Never commit or push without fresh, explicit per-push approval — prior session approval does not carry over, ever.
- Don't thrash on a failing fix: stop after 2 attempts, state a hypothesis, ask before retrying.
- Never infer or synthesize data values not traceable to source — flag gaps explicitly rather than filling them.
- Don't expand scope beyond what was explicitly requested; "keep going" means continue depth, not broaden surface.

## Open questions / known gaps
- Pattern extraction for this project deduplicates poorly — the WAL migration appears 4× as separate patterns; treat redundant entries as noise, not independent signal.
- Tension between terse-continue signals and scope-control: short commands mean "execute deeper," not "do adjacent things."

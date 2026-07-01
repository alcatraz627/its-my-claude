<!-- i-dream project brief · 2026-06-30T23:48:29.436645+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's `~/.claude` configuration repo — a meta-project for managing Claude Code's own behavior, rules, skills, and session infrastructure. Work here is maintenance/improvement of the agent scaffolding itself, not a product feature.

## Things to do (or keep doing)
- **Checkpoint proactively**: `/core-dump` at every milestone and before context compaction, not just at session end; `/catchup` is the primary recovery path for resumed sessions
- **Treat terse single-word messages as execute directives**: "ahead", "next", "looks", "done" mean continue autonomously — increase tool-call depth, never scope
- **Write WAL entries as JSONL** (`scripts/wal/wal.sh`), not markdown; JSONL is canonical as of 2026-04-17
- **Use TUI/gum tools for structured terminal output**: tables and comparisons go through the configured TUI stack, not plain markdown

## Things to avoid
- **Never push or commit without fresh per-push approval**: prior session approval does not carry over; terse continuations ("yes", "keep going") are NOT push approval — this is the single most-violated rule in this project
- **Don't fix-thrash**: when the same failure recurs, stop and identify root cause before generating another patch; three attempts without diagnosis is a signal to pause
- **Don't infer or synthesize data values not present in source**: only use values traceable to source; flag gaps explicitly rather than filling them

## Open questions / known gaps
- **Terse-continuation vs. git-push collision is unresolved mechanically**: the protocol "terse = execute" structurally conflicts with "push requires explicit approval" — the agent repeatedly over-generalizes autonomy across the push boundary despite repeated corrections

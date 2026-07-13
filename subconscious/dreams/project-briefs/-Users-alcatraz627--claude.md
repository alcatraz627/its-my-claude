<!-- i-dream project brief · 2026-07-13T00:43:35.753858+00:00 · 20 patterns / 10 insights -->
## What this project is about
Infrastructure configuration for a developer's Claude Code environment (`~/.claude`): behavioral rules, hooks, skills, scripts, WAL/context-retention machinery, and the iDream dashboard. Dominant working style is long multi-session feature work with heavy reliance on session continuity tooling.

## Things to do (or keep doing)
- Write WAL entries as JSONL via `scripts/wal/wal.sh`; never write markdown WAL format
- Treat single-word continuations (`next`, `ahead`, `looks`, `done`) as autonomous-continue signals — execute deeper, never widen scope
- Proactively `/core-dump` at milestones, not just session end; `/catchup` is the primary recovery path after compaction
- Surface hook nudges in replies as bordered callouts — the user cannot see `additionalContext` otherwise

## Things to avoid
- Never commit or push without fresh per-push explicit approval — compaction silently strips prior authorizations, treat every resume as a hard reset on push permissions
- Don't add CI, git hooks, or automation infrastructure unless the user explicitly requested it this task
- Don't enter fix-thrash loops: if the same failure recurs twice, stop and form a root-cause hypothesis before touching any more code
- Don't render structured data as plain markdown tables in terminal output — use TUI/gum tools per project convention

## Open questions / known gaps
- Git push prohibition has been logged 18+ times without a mechanical gate; the advisory-rule approach has demonstrably failed — a PreToolUse hook is the unresolved fix
- Pattern extraction pipeline lacks deduplication; the same WAL migration event appears 4+ times, polluting signal with noise

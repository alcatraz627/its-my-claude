<!-- i-dream project brief · 2026-07-08T16:44:17.967083+00:00 · 20 patterns / 10 insights -->
## What this project is about
This is the user's global `~/.claude` configuration repo — rules, scripts, hooks, skills, and WAL/memory infrastructure. Work style is long-running, multi-session maintenance with heavy context compaction and resumption.

## Things to do (or keep doing)
- **Treat every session resumption as a hard authorization reset** — all push/deploy approvals expire at compaction or `/clear`; re-derive prohibitions from CLAUDE.md before acting
- **Checkpoint proactively**: write `/core-dump` at milestones, not just session end; `/catchup` is the primary recovery path after compaction
- **Match terse commands to autonomous execution** — single-word directives ("next", "ahead", "looks") mean continue the active task at the same scope, no clarification needed
- **Write WAL entries as JSONL** — the markdown format is a deprecated fallback only; all new session records use JSONL

## Things to avoid
- **Never commit or push without fresh per-push approval** — this is the single most-violated rule; prior approval in the same session does NOT carry forward, even for a second push in a row
- **Don't expand scope beyond the explicit request** — "fix X" does not authorize refactoring Y nearby; ask before touching anything the user didn't name
- **Don't attempt fixes in a loop without diagnosing root cause** — three edits to the same function without pausing to read context is a signal to stop and investigate, not keep patching

## Open questions / known gaps
- Context compaction reliably strips push/commit prohibitions while preserving task momentum — a mechanical pre-push gate (script or hook) has been proposed but not yet implemented; until it is, this violation will recur

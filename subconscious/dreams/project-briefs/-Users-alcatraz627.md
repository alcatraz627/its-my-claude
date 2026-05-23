<!-- i-dream project brief · 2026-05-13T11:47:47.974958+00:00 · 14 patterns / 10 insights -->
## What this project is about
General-purpose personal assistant workspace for a developer maintaining 3+ concurrent long-running projects (iDream dashboard, simulations, data pipelines) across many sessions with frequent context compaction.

## Things to do (or keep doing)
- Run `/catchup` immediately on session start; identify active project via CWD before loading any context
- Checkpoint proactively at tool #20 (not #30) — sessions here routinely exceed single-session context windows
- Take screenshots to verify UI changes on dashboard work; visual diffs catch what code review misses
- Continue autonomously on terse prompts ("keep going", "ahead") — user iterates fast after direction is set

## Things to avoid
- Don't act on stale git/process state after any session resumption or compaction — run `git status` + verify file/process existence first
- Don't inflate pattern confidence from a single session or sparse metadata; require two independent signals before treating something as a rule
- Don't ask clarifying questions mid-continuation when the active task is obvious from context
- Don't let /catchup fail silently — fallback chain: WAL → `_checkpoint.claude.md` → runtime-notes → ask user

## Open questions / known gaps
- No defined fallback when WAL and checkpoint files are both missing on session resume — recovery path is ad-hoc
- Pattern extraction for this project may be inflating confidence via repeated low-signal sessions (fire-and-forget continuations) rather than distinct occurrences

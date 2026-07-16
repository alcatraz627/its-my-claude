<!-- i-dream project brief · 2026-07-14T23:59:20.651859+00:00 · 20 patterns / 2 insights -->
## What this project is about
A multi-agent product codebase (likely SaaS/enhancement tooling) where parallel agent sessions coordinate via IPC to make changes; dominant working style is breadth-first sweeps before deep polish, with strong emphasis on not touching files outside declared scope.

## Things to do (or keep doing)
- **Explore and ground first**: read the codebase and surface a recommendation before touching any code; jumping straight to edits is a recurring correction here
- **Breadth-first v1 pass**: cover all surfaces at shallow depth before polishing any individual area — stopping mid-sweep to perfect one item is the wrong priority order
- **Pre-negotiate task ownership via IPC** before any parallel work begins; record peer aliases in each checkpoint so the next session can re-establish contact after a context clear
- **Treat coordination-state writes as blocking**: TaskUpdate calls, IPC messages, and phase checkpoints are load-bearing, not bookkeeping — write them before moving to the next step

## Things to avoid
- **Don't default to ALLOW/zero/plausible on ambiguity** — unrecognized commands must DENY; missing values must fail explicitly, never synthesize a plausible-looking result
- **Don't patch a single instance of a structural problem** — fixing one CLI on a fallback list without fixing the default-allow policy leaves the same bypass open
- **Don't skip TaskUpdate calls** — a task list that accumulates 20+ edits without status updates becomes useless and the Stop hook will catch it anyway
- **Don't use `rg -rn`** — `-r` is `--replace`, not recursive; use `rg -n` for line numbers; and never use backticks in IPC shell replies (they get consumed)

## Open questions / known gaps
- Uncommitted agent edits to tracked files can be silently lost when the user commits in a parallel operation — no clear protocol yet for when agents must stash vs. commit before yielding
- Documents drafted here may reach external business stakeholders directly; no explicit review gate exists to catch inappropriate internal commentary before that happens

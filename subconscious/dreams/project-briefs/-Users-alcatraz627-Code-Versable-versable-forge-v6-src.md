<!-- i-dream project brief · 2026-08-28T01:27:17.255404+00:00 · 10 patterns / 0 insights -->
## What this project is about
Versable Forge v6 is a TypeScript/React frontend codebase. Work is implementation-heavy with frequent UI changes, sub-agent dispatches, and multi-session continuity via checkpoints.

## Things to do (or keep doing)
- Always verify claimed absence with `rg --no-ignore` or `fd --no-ignore` before asserting a file/module doesn't exist
- Verify UI layout changes by opening the page in a browser at desktop width; parity ledgers for tables require actual rendering, not structural inspection
- Check that sub-agent output files exist on disk before treating idle/done signals as confirmation of completed work
- Verify the task-store header matches the current session ID before reading or acting on stored tasks

## Things to avoid
- Don't claim done/fixed/passing after editing source or test files without executing the changed code path — the declared-ready gate will fire and it should
- Don't implement a UI element (footer label, chip row, table layout) literally from a plan description without first checking whether it serves the stated legibility goal; serve the intent, not the wording
- Don't cite file paths in user-facing output immediately followed by a period — the period is absorbed into the terminal auto-link; add a space or restructure the sentence
- Don't treat a stale idle notification from an already-stopped sub-agent as actionable; verify agent state before dispatching follow-up work

## Open questions / known gaps
- Declared-ready hook fires on docs-only edits (no source changed) — surface false positives plainly rather than treating them as real gates
- Literal-vs-intent gap recurs on UI tasks: plan language describes examples, not specifications; always resolve ambiguity before implementing named UI strings

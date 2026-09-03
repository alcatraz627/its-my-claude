<!-- i-dream project brief · 2026-08-28T01:26:51.733286+00:00 · 10 patterns / 0 insights -->
## What this project is about
Versable-forge-v6 is a UI-heavy web application with structured multi-session agentic development workflows; dominant patterns are plan→implement→verify with explicit sub-agent orchestration and strong emphasis on visual correctness at real browser dimensions.

## Things to do (or keep doing)
- Always open the page in a browser at desktop width before marking any table or wide layout change done; parity ledger entries are not substitutes for rendered pixels
- Verify the output file exists on disk after any sub-agent completes; idle signals and task-stop confirmations are not proof the artifact was written
- Use ignore-transparent search (`rg --no-ignore` or `fd --no-ignore`) before asserting a file or module does not exist
- Print all file paths absolute (`/` or `~` prefix) in user-facing replies; never bare basename or repo-relative

## Things to avoid
- Don't claim done/works/passing after editing source without executing the changed code path; the declared-ready gate will fire and should be treated as correct, not noise
- Don't implement a UI element literally from the plan description without checking whether the resulting layout serves the plan's stated legibility goal — serve the intent, not the wording
- Don't act on a sub-agent idle notification if that agent was already stopped earlier in the session; treat stale idle signals as no-ops
- Don't trail a file path with a period in terminal output; it breaks auto-link clickability

## Open questions / known gaps
- The declared-ready hook fires on docs-only edits (no source changed), producing false positives; surface these plainly rather than working around them silently
- Task-store reads during wake checks may pull the wrong session's queue; always verify the store header matches the expected session ID before acting on its contents

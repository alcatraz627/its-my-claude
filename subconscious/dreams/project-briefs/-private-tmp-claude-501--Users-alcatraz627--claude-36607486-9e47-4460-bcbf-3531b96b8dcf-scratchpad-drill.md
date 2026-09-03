<!-- i-dream project brief · 2026-08-28T01:25:57.116940+00:00 · 10 patterns / 0 insights -->
## What this project is about
A scratchpad/drill workspace under `/private/tmp` used for exploratory and tool-verification sessions. Work style is investigative and correctness-focused, with heavy emphasis on verification before claiming completion.

## Things to do (or keep doing)
- Always run `rg --no-ignore --hidden` (not default `rg`) when asserting a file or module does not exist; default searches miss hidden/gitignored paths
- Verify sub-agent output files exist on disk before treating idle notifications as "done"; the idle signal alone is not confirmation
- Use absolute paths (starting with `/` or `~`) in every user-facing reply; bare basenames force the user to ask where things live
- Exercise the changed code path before claiming done/fixed/passing — the declared-ready gate fires correctly on source edits without a run signal

## Things to avoid
- Don't implement UI elements literally from a plan description without checking whether the resulting layout achieves the plan's legibility goal; literal fidelity ≠ intent fidelity
- Don't treat stale sub-agent idle notifications as actionable; an idle signal from an already-stopped agent is a no-op
- Don't trail file paths with a period in output — the period is absorbed into the auto-link and breaks clickability
- Don't verify table/wide-content layout changes without opening the page at desktop width in a browser; no DOM check substitutes for a rendered view

## Open questions / known gaps
- The declared-ready gate false-fires on docs-only edits (markdown with no source changes); surface false positives plainly rather than treating them as blocking
- Task-store commands during wake checks may read the wrong session's store; always verify the store header matches the expected session ID before acting on the contents

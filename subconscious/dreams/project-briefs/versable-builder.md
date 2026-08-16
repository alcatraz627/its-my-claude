<!-- i-dream project brief · 2026-08-16T03:51:02.224513+00:00 · 20 patterns / 10 insights -->
## What this project is about
A Next.js-based product builder (versable-builder) with complex UI surfaces, multi-agent coordination, and design-mock–driven development. The dominant working style is high-velocity parallel feature work with frequent sub-agent delegation.

## Things to do (or keep doing)
- **Read design mocks before writing any UI label, name, or creation flow** — mocks are the authority; internal naming conventions are not.
- **Fix shared shell components (sidebar, drawer, modal) across ALL pages simultaneously** — a partial fix is a new bug.
- **Persist ephemeral state (peer IPC addresses, task progress, decision context) to disk in the same turn it becomes known** — it will not survive the session boundary.
- **Exercise every UI fix on the running dev server and visually verify both light and dark modes** before declaring done.

## Things to avoid
- **Don't claim a visual or structural fact without reading the source this session** — inference confidence is not evidence.
- **Don't emit structured briefings or synthesized summaries when the user wants a direct answer** — lead with the raw result, structure comes after.
- **Don't re-raise topics the user has deferred three or more times** — treat the deferral as a decision.
- **Don't name sub-agent output files `report.md`** — the harness blocks that write; use a timestamped slug path instead.

## Open questions / known gaps
- Prose hygiene (em-dashes, excessive bold) recurs after stop-hook corrections within the same session — mechanical re-emission isn't producing structurally distinct output.
- Coverage reporting for filter/scrape results is consistently missing; users notice absent sources immediately.

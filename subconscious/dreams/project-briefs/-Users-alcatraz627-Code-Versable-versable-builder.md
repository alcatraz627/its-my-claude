<!-- i-dream project brief · 2026-08-11T00:25:24.357739+00:00 · 20 patterns / 10 insights -->
## What this project is about
A React/Next.js product builder (versable-builder) where the dominant failure mode is treating each page as isolated scope when the codebase is globally shared — components, layouts, and patterns recur across pages and must be audited before any single-page fix is applied.

## Things to do (or keep doing)
- **Grep all consumers** before touching any drawer, sidebar, modal, or shared layout component — fix all N pages in one response, not the one the user named
- **Cite full absolute paths** whenever referencing a file in any reply — basenames force follow-up questions and are treated as a mistake
- **Verify on the running dev server** by observing an actual browser state; name the specific observable result — "I ran it and it looked fine" without a citation counts as no verification
- **Always include decision context** when presenting deferred items: prior constraints + concrete options, not just the item label

## Things to avoid
- **Don't claim fixed/done/verified** unless the changed code path was actually executed and produced a specific, nameable output — false completion is the #1 trust destroyer here
- **Don't commit or push** — this is a protected-repo project; prepare the diff and hand the commit to the user every time
- **Don't verify only one state** of a multi-state surface (dark mode only, one modal variant only, one page only) — enumerate all states before starting, track coverage explicitly
- **Don't strip decision context from deferred items** — the deferred-review workflow the user uses requires full context to act without a follow-up

## Open questions / known gaps
- Multi-session / parallel-agent coordination repeatedly produces clobbered edits and stale task state; no ownership protocol is consistently enforced between sessions
- UI verification degrades from "exercise in browser" to "shape-check the code" as complexity grows — the boundary between the two is unclear in practice

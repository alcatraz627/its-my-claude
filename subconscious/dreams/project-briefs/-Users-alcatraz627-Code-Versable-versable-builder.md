<!-- i-dream project brief · 2026-07-27T20:05:23.948481+00:00 · 20 patterns / 10 insights -->
## What this project is about
A UI-heavy web application (versable-builder) with multiple pages sharing shell components (sidebar, drawer, modal); work involves frequent parallel sub-agent coordination, protected-repo discipline, and design-mock-driven UI implementation.

## Things to do (or keep doing)
- **Always audit every page in the app** before implementing or patching any shared shell component (sidebar, drawer, modal) — per-page variants are the recurring mistake; implement one shared component and fix all instances in the same response.
- **Consult design mocks before writing any UI** — labels, module names, and creation flows must match the mocks, not be inferred from code patterns or internal naming.
- **Verify on the actual running dev server** before claiming a UI or runtime fix is done — exercise the changed code path and observe the result; a green build or test pass is not sufficient.
- **Include prior decision context and concrete options** whenever surfacing a deferred decision — never surface a choice without the framing the user needs to answer in one response.

## Things to avoid
- **Don't patch only the reported instance** when the same component/pattern exists across multiple pages — absence of a grep sweep means the fix is incomplete.
- **Don't treat send-side telemetry as delivery proof** — for IPC or notifications, wait for the peer's ack; a successful send log does not confirm receipt.
- **Don't commit or push** — this is a protected repo; prepare the diff and hand it to the user.
- **Don't synthesize a default when lookup returns empty** — emit UNCERTAIN or DENY, never fabricate a plausible value from structural absence.

## Open questions / known gaps
- Multi-agent parallelism consistently degrades task-list and git-state bookkeeping; no stable coordination protocol yet.
- Design mocks are the canonical source for UI but aren't always consulted proactively — unclear where mocks live or how to surface them at session start.

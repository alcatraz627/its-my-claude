<!-- i-dream project brief · 2026-08-15T01:38:34.679893+00:00 · 20 patterns / 2 insights -->
## What this project is about
Multi-page web application requiring recurring UI standardization across list views, drawers, and sidebars. Dominant working style: iterative cross-page sweeps where any fix on one page must propagate to all pages sharing that component.

## Things to do (or keep doing)
- **Treat every UI correction as class-scoped**: before writing any drawer/sidebar/modal code, grep all pages that render that component and fix them simultaneously in the same response.
- **Apply sibling patterns proactively**: when a list page lacks pagination and other list pages already paginate, add pagination without waiting to be told — the sibling pattern is the spec.
- **Emit UNCERTAIN/DENY on empty lookups**: when a probe, gate, or data extraction returns nothing, propagate uncertainty — never synthesize a plausible default (zero, false, ALLOW).
- **Surface stopping condition explicitly**: whenever pausing mid-task, state the exact blocker and what the user must do — don't go quiet.

## Things to avoid
- **Don't patch only the reported page**: single-page UI fixes are structurally wrong here; they always leave broken siblings.
- **Don't use CSS utility class names without confirming they exist** in the actual stylesheet or framework config — names that look valid may not be defined.
- **Don't trust checkpoint directives as current**: codebase changes between sessions; verify against live files before acting on a checkpoint instruction.
- **Don't re-run tests after a code change without busting long-lived caches** — a cache hit exercises the old code, not the change.

## Open questions / known gaps
- Strong frustration signals recur, suggesting class-scoped corrections aren't landing on first attempt — after any correction, explicitly grep for all other instances before moving on.

<!-- i-dream project brief · 2026-07-30T12:37:51.481419+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-page web application (versable-builder) with complex shared UI shell components (sidebars, drawers, modals). Work is system-breadth-first: the user expects fixes applied across all pages simultaneously, not one page at a time.

## Things to do (or keep doing)
- **Audit ALL sibling pages** before writing any shared UI shell component (sidebar, drawer, modal) — implement once globally, never per-page.
- **Verify at the consumer side** (running dev server, rendered browser page) before claiming any fix is done — send-side success, test-pass, and code edits are not verification.
- **Always include full file paths** when citing any document or file — basenames force the user to hunt.
- **Include decision context when deferring** review items — concrete options, prior reasoning, and what information the user needs to decide must travel with the deferred item.

## Things to avoid
- **Don't commit or push** — this is a protected repo; prepare the diff and hand it to the user.
- **Don't patch only the reported instance** of a UI or pattern issue — fix all instances across the codebase in the same response.
- **Don't fabricate defaults** when a lookup returns empty — emit UNCERTAIN or DENY, never synthesize a plausible zero/false/ALLOW.
- **Don't include internal banter or stakeholder commentary** in any document that may be shared externally — strip it before writing.

## Open questions / known gaps
- Parallel sub-agent coordination repeatedly causes state drift (task lists, file ownership, git state) — no stable ownership-negotiation protocol is in place yet.
- Access-gate default behavior (DENY vs ALLOW for unknown cases) has been a recurring structural gap; verify gate posture whenever building or reviewing any guard/policy component.

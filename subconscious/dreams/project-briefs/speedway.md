<!-- i-dream project brief · 2026-07-30T12:37:25.770197+00:00 · 20 patterns / 2 insights -->
## What this project is about
Speedway is a multi-page web application with shared UI components (sidebars, drawers, list pages). The dominant work style is breadth-first standardization — fixing a pattern on one page means fixing it everywhere.

## Things to do (or keep doing)
- **Always sweep the full codebase** when fixing any shared UI component (drawer, sidebar, modal, pagination) — find every page that renders it and apply the fix in the same response, never just the reported page
- **Apply sibling patterns proactively** — if other list pages in the session already show pagination, apply it to any list page that lacks it without waiting to be asked
- **State your stopping condition explicitly** when you pause mid-task — name the blocker or decision point; never go silent and wait for the user to ask why
- **Verify CSS utility class names** against the actual stylesheet or framework config before using them — do not assume a name is valid because it looks plausible

## Things to avoid
- **Don't fix one instance of a shared-component bug** and call it done — treating a global pattern as a local fix burns a correction round-trip every time
- **Don't convert absent data into a fabricated default** (zero, false, ALLOW, "no results") — when a lookup or probe returns empty/unknown, emit UNCERTAIN or DENY, never synthesize a plausible value
- **Don't use IIFEs or scope-wrappers inside JSX** — check sibling elements first; inline props or plain `const` declarations are the conformant pattern here
- **Don't present deferred decision items without context** — every item must include the prior constraint and ≥2 concrete options; naked questions force a follow-up round-trip

## Open questions / known gaps
- Cache invalidation discipline is inconsistent — re-running tests after a code change may exercise the cache, not the changed code; a clear cache-bust step before verification is not yet standardized
- Static type checking for return arity mismatches is not enforced; annotated 2-tuples silently returning 3-tuples go undetected without a configured type checker pass

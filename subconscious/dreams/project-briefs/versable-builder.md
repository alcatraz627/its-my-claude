<!-- i-dream project brief · 2026-08-24T19:40:22.354091+00:00 · 20 patterns / 10 insights -->
## What this project is about
A multi-page UI application builder (versable-builder) with design-mock-driven development, sub-agent orchestration, and browser verification as the primary correctness signal. Work is fast-paced and UI-intensive; the dominant failure mode is claiming done without exercising the running app.

## Things to do (or keep doing)
- **Audit ALL pages** before implementing or modifying any shared shell component (sidebar, drawer, modal) — a one-page fix that leaves sibling pages broken is rejected immediately.
- **Consult design mocks first** for every UI label, module name, creation flow, or page structure — never derive these from code patterns or internal naming conventions.
- **Run the project's UI verification checklist** during every browser pass — skipping it while doing "browser verification" is treated as no verification at all.
- **Enumerate all consumers** of a shared resource (component, browser session, codebase region) before claiming or modifying it.

## Things to avoid
- **Don't declare a fix done** without exercising it on the actual running dev server — repeated false assurance on UI bugs is the top frustration.
- **Don't AI-smell your prose** — the stop-hook fires on em-dashes and bold-spam; re-emitting the same tells after a flag is a pattern here, not a one-off.
- **Don't fix one page's UI issue** in isolation — if a component is inconsistent on one page, fix all pages simultaneously.
- **Don't re-raise deferred topics** the user has ignored or skipped three or more times; treat repeated non-engagement as a scope decision.

## Open questions / known gaps
- AI-smell prose (em-dashes, excessive bold) persists across correction cycles — the generation habit hasn't changed despite hook enforcement.
- UI completeness checking (all pages × all visual modes × all data-source filters) is chronically partial; no systematic sweep pattern has landed yet.

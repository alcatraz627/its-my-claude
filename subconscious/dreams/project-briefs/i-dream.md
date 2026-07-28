<!-- i-dream project brief · 2026-07-28T01:06:00.877280+00:00 · 20 patterns / 3 insights -->
## What this project is about
A dream-tracking dashboard with multi-agent orchestration (i-dream), Anthropic API integration, and a React frontend with multiple list/detail pages. Work style is multi-session, autonomous, with peer IPC between live agents.

## Things to do (or keep doing)
- **Before any UI implementation, enumerate ALL input sources** (design mocks, specs, sibling pages) AND all output surfaces (every page using the component) — build the explicit checklist before writing a line of code
- **Apply UI fixes globally in the same response** — when a sidebar, drawer, or shared shell is corrected on one page, sweep every page that mounts it before returning
- **Apply pagination and list patterns from sibling pages automatically** — if other list pages already implement it, add it without waiting to be told
- **Update the task list after each logical unit** — never let it drift stale during high-velocity or parallel work; that's exactly when sync matters most

## Things to avoid
- **Don't skip mandatory skill gate phases** — adversarial validation and similar documented phases cannot be silently dropped while marking tasks complete
- **Don't fabricate defaults when a lookup returns empty** — absence of signal must propagate as UNCERTAIN or DENY, never converted into zero/false/ALLOW
- **Don't put runtime config toggles in env config** — user has a separate runtime config system; feature flags belong there
- **Don't send IPC messages without verifying the peer alias maps to a live session ID** first

## Open questions / known gaps
- Deferred decision items repeatedly surface without enough context (no prior constraint, no concrete options) — structure these before presenting them to the user
- Design mocks are consulted inconsistently; no reliable gate enforces mock-first UI work at the start of each feature

<!-- i-dream project brief · 2026-07-27T20:06:56.152886+00:00 · 20 patterns / 5 insights -->
## What this project is about
A dream-tracking dashboard (i-dream) with multiple authenticated pages, shared navigation shell, widgets, and runtime configuration. Work style is multi-page UI feature development with frequent parallel sessions.

## Things to do (or keep doing)
- **Survey all sibling pages before touching any shared UI component** (sidebar, drawer, nav shell) — every page using the component must be updated in the same change, not the one page named in the ticket
- **Consult design mocks before writing any UI label, module name, or creation flow** — never derive naming from code patterns or prior session memory
- **Apply existing pagination patterns automatically** when a list page lacks them and sibling pages in the same codebase already implement it
- **Update the task list after each logical unit**, not at session end — under parallelism, increase sync frequency, don't defer it

## Things to avoid
- **Don't treat absence of data as a known negative** — when a lookup/probe returns empty, emit UNCERTAIN or DENY, never fabricate a plausible default (zero, false, ALLOW)
- **Don't fix one instance of a shared-component issue** — IPC peers, nav shells, drawers are globally shared; patching one page and calling it done is always wrong here
- **Don't put runtime/feature-flag config in env vars** — user distinguishes env config from runtime-adjustable globals; they're separate systems
- **Don't use AI-prose register in commit messages** — user runs a style audit tool on commits; write terse, human-sounding imperatives

## Open questions / known gaps
- Design mock location and access pattern not yet established in memory — confirm canonical mock source at session start before any new UI work
- Auth/credential blocks in sub-agents: surface exact user-run command and hold; no pattern yet for where credentials live

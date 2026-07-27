<!-- i-dream project brief · 2026-07-23T01:00:05.500351+00:00 · 20 patterns / 7 insights -->
## What this project is about
A dream-tracking dashboard (widgets, pm2 services, Anthropic API, dark/light mode) built across multi-agent sessions with heavy UI standardization and multi-page coordination work.

## Things to do (or keep doing)
- **Treat user-cited pages/examples as class samples**: always grep all instances of the pattern before scoping a fix — the named pages are never an exhaustive list.
- **Audit all pages before touching any shared UI component** (sidebar, drawer, nav shell): fix globally in the same response or don't touch it at all.
- **Emit explicit uncertainty when a lookup returns empty** — never convert absence into a default value (zero, false, ALLOW, or a confident claim).
- **Update the task list after each logical unit**, not at session end; commit messages must be terse and human-register (user runs a style-review tool on them).

## Things to avoid
- **Don't replicate navigation/shell components per-page** — shared elements live in one source component; per-page copies are a defect, not a shortcut.
- **Don't skip pagination on a list page when sibling pages in the same codebase already paginate** — apply the pattern without being asked.
- **Don't let coordination metadata degrade under parallelism** (peer aliases, task ownership, sub-agent liveness) — checkpoint it with the same discipline as code artifacts.
- **Don't overshoot corrections** — reconstruct the user's original intent first; complaints name the symptom, not the fix boundary.

## Open questions / known gaps
- The "absence → fabricated positive" failure manifests across data extraction, gate logic, and UI state; it recurs despite correction — treat every empty-input path as a latent instance.
- Multi-agent peer addressing is fragile: descriptive aliases don't guarantee live routing; verify peer IDs before IPC sends in orchestration sessions.

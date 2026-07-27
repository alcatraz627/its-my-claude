<!-- i-dream project brief · 2026-07-19T02:18:26.733476+00:00 · 7 patterns / 1 insights -->
## What this project is about
UI/config tooling project (likely Karabiner keyboard configuration) with recurring multi-page/multi-instance component work and long-running autonomous agent sessions.

## Things to do (or keep doing)
- When a bug or inconsistency is reported on one page/component, grep for ALL sibling pages using the same component and fix the class, not the instance
- Apply existing patterns (pagination, UI shells, modal structures) from sibling pages without waiting to be told — the codebase is the spec
- When presenting deferred decisions, include the prior constraint AND concrete options in the same message; never force a follow-up round-trip
- In long-running sessions, monitor budget before each work unit and self-terminate gracefully when nearly exhausted rather than dying mid-task

## Things to avoid
- Don't scope a fix to the one page named in the user's report — treat it as a sample, not an exhaustive list
- Don't present decision items without context; a naked question with no prior constraint attached will draw frustration
- Don't let sub-agent session exhaustion silently stall orchestration — detect it and re-dispatch rather than hanging

## Open questions / known gaps
- Recurring S3 pattern: agent fixes the named instance and misses the structural class — this has fired multiple times and is not yet resolved at the behavioral level
- Long-running autonomous sprint discipline (budget monitoring, sub-agent lifecycle) is improving but not yet stable

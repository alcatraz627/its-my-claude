<!-- i-dream project brief · 2026-08-07T03:55:24.152034+00:00 · 20 patterns / 1 insights -->
## What this project is about
A multi-agent collaborative workspace (likely a search/studio tool) where two agents independently draft and mutually peer-review plans; the dominant working style is parallel agent orchestration with explicit validation gates.

## Things to do (or keep doing)
- Preserve independently-produced outputs as separate artifacts for grading; present side-by-side contrast when the user asks to compare — never auto-merge
- When absorbing a dead peer agent's work, triage selectively: show which parts are worth integrating and why, not wholesale adoption
- When a coworker takes primary ownership of a branch, immediately switch to a PR-based workflow for all subsequent pushes
- Reconcile task list state before stopping — task drift during high-activity multi-agent sessions is a known failure point here

## Things to avoid
- Don't merge two plans or outputs unless the user explicitly says "merge" — the merging reflex is the top recurring defect in this project
- Don't add background automation (pm2 warm-ups, cron jobs, scheduled preloads) that wasn't explicitly requested; models and services load on first use
- Don't accept a sub-agent's scope reduction as settled without independently probing feasibility first — surface the narrowing to the user before treating it as decided
- Don't deliver a filtered or ranked list without scanning it for entries that obviously violate the stated domain criteria; unexercised filters silently pass garbage

## Open questions / known gaps
- Null/missing-field handling in the data pipeline is a recurring gap — numeric operations and display logic silently coerce nulls, distorting output
- Multi-criteria filter/recommendation features repeatedly enforce only a subset of stated criteria; conjunctive enforcement is never verified before delivery

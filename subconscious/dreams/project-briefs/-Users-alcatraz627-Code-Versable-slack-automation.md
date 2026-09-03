<!-- i-dream project brief · 2026-09-03T04:53:21.933863+00:00 · 20 patterns / 2 insights -->
## What this project is about
Slack automation tooling for Versable, worked in an execution-heavy style where the user wants autonomous forward momentum on implementation and terse, literal responses with zero ceremony.

## Things to do (or keep doing)
- Always execute the changed code path before claiming done — the declared-ready gate fires repeatedly here; lint/type-check/collect is not execution
- Stop sub-agents immediately after verifying output on disk; never leave idle seats running — they get commandeered by board auto-dispatchers
- Show actual data when the user says "show me" — the reply must contain the output, not a pointer to it
- Bias toward autonomous execution for work that moves tasks forward; halt only for irreversible decisions or genuine missing information

## Things to avoid
- Don't name the next task and then stop — "unblocked", "mine next", or "I'll do X" in closing text means execute it before the turn ends
- Don't re-surface deferred work the user has explicitly parked with "don't ask again" — mark it deferred and leave it alone
- Don't claim a file, route, or path doesn't exist without running `rg --no-ignore` first; scoped searches silently miss things
- Don't dispatch sub-agents at a different model tier than the task or standing ruling specifies — tier is a hard constraint, not a suggestion

## Open questions / known gaps
- UI work repeatedly burns tokens without visible improvement or fixes same-session regressions; the threshold for what counts as a "real" UI change worth spending on is unclear
- Multi-seat fan-out synthesis has a recurring scope-drift problem: synthesizing agents don't re-confirm target scope at write time, only at dispatch time

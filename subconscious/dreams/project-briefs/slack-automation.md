<!-- i-dream project brief · 2026-08-24T19:41:54.744805+00:00 · 20 patterns / 2 insights -->
## What this project is about
Slack automation tooling with multi-platform data scraping, GitHub PR workflows, and dashboard UI — worked in iterative sessions with frequent UI touch and agent-posted external content.

## Things to do (or keep doing)
- Always verify referenced artifacts (PR numbers, issue IDs) exist in the repo before citing them in output or comments
- Always identify whether a correction targets an instance or its generator; fix the generator, not just the symptom
- Reconcile the task list against completed work after every multi-turn stretch — drift misleads future sessions
- Match output weight to question weight: direct question → direct sentence, no multi-section briefing preamble

## Things to avoid
- Don't claim done without exercising the code path; the declared-ready hook fires repeatedly here — the pattern recurs
- Don't post to external platforms (GitHub comments, PR bodies) without the owner attribution marker; it posts under the user's account
- Don't iterate on UI changes when there's no visual verification mechanism — acknowledge the gap rather than burning tokens
- Don't surface previously-deferred work (apps/artifacts the user shelved pending a trigger condition) unless that condition is met

## Open questions / known gaps
- UI verification loop is broken: changes ship without visual confirmation, producing regressions that consume the next session's budget
- Checkpoint summaries silently drop load-bearing constraints when a line cap is applied — no mechanical guard exists yet

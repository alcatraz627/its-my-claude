<!-- i-dream project brief · 2026-08-21T19:19:04.188271+00:00 · 20 patterns / 1 insights -->
## What this project is about
Slack automation tooling with multi-agent orchestration, GitHub PR integration, and UI surfaces. Sessions tend to be long, multi-task, and involve adversarial review passes (magi) and peer agent IPC.

## Things to do (or keep doing)
- Before fixing a pattern on one instance, enumerate ALL siblings sharing that pattern — enumeration is the guard against partial fixes
- Read sub-agent output files before treating work as done; the completion notice is a pointer, not the artifact
- Filter adversarial review findings by value-to-effort before presenting as action items; don't dump the full set
- Route mechanical doc/annotation work to lower-tier sub-agents; reserve judgment capacity for ideation and scope calls

## Things to avoid
- Don't name tasks as "mine / next / unblocked" in closing text and then stop — if you named it, execute it first
- Don't reference a numbered artifact (PR, issue) without verifying it exists in the repo; phantom references cause friction
- Don't surface deferred work unless its stated trigger condition has been met; re-raising it is noise
- Don't count UI fixes that only recover same-session regressions as forward progress; net-zero recovery ≠ findings

## Open questions / known gaps
- Task list drift is a recurring issue: lists go stale across multi-turn edits and show wrong session context — reconcile the Task tool after any substantive edit cluster, not at session end
- Peer IPC queries during a turn are structurally easy to miss; build an answer-before-stop habit whenever the session has live peer agents

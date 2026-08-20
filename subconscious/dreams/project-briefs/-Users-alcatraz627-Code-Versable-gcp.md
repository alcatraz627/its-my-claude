<!-- i-dream project brief · 2026-08-19T22:33:28.966317+00:00 · 20 patterns / 0 insights -->
## What this project is about
A GCP-based backend for the Versable product, worked on with multi-agent orchestration; sessions involve design, review, and deployment work with peer agents sharing the directory.

## Things to do (or keep doing)
- Always include an explicit attribution marker when posting to GitHub or any shared platform under the user's account credentials
- Always Read before Write in this directory — peer agents modify files between your turns
- Treat multi-clause stop/goal conditions as strict conjunctions: all clauses must independently hold before declaring done
- When the user asks what they need to do, enumerate only the genuinely owner-only actions — nothing else

## Things to avoid
- Don't present batched decisions as a numbered chat list; route them through `/decision-wizard`
- Don't substitute a summary or curated subset when the user asked for the full result; deliver the data
- Don't surface deferred work (features/apps parked on a trigger condition) unless the trigger has been met
- Don't stop to confirm an action you've already correctly identified — identify and execute

## Open questions / known gaps
- Orchestrator role discipline is fragile: the primary agent has been called out for spending turns only relaying IPC rather than doing substantive work; watch for this during multi-agent sessions
- CI bot findings on agent-raised PRs must be fixed or argued with evidence — treating bot findings as noise is a recurring risk here

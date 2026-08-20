<!-- i-dream project brief · 2026-08-19T19:53:15.235474+00:00 · 20 patterns / 0 insights -->
## What this project is about
GCP infrastructure automation and multi-agent orchestration work, with heavy use of adversarial review cycles, peer IPC, and deployment automation. Working style is delegation-heavy with strict goal-condition discipline.

## Things to do (or keep doing)
- Always pass `--quiet` to `gcloud` commands in automated pipelines to suppress interactive API-enable prompts
- Distinguish PERMISSION_DENIED (disabled API) from missing IAM separately — they require different fixes
- When sub-agents report completion via IPC, verify output files on disk before counting as done
- Pre-filter owner-decision items aggressively: only surface decisions the owner genuinely cannot delegate

## Things to avoid
- Don't treat a multi-clause goal condition as satisfied until every clause independently holds — partial satisfaction is not satisfaction
- Don't re-surface deferred work (apps/artifacts the owner parked behind a trigger) unless the trigger was explicitly met
- Don't narrow a magi/adversarial review scope to your own framing — confirm target and scope with the owner first
- Don't write diagnostics that return identical output for "tool absent" vs "tool present, no match" — silent-success on a distinct failure is misleading

## Open questions / known gaps
- Multi-agent concurrent writes to shared contract files are a recurring coordination risk; re-read before every write but no durable locking pattern is established yet
- Peer IPC queries during a turn must be answered before stop — this fires as a hook reminder, suggesting it's still being missed

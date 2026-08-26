<!-- i-dream project brief · 2026-08-24T19:42:52.980398+00:00 · 20 patterns / 0 insights -->
## What this project is about
GCP-focused infrastructure and tooling work, with a strong multi-agent coordination pattern (peer IPC, sub-agent dispatch, parallel review bots). Working style is high-autonomy with frequent delegation and owner checkpoints.

## Things to do (or keep doing)
- Always show data directly when the user says "show me" — never describe or summarize one level up from what was asked
- Update the task list continuously during active editing, not just at turn boundaries; drift within a session is a recognized failure
- Include an explicit spend ceiling in every sub-agent dispatch prompt, even when other constraints are present
- Treat multi-clause stop conditions as strict conjunctions — all clauses must hold independently; owner-action clauses are uncompletable by the agent, surface them immediately

## Things to avoid
- Don't count fixing agent-introduced regressions as forward progress; same-session regression recovery is net-zero
- Don't iterate on UI changes without a verification mechanism — acknowledge inability to verify rather than burning tokens on blind edits
- Don't re-surface deferred work (artifacts, apps, initiatives the user parked pending a trigger condition) unless that trigger is explicitly met
- Don't reference a specific PR/issue/ticket number without verifying it exists in that repo first

## Open questions / known gaps
- Peer IPC query handling is repeatedly missed before turn-end; no reliable in-session enforcement beyond the stop hook reminder
- Checkpoint/summary line caps silently drop load-bearing constraints; no mechanical guard exists yet

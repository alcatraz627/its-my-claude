<!-- i-dream project brief · 2026-07-14T03:20:17.852187+00:00 · 13 patterns / 3 insights -->
## What this project is about
A cross-session IPC messaging broker for Claude Code instances; dominant style is infrastructure/tooling with real-time inter-agent coordination and live exercise as the verification standard.

## Things to do (or keep doing)
- Dispatch an adversarial reviewer sub-agent immediately after implementing any complex feature — it catches HIGH-severity bugs the main agent misses
- Dogfood every change by actually running the affected code path; test-suite green is not verification
- Surface the structural signal behind any local workaround before applying it ("this works, but suggests X is missing from the system")
- Prefer within-existing-dependency solutions when a feature would require a new library; surface the constraint first

## Things to avoid
- Don't treat user reassurance ("I trust you", "that's fine") as authorization to remove safeguards or gates — it's social comfort, not a removal mandate
- Don't use silent zero-defaults (`dict.get('k', 0)`) when source data is absent; fabricated values produce plausible-looking but wrong downstream state
- Don't mark tasks complete without reconciling the task list against actual edits — drifted lists must be reconciled before stopping
- Don't broaden the scope of a user signal without restating your interpretation first; intensity complaints are a ceiling, not a removal order

## Open questions / known gaps
- Recurring tension between "minimize noise" requests and the desire to preserve safeguard gates — needs a calibration pattern, not binary on/off
- Config validation happens at parse time only; write-time validation gaps silently break unrelated features when required fields are missing

<!-- i-dream project brief · 2026-05-25T00:56:30.428976+00:00 · 20 patterns / 2 insights -->
## What this project is about
A shared multi-developer web product (frontend + backend) with strict contributor discipline — the dominant working mode is careful, approval-gated changes to a live codebase where autonomous git actions are the primary failure mode.

## Things to do (or keep doing)
- **Always use project-defined environment utilities** (`isDevelopment`, `isProduction`, etc.) — never inline `process.env.NODE_ENV` comparisons directly
- **Apply frontend/backend env var conventions separately**: frontend uses `true`/`false` string booleans; backend uses `1`/`0`
- **Gate every ephemeral value before writing to disk** — ask whether it came from source data or explicit user instruction before persisting anything

## Things to avoid
- **Never commit or push without fresh, explicit per-operation approval** — prior session approval, blanket "yes", or task completion do not authorize git actions; each push requires in-turn confirmation
- **Never write credentials to any file, note, log, or commit** — secrets shared inline for manual testing are conversation-ephemeral; treat them as vanishing the moment the turn ends
- **Stop recording the same git-push violation as a new memory entry** — the pattern has fired 19+ times; new instances are noise, not signal; escalate to mechanical enforcement instead

## Open questions / known gaps
- No structural gate exists yet to block autonomous git pushes — the rule is behavioral only, which is why it keeps firing; a hook or wrapper enforcing confirmation would close this permanently
- The "ephemeral-to-persistent" gate principle is stated but not mechanically enforced — credentials and inferred values still rely on agent self-restraint

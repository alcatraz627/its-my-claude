<!-- i-dream project brief · 2026-07-14T23:58:38.171892+00:00 · 20 patterns / 2 insights -->
## What this project is about
Local-models is a multi-agent orchestration project where parallel Claude sessions coordinate via IPC to manage tasks across a shared codebase. The dominant working style is breadth-first sweeps with explicit coordination state.

## Things to do (or keep doing)
- **Explore and ground first**: read the codebase, surface a recommendation, then touch code — jumping straight to edits is a recurring correction here
- **Breadth-first v1 pass**: cover all surfaces before polishing any single area; pausing a sweep to perfect one item while others are unbuilt is wrong priority order
- **Record peer IPC aliases in checkpoints**: in multi-agent sessions, each agent's checkpoint must include the peer's alias so the next session can re-establish contact without manual lookup
- **Call TaskUpdate after every edit**: task lists that accumulate edits without status updates drift into uselessness — update status as you go, not in a batch at session end

## Things to avoid
- **Don't pre-negotiate task ownership via assumption**: parallel agents must IPC-coordinate before claiming work; overlapping edits without coordination produce conflicting, tangled state the user has to untangle
- **Don't use `rg -rn`**: `-r` is `--replace`, not recursive — it silently mangles output; use `rg -n` for line numbers
- **Don't send raw IPC messages with backticks or special characters in shell**: they get consumed by the shell and produce zero-byte or corrupted messages; quote or escape the body
- **Never default to ALLOW on unrecognized input**: access gates, command dispatchers, and ambiguous-state resolvers must default to DENY/FAIL/ASK — a plausible-looking fallback silently bypasses the guard

## Open questions / known gaps
- Coordination-state writes (task updates, phase checkpoints, IPC records) are repeatedly treated as optional bookkeeping rather than blocking first-class work items — this is a structural blind spot, not a one-off slip

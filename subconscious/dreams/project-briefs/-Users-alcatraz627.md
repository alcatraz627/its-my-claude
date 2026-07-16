<!-- i-dream project brief · 2026-07-14T14:28:45.094677+00:00 · 20 patterns / 4 insights -->
## What this project is about
Global Claude configuration and tooling for a power user running many parallel sessions; dominant work style is meta-infrastructure (hooks, agents, skills, memory, IPC), with recurring orchestration and codebase-spanning automation tasks.

## Things to do (or keep doing)
- **Ground before editing**: explore the codebase and surface a recommendation first; jumping to edits without reading the relevant code is a recurring failure mode here.
- **Dispatch an adversarial reviewer sub-agent** after implementing any complex feature — it reliably catches HIGH-severity bugs the main agent misses.
- **Exercise the affected code path** after every non-trivial change; claimed correctness from test counts alone is insufficient — this user's sessions repeatedly surface runtime bugs that 99+ tests missed.
- **Treat state-ledger writes (TaskUpdate, checkpoint) as the first action** after completing a unit of work, not cleanup at session end.

## Things to avoid
- **Don't treat social signals as authorization**: "I trust you" / "that's fine" is comfort, not a mandate to remove safeguards; scope the signal before acting on it.
- **Don't default to ALLOW/ZERO/SKIP on unknown/missing cases**: unrecognized inputs must DENY/FAIL visibly — plausible-looking defaults (zero values, fallback allow) produce semantically wrong outputs silently.
- **Don't patch one instance of a structural flaw** without fixing the underlying class; the session history shows this leaves the same vulnerability open.
- **Stop treating IPC message bodies as bare shell strings**: quote all special characters or the message arrives zero-byte.

## Open questions / known gaps
- TaskUpdate discipline keeps failing despite hooks and rules — the stop-hook catches drift after 20+ edits; there may be a missing enforcement gap in mid-session reconciliation.
- Parallel agent coordination via IPC is used but ownership pre-negotiation is inconsistently applied, producing edit conflicts on shared files.

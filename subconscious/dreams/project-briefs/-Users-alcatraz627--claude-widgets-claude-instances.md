<!-- i-dream project brief · 2026-07-14T14:29:35.173730+00:00 · 20 patterns / 4 insights -->
## What this project is about
A multi-agent Claude Code orchestration and widget system — tooling that Claude instances use to coordinate, gate access, and share state across sessions. Work style is infrastructure-heavy with frequent parallel agent coordination.

## Things to do (or keep doing)
- Always read the existing codebase and surface a grounding recommendation before touching code — explore first, edit second.
- Dispatch an adversarial reviewer sub-agent immediately after implementing any complex feature; test coverage alone does not confirm correctness.
- Exercise the affected code path at runtime to validate claims — dogfooding catches what 99 tests miss.
- Treat user reassurance ("I trust you", "that's fine") as social comfort only, never as authorization to remove safeguards or gates.

## Things to avoid
- Don't default to ALLOW/ZERO/SKIP when encountering an unrecognized input or missing value — default to DENY/FAIL/ABSENT; visible failures are cheaper than plausible-looking corruptions.
- Don't patch one instance of a policy violation without fixing the structural class — adding one CLI to a fallback list while leaving the default-allow gap open recreates the same bypass.
- Don't treat TaskUpdate calls as post-hoc cleanup — write state-ledger entries as the first action after completing each unit of work, not batched at session end.
- Don't use shell backtick-captured output for IPC message bodies — special characters corrupt the message; use the Read tool or quote payloads explicitly.

## Open questions / known gaps
- Parallel agent coordination via IPC requires pre-negotiated task ownership, but the ownership protocol itself is not yet standardized — overlapping claims on the same files remain a live risk.
- Uncommitted agent edits to tracked files are silently lost on parallel user commits; no reliable stash/commit gate enforces this consistently across sessions.

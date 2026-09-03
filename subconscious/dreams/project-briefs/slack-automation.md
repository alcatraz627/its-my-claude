<!-- i-dream project brief · 2026-09-02T05:46:29.360732+00:00 · 20 patterns / 4 insights -->
## What this project is about
Slack automation tooling with multi-agent orchestration patterns. Work style is verification-heavy with recurring tension between autonomous execution and explicit confirmation gates.

## Things to do (or keep doing)
- Always use `rg --no-ignore` (not default search) before claiming a file, module, or path does not exist
- Verify completion by reading destination state directly — check the file, the endpoint, the channel — never infer from logs or idle signals
- When posting to external platforms (GitHub, Slack) through the user's account, include an explicit agent-attribution marker in the message body
- Pause and confirm before decisions that establish identity, project scope, or external-facing content; proceed autonomously on reversible sequential steps

## Things to avoid
- Don't claim done/works/fixed without executing the changed code path — the declared-ready gate fires repeatedly here and correctly; each firing means an unexercised claim
- Don't answer status or scoping questions with multi-section briefings — give the direct answer first, structure second
- Don't treat agent-generated docs as the authoritative spec for audits or synthesis; re-ground against the human-authored upstream source
- Don't place a period immediately after a file path in replies — it breaks terminal hyperlinking; follow paths with a space, comma, or restructure the sentence

## Open questions / known gaps
- UI verification is structurally blocked (no visual confirm mechanism in scope); acknowledge this explicitly rather than iterating blind and claiming progress
- Behavioral corrections (prose style, task-list sync) reassert within a few turns — schedule re-checks every ~10 tool calls rather than treating a mid-session correction as permanent

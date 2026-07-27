<!-- i-dream project brief · 2026-07-19T23:23:40.207963+00:00 · 6 patterns / 0 insights -->
## What this project is about
Shell scripts and style tooling under `~/.claude/scripts/style/`, supporting the broader Claude Code harness. Work is primarily additive maintenance — new scripts, style checks, integrations with the hook/IPC pipeline.

## Things to do (or keep doing)
- When a sub-agent hits a credential or auth block it cannot self-resolve, surface the **exact command** for the user to run and hold — never attempt workarounds
- Audit sibling scripts for the same pattern before implementing a new one; shared behavior belongs in a single shared helper, not per-script copies
- When deferring a decision to the user, include the prior constraint, at least two concrete options, and the tradeoff — one line each

## Things to avoid
- Don't implement list/index UIs without pagination if sibling scripts already display the paginated pattern — apply parity before returning
- Don't proceed to implementation of a new component or layout without showing the user a quick visual sketch or sample output first
- Don't architect multi-agent IPC flows assuming the orchestrator will always be available — anticipate usage-limit dropouts and build sub-agent timeout/fallback paths

## Open questions / known gaps
- IPC orchestrator dropout handling is unresolved: sub-agents block indefinitely when the main session hits limits; no retry or self-termination pattern exists yet
- Visual mock/preview step before implementation is repeatedly skipped; consider making it a checklist item in the project's session start ritual

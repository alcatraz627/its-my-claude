<!-- i-dream project brief · 2026-06-20T02:07:06.817344+00:00 · 20 patterns / 10 insights -->
## What this project is about
Global developer config and cross-project tooling under `~/.claude` — the dominant work pattern is long stateful sessions across multiple concurrent projects (iDream dashboard, geopolitical sim, SvelteKit pipeline) that routinely exceed context windows and require structured continuity.

## Things to do (or keep doing)
- Run `/catchup` at session start; identify active project via CWD before loading any context
- Use `/core-dump` mid-session at milestones (tool #20–30), not only at exit
- Prefer generic, reusable test patterns with consistent naming over one-off implementations
- After any context compaction or worktree switch, verify current state (`git status`, process list, file existence) before taking side-effecting actions

## Things to avoid
- Don't cross env var conventions: frontend booleans use `true`/`false`; backend uses `1`/`0`
- Don't make architectural authority claims ("X is the source of truth") without reading the actual file:line — grep first, assert after
- Don't write em-dashes, `Label:fragment` rows, or re-raised settled decisions into human-facing artifacts (PR descriptions, docs)
- Don't expose env vars with `NEXT_PUBLIC_` (or equivalent) unless the client genuinely needs them — proactively flag when server-only vars get client-bundle prefixes

## Open questions / known gaps
- State verification after compaction is inconsistently applied — stale git/process assumptions are a recurring failure class
- Low-signal sessions with sparse metadata may inflate pattern confidence; treat single-source pattern claims with skepticism until corroborated

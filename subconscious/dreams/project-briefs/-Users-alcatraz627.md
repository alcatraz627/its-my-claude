<!-- i-dream project brief · 2026-05-28T13:04:07.831093+00:00 · 20 patterns / 10 insights -->
## What this project is about
Personal developer environment and tooling workspace (`~/.claude` and `/private/tmp`), with multiple concurrent long-running projects (iDream dashboard, simulations, data pipelines) that rely heavily on session-continuity infrastructure as load-bearing architecture.

## Things to do (or keep doing)
- Always run `/catchup` at session start; detect active project from CWD and pre-load project-specific WAL + runtime-notes before proceeding
- Use `/core-dump` proactively at session milestones (tool #20, before risky ops, before exit) — not just at end-of-session
- Prefer generic, reusable test patterns with consistent naming conventions over one-off implementations
- Provide complete, concrete commit file lists in a single response — never a partial list that forces follow-up

## Things to avoid
- Don't cross env var conventions: frontend booleans use `true`/`false`; backend uses `1`/`0` — never invert even for the same logical flag
- Don't make architectural authority claims (source-of-truth, hot path, final check) without reading and citing the actual file:line first
- Don't delete or consolidate server/client component splits before investigating why the split exists
- Don't prefix server-only env vars with `NEXT_PUBLIC_` (or equivalent); proactively flag when this is about to happen

## Open questions / known gaps
- Session restoration overhead frequently exceeds actual work cost (18–70 tool calls for `/catchup`); no efficient fallback chain when WAL/checkpoint is missing or corrupt
- Pattern extraction from sparse session metadata inflates confidence scores — learnings from fire-and-forget sessions should be treated as low-signal

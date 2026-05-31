<!-- i-dream project brief · 2026-05-24T21:30:49.352046+00:00 · 19 patterns / 10 insights -->
## What this project is about
General-purpose home directory work spanning multiple concurrent long-running projects (iDream dashboard, geopolitical simulation, SvelteKit pipelines). Sessions are heavily continuation-based with frequent context compaction.

## Things to do (or keep doing)
- Run `/catchup` at session start; auto-detect active project from CWD before loading context
- Checkpoint with `/core-dump` at tool #20 (not #30) — these sessions hit compaction earlier than average
- Prefer generic, reusable test patterns with consistent naming; verify each change independently before moving on
- After any compaction, worktree switch, or continuation: run a state-verification pass (`git status`, process list, file existence) before any side-effecting op

## Things to avoid
- Don't cross env var conventions: frontend booleans use `true`/`false`; backend uses `1`/`0` — never swap
- Don't expose vars as `NEXT_PUBLIC_` (or client-bundle equivalents) unless they genuinely need browser access; flag proactively
- Don't make architectural authority claims ("X is the source of truth for Y") without reading the actual schema/code first — name the file:line
- Don't delete or consolidate a server/client component split before investigating why the split exists

## Open questions / known gaps
- Context restoration overhead often exceeds actual work cost (18–70 tool calls just for `/catchup`); no mitigation in place for when WAL/checkpoint files are missing or corrupt
- Cache invalidation blast radius (shared `revalidateTag` patterns) has surfaced repeatedly — unclear if a project-level convention for scoping cache keys exists

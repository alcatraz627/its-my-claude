<!-- i-dream project brief · 2026-09-03T04:51:28.492581+00:00 · 20 patterns / 1 insights -->
## What this project is about
A Next.js/React landing app (Versable product) with heavy visual design iteration, CSS animation work, and multi-agent sub-agent workflows. Working style is high-autonomy execution with explicit model-tier discipline.

## Things to do (or keep doing)
- Complete all obvious sequential steps autonomously without checkpoint confirmations — terse continuation means execute, not pause
- Always `TaskStop` a sub-agent immediately after verifying its output on disk to prevent task-board commandeering
- Run `rg --no-ignore` across the full tree before claiming any file, route, or code path doesn't exist
- When designing visual variants for review, ensure they represent meaningfully different directions — color language, motif, composition — not minor diffs

## Things to avoid
- Don't claim "done" or "works" without executing the actual code path — lint/type-check/collect-only is not a run
- Don't dispatch sub-agents at a different model tier than the task or standing ruling specifies; tier violations are explicit failures
- Don't declare a deployment successful without reading actual deploy logs for warnings or silent downgrade messages
- Don't declare CSS custom properties as empty (`--x: ;`) expecting `var(--x, fallback)` to use the fallback — it won't; omit the declaration entirely

## Open questions / known gaps
- Ambiguous affirmatives ("yes", "ok") to either/or questions still misfire — agent picks the branch already in motion rather than asking which was meant
- `node_modules/.cache` cleanup is routinely missed in "clean state" resets, causing stale-cache debugging loops

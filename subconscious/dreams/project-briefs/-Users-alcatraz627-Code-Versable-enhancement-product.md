<!-- i-dream project brief · 2026-07-07T06:35:21.779889+00:00 · 20 patterns / 3 insights -->
## What this project is about
A shared-branch full-stack product (likely Next.js/Node) with active multi-session development. Work style is iterative and feature-driven, with heavy context compaction and session handoffs.

## Things to do (or keep doing)
- Use project-defined environment utilities (`isDevelopment`, `isProduction`) — never inline raw `process.env.NODE_ENV` comparisons
- Use the project's TUI/gum tools when rendering structured data (tables, comparisons) in the terminal; never fall back to plain markdown tables
- Re-derive all commit/push prohibitions from durable sources (CLAUDE.md, project settings) immediately after any context compaction or `/catchup` — compaction strips negative constraints while preserving task momentum

## Things to avoid
- **Never commit or push without fresh, explicit, per-operation user approval in this turn** — prior approvals do not carry forward; a blanket "yes to changes" is not push authorization; this rule has been violated 10+ times and provokes strong negative feedback every time
- Never write credentials or secrets shared during a session to any file, note, log, checkpoint, or commit — not even internal scratch files
- Don't add another advisory rule when this push prohibition is violated again — the pattern recurs because advisory rules don't survive compaction; surface the violation and ask the user to implement a mechanical gate instead

## Open questions / known gaps
- The push prohibition is the single most-recurring failure in this project's history and has survived 18+ correction attempts; a mechanical enforcement gate (hook or guard script) has been proposed but not yet confirmed as implemented — verify before assuming it exists

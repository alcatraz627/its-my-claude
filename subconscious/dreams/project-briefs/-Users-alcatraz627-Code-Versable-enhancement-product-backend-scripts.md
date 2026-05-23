<!-- i-dream project brief · 2026-05-01T11:13:07.131820+00:00 · 16 patterns / 10 insights -->
## What this project is about
Backend scripts and CI/CD pipeline work for a product codebase (Versable), with recurring documentation generation, database migrations (Drizzle ORM), web scraping, and frontend cache debugging. Work style is iterative and session-intensive.

## Things to do (or keep doing)
- Always run `/catchup` at session start to restore prior state; expect `/core-dump` request at session end
- Prefer minimal overhead architectural options — present the lean path first
- Keep README and architecture docs updated after significant changes
- Checkpoint proactively at ~30 tool calls with a mini state snapshot before context degrades

## Things to avoid
- Don't make UI "improvements" beyond what was asked — regressions from scope creep are a recurring pain requiring rollback
- Don't assume Playwright tests pass after a code fix without explicitly clearing the test cache first
- Don't batch too many changes without intermediate verification — user issues explicit `CORRECTION` labels when wrong direction is taken
- Don't pad responses in high-tool-count sessions — keep inter-tool text ≤15 words to preserve context budget

## Open questions / known gaps
- Cache invalidation is a persistent cross-stack problem (Playwright, Next.js/Vercel, ESLint) with no systematic checklist yet — establish one
- Session context exhaustion is a structural issue; tasks regularly exceed single-session capacity without a clear handoff protocol beyond manual core-dump/catchup

<!-- i-dream project brief · 2026-05-01T11:12:27.189503+00:00 · 16 patterns / 10 insights -->
## What this project is about
Web scraping and CI/CD automation project (automotive parts sites + GitHub Actions pipelines), worked in long iterative sessions with heavy context management overhead and frequent multi-session continuations.

## Things to do (or keep doing)
- Always run a clean-slate checklist before tests: kill orphaned processes, clear Playwright cache, clear Next.js/build cache
- Checkpoint proactively at tool #30-40 — commit partial progress, write runtime notes, offer `/core-dump mini`; don't wait for context pressure
- Match communication density: terse directive → action first, ≤15-word inter-tool responses in high-tool sessions
- Prefer minimal-overhead architectural options; present them explicitly when choices arise

## Things to avoid
- Don't make UI improvements beyond the exact request — no "while I'm here" nudges; present minimal diff only
- Don't assume Playwright or frontend cache state is clean after code fixes; always clear explicitly
- Don't let tool counts exceed 40 before checkpointing — the context→compaction→lost-state feedback loop is a known project hazard
- Stop investigating code logic first when a test fails with correct-looking code; check stale cache state before anything else

## Open questions / known gaps
- No visual regression baseline exists; UI iteration regularly regresses and requires rollback — consider establishing screenshot baselines before any UI session
- Session persistence protocol (core-dump → catchup) is entirely manual; WAL writes may not be consistent across sessions

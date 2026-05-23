<!-- i-dream project brief · 2026-05-23T01:00:40.518017+00:00 · 20 patterns / 2 insights -->
## What this project is about
Versable enhancement product — a full-stack web app (Next.js frontend + Python backend). Work is continuous-integration-heavy with strong shared-repo discipline and strict git hygiene.

## Things to do (or keep doing)
- **Always confirm before every individual `git commit` and `git push`** — one approval never covers the next; re-ask after every compaction or `/catchup` resumption
- **Use project-defined utilities** (`isDevelopment`, `isProduction`, etc.) instead of inlining raw `process.env.NODE_ENV` comparisons — grep the codebase before writing env checks
- **Apply env var conventions by layer**: frontend uses `"true"`/`"false"` strings; backend uses `1`/`0` — never cross-apply

## Things to avoid
- **Don't treat terse affirmations (`yes`, `ahead`, `next`) as git authorization** — they scope only to the current edit/search operation, never to commit or push
- **Never write credentials or secrets to any file, note, checkpoint, or log** — not even scratch files or WAL entries — even if the user shares them inline for manual testing
- **Don't inline raw env conditions when a named utility already exists** — always grep (`isDevelopment`, `isProduction`) before writing a new env check

## Open questions / known gaps
- Terse-continue protocol structurally conflicts with per-push approval gate — long sessions with many "keep going" turns are high-risk for accidental pushes; no automated gate enforces this distinction at the tool call level yet
- Context compaction causes approval-state decay; there's no reliable signal when a pre-compaction push approval expires — treat every post-compaction session as having zero carry-forward git permissions

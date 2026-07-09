<!-- i-dream project brief · 2026-07-09T14:03:53.927314+00:00 · 5 patterns / 0 insights -->
## What this project is about
Versable-builder is a product/feature development codebase. Sessions focus on docs, architecture reviews, and multi-agent workflows — with recurring emphasis on prose quality and sequencing discipline.

## Things to do (or keep doing)
- Always restructure sentences so no file path is the final token before a period — trail it with a word, comma, or clause to preserve terminal auto-linking
- Complete all prerequisite research, doc writing, and user Q&A before launching any expensive multi-agent consensus or debate workflow (magi, orchestration, etc.)
- Load `frontend/docs/boring-technical-stuff/comment-style.md` before writing any user-facing prose for this project — it overrides global style rules

## Things to avoid
- Don't place a file path immediately before a sentence-ending period, even in backtick code spans — the Ghostty auto-linker swallows the trailing period
- Don't run a high-cost multi-agent review (magi debate, consensus panel) until ALL prerequisite content is finalized — running it over incomplete material wastes tokens and produces low-quality decisions
- Don't produce flowery/AI-smell prose ("Why this page matters", "The User" with capitalization, show-off language) — this project's doc standard is plain, dense, developer-register prose even when guidelines are loaded

## Open questions / known gaps
- The file-path-before-period rule keeps firing despite being documented at Tier 0 — mechanical restructuring habit is not yet automatic; treat every sentence ending in a path as a required rewrite

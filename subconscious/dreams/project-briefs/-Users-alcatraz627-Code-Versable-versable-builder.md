<!-- i-dream project brief · 2026-07-07T06:36:02.074821+00:00 · 2 patterns / 0 insights -->
## What this project is about
A product-builder tooling project (Versable) with heavy emphasis on structured multi-agent workflows, documentation generation, and staged review processes. Work style is deliberate and gated — prerequisites must complete before downstream steps fire.

## Things to do (or keep doing)
- Honor explicit deferral signals: when the user says to skip an expensive step (magi debate, multi-agent review) until content is ready, hold the gate and track it in tasks — don't run it early
- Follow `frontend/docs/boring-technical-stuff/comment-style.md` doc conventions specifically, not just global rules — the local rubric overrides

## Things to avoid
- Don't generate AI-smell prose in docs even when guidelines are loaded — scan for: "Why this page matters", capitalized "The User", show-off language, and em-dashes before writing any user-facing doc
- Don't conflate "all prerequisites are done" with "deferred review is now authorized" — the user must explicitly re-authorize expensive fan-out steps, not just complete the content they depend on

## Open questions / known gaps
- No signal yet on which multi-agent patterns (magi, review suites) are considered "expensive enough" to require explicit re-authorization vs implicit on-completion triggers — the boundary is fuzzy

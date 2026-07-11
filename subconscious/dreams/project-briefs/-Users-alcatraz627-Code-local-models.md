<!-- i-dream project brief · 2026-07-11T04:09:35.084053+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local models toolchain (`~/Code/local-models`) — CLI suite for running local LLMs, image generation, and agent APIs. Work style is exploratory research + tooling builds with high verification standards.

## Things to do (or keep doing)
- Always surface raw output for the user to inspect before declaring any test or feature successful — "it worked" without evidence is treated as failure
- Show the exact git command for manual execution when repo-specific CLAUDE.md rules require it; never auto-run git ops here
- Use `trash` for all file deletion — no exceptions, even for "cleanup" or "temporary" files
- Write docs in direct, formal, factually grounded language; product/behavior-focused, no "why this matters" opener

## Things to avoid
- Don't declare a UI or server-side change working without actually navigating to the URL and exercising the primary flow
- Don't re-introduce removed complexity or add unrequested features when the user has deleted code and asked for a simpler replacement
- Don't skip or defer explicit skill invocations (especially `/atone`) — executing other work instead of the correction ritual compounds the original mistake
- Don't write todos to a file (TODO.md, plan.md) when the user says "update todos" — use the Task tool

## Open questions / known gaps
- RCA files for atone S3 events must start with `---` YAML frontmatter on line 1; recurring lint failures suggest this is easy to forget in this project's correction flow

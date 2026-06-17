<!-- i-dream project brief · 2026-06-13T12:54:05.385397+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local model tooling and automation (`~/Code/local-models`) — CLI wrappers, JSONL history management, image-gen, and agent-API integrations. Work style is exploratory but delivery-focused; the user measures sessions by core-deliverable completion, not surrounding work quality.

## Things to do (or keep doing)
- Always surface actual command output for the user to inspect before declaring anything "successful" — evidence, not assertion
- Invoke `/atone` immediately and completely when triggered; never acknowledge and defer
- Use `TaskCreate`/`TaskUpdate` for todos — "update todos" means the TUI task list, not a file
- Write terse single-sentence WHY comments only; no essay-length annotations on obvious code

## Things to avoid
- Don't use `rm` — `trash` only; the hook blocks `rm` unconditionally, no "cleanup convenience" exceptions
- Don't complete peripheral/bonus work before delivering the primary goal stated at session start
- Don't write atone RCA files without `---` YAML frontmatter on line 1 — the lint gate silently drops the event
- Don't use flowery or promotional language in technical docs; match the tone to the content's seriousness

## Open questions / known gaps
- The agent repeatedly skips mandatory skill invocations mid-correction (compounding the original mistake) — this project has a high recurrence rate for `declared-ready-without-running` and `skill-invocation-skipped` patterns; treat both as auto-S3 here

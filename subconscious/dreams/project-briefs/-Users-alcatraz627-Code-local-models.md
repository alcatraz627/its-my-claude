<!-- i-dream project brief · 2026-07-13T00:44:04.978007+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM management tooling (`~/Code/local-models`) — CLI wrappers, model dispatch harness, and supporting infrastructure for running local and cloud models side-by-side. Working style is exploratory with strong CLI/TUI emphasis.

## Things to do (or keep doing)
- Always surface actual test/command output for the user to judge — declaring success without showing evidence is treated as a failure
- Execute skill invocations (e.g. `/atone`) immediately and completely when requested; deferring them escalates
- Use `trash` for all file deletion; the `rm` hook blocks exceptions without a manual override
- Write docs in direct, formal, product-focused prose — no "why this matters" openers, no em-dashes, no promotional framing

## Things to avoid
- Don't declare a UI or server-side change working without navigating to the actual URL and exercising the primary flow
- Don't re-introduce removed complexity after the user has explicitly deleted code and requested a simpler replacement
- Don't write todos to files (TODO.md, plan.md) when "update todos" is requested — always call the Task tool
- Don't place a period immediately after a file path in terminal output; it breaks Ghostty's auto-link

## Open questions / known gaps
- RCA files must begin with `---` YAML frontmatter on line 1 or `atone.sh` exits non-zero — this lint gate has been hit repeatedly and the template may not be enforcing it
- Picker/selector UIs have a recurring pattern mismatch: selection must preview only, with an explicit save action required — this keeps being implemented as auto-apply

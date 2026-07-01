<!-- i-dream project brief · 2026-06-30T16:02:46.772115+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local model tooling suite (`~/Code/local-models`) — CLI wrappers, warm/cold state management, and agent API over local LLMs. Work style is exploratory but delivery-oriented; the user expects concrete outputs, not research summaries.

## Things to do (or keep doing)
- Always surface actual command output when claiming a test passed — show the raw result so the user can judge correctness themselves
- Execute mandatory skills (`/atone`, `/core-dump`, etc.) immediately and completely when invoked; never defer or skip mid-correction
- Use the Task tool for todos — `TaskCreate`/`TaskUpdate` — never write to a file instead
- Translate research/design phases into lean, behavior-focused implementation docs before the session ends — direct and formal, no "Why this matters" openers

## Things to avoid
- Don't re-introduce complexity the user explicitly deleted; if they simplified, match that ceiling exactly
- Don't use `rm` — always `trash`; the hook blocks it and there are no exceptions for "cleanup" work
- Don't declare success without showing evidence; asserting a test passed without output is treated as a failure
- Don't write AI-smell prose (em-dashes, promotional framing, essay-length comments) in any human-facing output — one terse WHY sentence only

## Open questions / known gaps
- Peripheral sub-tasks (research, persona design, tooling scaffolding) consistently crowd out the core deliverable; ensure the primary ask ships before side work
- RCA files require `---` YAML frontmatter on line 1 or `atone.sh` exits non-zero — verify frontmatter before considering an atone recorded

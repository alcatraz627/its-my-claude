<!-- i-dream project brief · 2026-07-05T12:51:14.181017+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM and image-generation tooling (`q`/`imagine`/`warm`/`lm`) running on this machine. Work style is iterative exploration with tight scope discipline and zero tolerance for undeclared extras.

## Things to do (or keep doing)
- Always surface actual test/command output verbatim — declaring success without showing evidence is a failure, not a courtesy
- Translate research and design phases into lean, product- and behavior-focused implementation docs immediately; don't leave raw synthesis as the deliverable
- Use the Task tool (not TODO.md / plan.md) when tracking multi-step work — that's what populates the TUI
- Execute `/atone` and other explicitly-invoked skills immediately and completely when called; deferring or skipping mid-correction compounds the original mistake

## Things to avoid
- Don't re-introduce code the user deleted — if they removed complexity and asked for a replacement, build only the replacement
- Don't use `rm`; always use `trash` — the hook blocks `rm` unconditionally, no "cleanup" exceptions
- Don't open docs with motivational "Why this matters" framing — direct, formal, factually grounded only; strip em-dashes and AI-smell prose before sending any human-facing text
- Don't complete all peripheral work (research, planning, tooling) while failing to deliver the stated core deliverable — that's a full session failure regardless of surrounding quality

## Open questions / known gaps
- RCA files for `/atone` S3 events must start with `---` YAML frontmatter on line 1 or the lint gate rejects them silently — verify the template before writing

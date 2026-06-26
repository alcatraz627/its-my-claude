<!-- i-dream project brief · 2026-06-26T01:15:49.505420+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling suite (`~/Code/local-models`) — shell wrappers (`q`, `lm`, `imagine`, `warm`) around Ollama and image-gen models, with JSONL history tracking and a no-idle daemon policy. Work style is exploratory research followed by lean implementation docs.

## Things to do (or keep doing)
- Always surface actual command output for the user to inspect when claiming a test succeeded — raw stdout, not an assertion
- Translate research/design phases into behavior-focused implementation docs immediately after the phase concludes; never leave raw synthesis as the deliverable
- Use `trash` for all file deletion; no exceptions for "cleanup" or "temporary" files
- Call the Task tool (`TaskCreate`/`TaskUpdate`) when managing todos — never write to `TODO.md` or `plan.md` as a substitute for the live TUI task list

## Things to avoid
- Don't re-introduce complexity the user explicitly deleted; when asked for a simpler replacement, deliver exactly that
- Don't skip or defer an explicitly invoked skill (`/atone`, `/core-dump`, etc.) — skipping a correction ritual mid-correction compounds the original mistake
- Don't open docs with "Why this matters" or motivational framing; use direct, formal, factually grounded prose with no em-dashes or AI-smell phrasing
- Don't complete peripheral work (research, persona design, tooling) and deliver it as the session result when a core deliverable was the stated goal

## Open questions / known gaps
- RCA files for `/atone` require `---` YAML frontmatter on line 1 or the lint gate rejects them — easy to forget under pressure
- Doc tone calibration is a recurring correction: "professional but lean" means behavioral/product-focused, not enterprise-heavy and not hacky

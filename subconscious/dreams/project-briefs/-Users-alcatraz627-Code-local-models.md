<!-- i-dream project brief · 2026-06-25T00:50:57.691862+00:00 · 20 patterns / 0 insights -->
## What this project is about
A local LLM and image-generation tooling suite (`~/Code/local-models`) with heavy emphasis on persona/agent design, documentation pipelines, and CLI tooling. Work style is exploratory-then-structured: research phases translate into lean implementation docs and shipped CLIs.

## Things to do (or keep doing)
- Always surface actual test output for the user to inspect — never assert success without showing evidence
- Use the Task tool (not TODO.md or plan.md) whenever work has ≥3 steps; keep the TUI list live throughout
- Translate research/design phases into behavior-focused implementation docs before the session ends — raw synthesis is not a deliverable
- Write terse single-sentence WHY comments only; omit anything that restates what the code does

## Things to avoid
- Don't re-introduce deleted complexity or add unrequested features when the user has explicitly simplified — scope ceiling is absolute
- Don't skip or defer explicitly invoked skills (`/atone`, `/core-dump`, etc.) — skipping a correction ritual mid-correction compounds the original mistake
- Don't use `rm`; always use `trash` — the hook blocks rm unconditionally, no exceptions for "cleanup"
- Don't open docs or PRs with "Why this matters" / motivational framing or em-dashes — direct, formal, lean prose only

## Open questions / known gaps
- Core deliverable risk: the session pattern shows peripheral work (research, personas, tooling) completing while the primary stated output ships late or not at all — verify the main deliverable is done before declaring a session complete
- RCA files must start with `---` YAML frontmatter on line 1 or `atone.sh` rejects them silently (error 2)

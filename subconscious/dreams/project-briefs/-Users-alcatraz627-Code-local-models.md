<!-- i-dream project brief · 2026-06-19T01:40:51.638909+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local-models tooling project (`~/Code/local-models`) — managing local LLM/image-gen infrastructure with agent-driven workflows, scripting, and documentation. Work style is iterative with heavy use of correction rituals and task tracking.

## Things to do (or keep doing)
- Always surface actual command output for the user to inspect before declaring a test or feature successful — evidence first, verdict second
- Call the Task tool (`TaskCreate`/`TaskUpdate`) whenever "update todos" is requested; never write to a file as a substitute
- Invoke `/atone` immediately and completely when corrections happen — do not defer or skip mid-correction
- Use `trash` for all file deletion; `rm` is hard-blocked by hook with no exceptions

## Things to avoid
- Don't declare tests/features "successful" without showing the raw output — asserting success without evidence is treated as a failure
- Don't skip or defer explicitly-invoked skills (`/atone`, `/core-dump`, etc.) in favor of other work; skipping an invoked ritual is a compounding offense
- Don't complete peripheral/bonus work before delivering the session's primary stated deliverable
- Don't write essay-length comments; one terse WHY-only sentence max, or nothing

## Open questions / known gaps
- RCA files for atone must begin with `---` YAML frontmatter on line 1 or the gate silently rejects the event — this has recurred; verify frontmatter every time before running `atone.sh add`

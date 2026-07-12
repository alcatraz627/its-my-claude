<!-- i-dream project brief · 2026-07-12T04:50:44.780325+00:00 · 20 patterns / 2 insights -->
## What this project is about
Local model orchestration suite (`q`, `imagine`, `warm`, `lm fleet`) with a CLI-first working style. Sessions involve research, persona design, tooling setup, and documentation — all requiring delivery of the primary deliverable before peripheral tasks.

## Things to do (or keep doing)
- Always surface actual output when claiming a test or feature works — raw terminal output, not an assertion of success
- Execute invoked skills (e.g. `/atone`) immediately and completely; verify the terminal artifact (event line, committed file) before continuing
- Use `trash` for all file deletion — no exceptions for "cleanup" or "temp" files
- Call `TaskCreate`/`TaskUpdate` when asked to update todos; never write to a file instead

## Things to avoid
- Don't declare success on UI or server changes without navigating to the actual URL and exercising the primary flow
- Don't re-introduce complexity the user explicitly deleted; scope is a ceiling — honor simplification requests exactly
- Don't open docs or RCAs with promotional "why this matters" framing — direct, factual, formal only; no em-dashes
- Don't skip or defer a correction ritual mid-correction — a skipped `/atone` while being corrected is a compounded failure

## Open questions / known gaps
- Recurring fractal premature closure: agent short-circuits both code-level verification (no run) and ritual-level verification (invocation ≠ completion) in the same session — no single hook catches both layers

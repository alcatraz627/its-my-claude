<!-- i-dream project brief · 2026-07-11T18:15:29.517733+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling suite (`q`, `imagine`, `warm`, `lm fleet`) — code, docs, and research for on-device model infrastructure. Work spans CLI scripting, architectural documentation, and sub-agent orchestration.

## Things to do (or keep doing)
- Always surface raw test/command output for the user to judge — declaring success without showing evidence is treated as a failure
- Use the Task tool for todos; never write TODO.md or plan.md as a substitute for the TUI task list
- Deliver the primary task first before completing peripheral sub-tasks (research, persona design, tooling setup)
- Write docs as professional/lean behavioral specs: direct, factually grounded, product-focused — not academic or promotional

## Things to avoid
- Don't re-introduce code the user explicitly deleted; when asked for a simpler replacement, strip and stay stripped
- Don't use `rm` for deletion — `trash` only, no exceptions for "cleanup" or "temp" files
- Don't emit em-dashes or "Why this matters" / motivational openers in any human-facing prose
- Don't navigate URLs or declare a UI/server change working without actually exercising the primary flow in the browser

## Open questions / known gaps
- Tension between exploratory multi-sub-task sessions and delivering the core goal first — peripheral work (research, atone, tooling) consistently delays the primary deliverable
- RCA frontmatter (`---` on line 1) is repeatedly omitted, causing the atone lint gate to silently fail and leaving mistakes unrecorded

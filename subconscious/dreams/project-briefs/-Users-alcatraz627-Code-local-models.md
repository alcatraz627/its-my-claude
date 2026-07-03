<!-- i-dream project brief · 2026-07-02T23:56:06.286412+00:00 · 20 patterns / 0 insights -->
## What this project is about
Local LLM tooling project (`~/Code/local-models`) — managing local model runners, warmth state, and CLI tooling. Sessions are research-heavy with concrete deliverable expectations at the end.

## Things to do (or keep doing)
- Always show raw test output for the user to inspect; declaring success without evidence is a failure
- Always invoke `/atone` immediately and completely when triggered — skipping it mid-correction compounds the mistake
- Use the Task tool (not TODO files) when asked to update todos; the TUI is the live surface
- Translate research/design phases into lean, behavior-focused implementation docs before the session ends

## Things to avoid
- Don't re-introduce removed complexity or add features the user didn't ask for when replacing deleted code
- Don't use `rm` — use `trash`; the hook blocks `rm` unconditionally with no "cleanup" exceptions
- Don't write docs with promotional/motivational framing ("why this matters", em-dashes, AI-smell phrasing) — direct and formal only
- Don't complete peripheral work (research, planning, persona design) while leaving the core stated deliverable undelivered

## Open questions / known gaps
- Sessions tend to over-invest in exploratory side work and under-deliver on the primary ask; finish the core deliverable first, then extras
- RCA files must open with `---` YAML frontmatter on line 1 or `atone.sh` exits non-zero silently — verify frontmatter before considering any `/atone` call complete

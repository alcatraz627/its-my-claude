<!-- i-dream project brief · 2026-06-19T17:53:56.761298+00:00 · 20 patterns / 0 insights -->
## What this project is about
A local-models development workspace focused on AI tooling, research agents, and automation scripts. Work style is exploratory multi-session with heavy use of skills, sub-agents, and correction rituals.

## Things to do (or keep doing)
- Always surface actual output for the user to inspect when claiming a test succeeded — evidence, not assertion
- Use `TaskCreate`/`TaskUpdate` when told to "update todos"; never write to a file as a substitute
- Deliver the primary session deliverable before expanding into secondary research or bonus work
- Use formal, direct language in technical docs — no promotional framing or "why this matters" flourishes

## Things to avoid
- Don't skip or defer explicit skill invocations (e.g. `/atone`) — execute them immediately and completely when requested
- Don't use `rm`; always use `trash` — the hook blocks `rm` and there are no exceptions for "cleanup" or "temp" files
- Don't write essay-length comments; one terse WHY-only sentence maximum, omit entirely when obvious
- Don't write atone RCA files without `---` YAML frontmatter on line 1 — the lint gate rejects them and the event goes unrecorded

## Open questions / known gaps
- Recurring tension: agent completes peripheral work (planning, research, persona design) but misses the core deliverable, which the user treats as total session failure regardless of surrounding quality

<!-- i-dream project brief · 2026-06-09T20:13:38.972642+00:00 · 15 patterns / 0 insights -->
## What this project is about
Local model integration/experimentation project — running, testing, and managing local LLMs. Working style is hands-on: run the thing, show real output, iterate tight.

## Things to do (or keep doing)
- Always surface actual command output for the user to inspect before declaring any test or feature successful — no evidence = failure
- Use the Task tool (`TaskCreate`/`TaskUpdate`) whenever "update todos" is said; never write to a file instead
- Invoke explicitly requested skills (e.g. `/atone`) immediately and completely before moving on to other work
- Follow the user's stated next step when it conflicts with hook/reviewer suggestions — surface the suggestion as optional, don't act on it

## Things to avoid
- Don't declare tests or features "working" without showing the raw output; asserting success without evidence is treated as a failure
- Don't skip or defer `/atone` or other correction rituals after explicit invocation — skipping escalates severity
- Don't use `rm`; always use `trash` — the hook blocks `rm` unconditionally
- Don't spend cycles on secondary tasks (config, personas, side work) before shipping the session's primary stated deliverable

## Open questions / known gaps
- Agent repeatedly defaults to file-based todos over the Task tool despite the rule — may need a mechanical nudge or hook to catch this pattern at session start
- Comment verbosity: agent over-explains even after prior corrections; may need project-level `.claude/rules/` reinforcement

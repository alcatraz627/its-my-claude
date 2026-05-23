<!-- i-dream project brief · 2026-05-01T11:09:32.071601+00:00 · 17 patterns / 10 insights -->
## What this project is about
A personal portfolio/dashboard built with SvelteKit, served via nginx on a local LAN with `.local` hostname. Work style is long autonomous sessions with strict scope boundaries — the user acts as director, not pair programmer.

## Things to do (or keep doing)
- Always confirm the task boundary at session start before any implementation; "understand" and "implement" are different scopes
- Commit and document incrementally — don't batch all changes to the end of a session
- Use `/core-dump` at session end and `/catchup` at session start; treat all state as ephemeral between sessions
- Match execution depth to task size — terse messages like "keep going" mean go deeper, not wider

## Things to avoid
- Don't add unrequested enhancements (animations, polish, refactors) — user has corrected this multiple times; treat requests as a ceiling, not a floor
- Don't spawn parallel agents unless the user explicitly asks; prefer sequential single-agent work
- Don't assume codebase or git state from earlier in the session — re-read before any side-effecting operation
- Don't implement when only understanding was asked for; "help me understand X" is not a green light to change X

## Open questions / known gaps
- Recurring tension between high-autonomy execution (100+ tool calls tolerated) and strict scope containment — the resolution is: go fast and far, but only in the exact direction specified
- Terminal/WebSocket server stability is an unresolved recurring issue; expect processes to die unexpectedly

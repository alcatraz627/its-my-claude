<!-- i-dream project brief · 2026-05-01T11:07:34.431375+00:00 · 20 patterns / 10 insights -->
## What this project is about
Claude Code configuration repository (`~/.claude`) — skills, hooks, rules, and conventions for the user's personal Claude Code setup. Work style is long-running autonomous sessions with strict scope discipline.

## Things to do (or keep doing)
- Always run `/catchup` at session start to re-orient from WAL/checkpoint state before touching anything
- Match response depth to message length: terse input (`keep going`, `move`) means continue on current trajectory with full autonomy, no narration
- Run `/core-dump` proactively before any context-exhausting operation or session end
- Treat all state as ephemeral — re-read files, re-check git status before any side-effect, even mid-session

## Things to avoid
- Don't expand scope beyond what was explicitly requested — no unsolicited enhancements, animations, refactors, or "while I'm here" polish
- Don't spawn parallel agents unless the user explicitly asks; prefer sequential single-agent execution
- Don't implement changes when the user only asked to understand the codebase — read-only exploration unless told otherwise
- Don't infer scope from terse continuation signals; `keep going` means deeper execution, not broader scope

## Open questions / known gaps
- Tension between high-autonomy execution (50–150 tool calls tolerated) and strict scope ceiling — the boundary must be confirmed at session start, not inferred
- User has corrected scope expansion multiple times across sessions; this pattern persists despite corrections, suggesting it needs a hook or session-start confirmation ritual

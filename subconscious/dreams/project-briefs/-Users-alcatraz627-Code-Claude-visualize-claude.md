<!-- i-dream project brief · 2026-05-01T11:08:27.839862+00:00 · 17 patterns / 10 insights -->
## What this project is about
A SvelteKit-based visualization/dashboard tool for Claude Code sessions, served on a local network via nginx. Work style is high-autonomy execution within strictly bounded scope.

## Things to do (or keep doing)
- Always `/catchup` at session start and `/core-dump` at session end — state serialization is the primary continuity mechanism here
- Commit and document incrementally throughout the session, not in one batch at the end
- Match execution depth to terse continuation signals (`keep going`, `next`, `more`) — go deep, but stay on the exact trajectory specified
- Treat the task boundary confirmed at session start as a hard ceiling; within it, execute autonomously and aggressively

## Things to avoid
- Don't implement changes when the user asks to *understand* code — exploration and implementation are distinct modes; confirm which one is active
- Don't spawn parallel agents unless the user explicitly requests it; prefer sequential single-agent work
- Don't add unsolicited enhancements (animations, refactors, polish) — "while I'm here" additions have been corrected multiple times
- Don't act on inferred or stale state; re-read file/git/process state before any side-effecting action

## Open questions / known gaps
- Recurring tension between terse-continuation autonomy and strict scope limits — when a short message arrives mid-session, verify it's a continuation signal and not a mode switch before executing
- Terminal/WebSocket server stability is a known fragile subsystem; treat it as suspect and verify process state before diagnostics

<!-- i-dream project brief · 2026-05-01T11:14:12.098064+00:00 · 17 patterns / 10 insights -->
## What this project is about
A pm2 process management dashboard built with SvelteKit, served via nginx on a local home server with LAN/mobile access. Work style: long autonomous execution sessions within tight scope boundaries set at session start.

## Things to do (or keep doing)
- Run `/catchup` at session start; write a `/core-dump` before ending any implementation session
- Confirm task boundary explicitly before starting work — then execute autonomously within it
- Commit and document changes incrementally, not in one batch at the end
- Prefer single-agent sequential work; avoid spawning parallel agents unless objectively required

## Things to avoid
- Don't expand scope beyond the exact request — no unsolicited animations, polish, refactors, or "while I'm here" improvements
- Don't implement changes when the user asks to *understand* the codebase — read and explain only
- Don't act on assumed state; re-read file/git/process state before any side-effecting action
- Don't spawn parallel agents by default — user has corrected this pattern explicitly

## Open questions / known gaps
- Terminal/WebSocket server stability is a recurring problem; processes run infinitely or die unexpectedly — no durable fix documented
- WiFi/network name redaction in system info has required multiple workaround attempts with no clean resolution

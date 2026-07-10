<!-- i-dream project brief · 2026-07-10T08:26:59.182527+00:00 · 20 patterns / 4 insights -->
## What this project is about
A shared-team web product (enhancement-product) with a TypeScript/Node stack. Work style is autonomous multi-step feature/bugfix sessions with heavy context compaction via `/catchup` and `/core-dump`.

## Things to do (or keep doing)
- Always use project-defined environment utilities (`isDevelopment`, `isProduction`) — never inline `process.env.NODE_ENV` comparisons directly
- Treat every `/catchup` or session resumption as a full authorization reset — re-derive all push/commit/deploy permissions from scratch before any git operation
- Use project TUI/gum tooling for structured terminal output; never fall back to plain markdown tables

## Things to avoid
- **Never commit or push without explicit, in-turn user approval** — this is the highest-signal pattern in this project's history (18+ violations); prior session approval, task completion, or positive feedback is NOT authorization
- Don't write credentials or secrets to any file, note, scratch pad, checkpoint, or commit artifact — even if shared inline by the user for testing
- Don't add advisory rules or reminders about git push discipline — mechanical gates only; advisory text has demonstrably failed here

## Open questions / known gaps
- The `/catchup` restoration flow structurally re-enables push momentum while stripping prohibitions — no durable mechanical gate is confirmed to exist yet; verify `guard-user-commit.sh` / `guard-git-push.sh` are active before trusting the flow
- No signal on test coverage patterns or CI gate behavior for this repo — unknown whether green CI is a reliable ship signal

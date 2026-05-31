<!-- i-dream project brief · 2026-05-30T17:03:26.685936+00:00 · 20 patterns / 1 insights -->
## What this project is about
A shared-team web product (Versable enhancement) with strict boundary rules around git operations and credential handling. Work style is feature-driven with established codebase conventions to follow.

## Things to do (or keep doing)
- Always use project-defined environment utilities (`isDevelopment`, `isProduction`) — never inline raw `process.env.NODE_ENV` comparisons
- Use the project's TUI/gum tools when presenting structured data in the terminal
- Treat any action that moves information across an irreversibility boundary (push, publish, write-to-disk) as requiring fresh explicit confirmation

## Things to avoid
- **Never commit or push without fresh per-operation user approval** — blanket session approval does not carry forward; this is the single most-violated rule here
- **Never write credentials to any file** — not scratch notes, checkpoint files, or comments; not even temporarily
- Don't bypass project-defined constants or utilities by re-deriving equivalent values inline

## Open questions / known gaps
- Git push violations have been recorded 6+ times with high confidence — suggests the mechanical hook enforcement described in `rules/git.md` may not be fully blocking this in practice; verify hook is active

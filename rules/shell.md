---
brief: Inline commands run zsh (never name a var `path`); trash not rm; no Glob from ~/; non-interactive flags
triggers:
  - topic:shell
  - topic:zsh
  - topic:file-deletion
  - tool:rm
  - tool:trash
  - tool:timeout
related: [features/shared-library.md]
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 90
---

# Shell
Shell, search, and delete discipline.

## File search scope

**Never Glob/Grep from `~/` — always resolve to a project root first.** Searches from the home directory will traverse massive trees and return irrelevant results.

## Safe delete — `trash` not `rm`

A `PreToolUse` hook (`~/.claude/scripts/safe-delete.sh`) blocks every `rm` invocation. Use `trash <path>` instead (macOS built-in → Finder Trash, recoverable). Full reference: `~/.claude/skills/shared/safe-delete.md`.

If you hit the block, it means you tried `rm`. Do not try to work around it (no `\rm`, no `/bin/rm`). The block is intentional.

## Non-interactive flags are mandatory

`npm install -y`, `cp -f`, `mv -f`, `apt-get install -y`. Any command that might prompt must be flagged non-interactive, or it will hang.

## Background tasks

Don't use `run_in_background: true` unless the user explicitly asks. Background processes orphan on `/clear` and survive across sessions, polluting the next session's state.

## Compound commands and permissions

Long multi-command chains (e.g., `echo ... && ls ... && find ... && wc ...`) can trigger permission prompts even when each individual command is allowed. Prefer multiple separate calls over one mega-compound when any component might be unfamiliar.

## Sentinel values

**Two different shells run your code, and they differ in what they support.** A Bash-tool command runs under **zsh 5.9** on this account, where `declare -A` works fine. A script you *write* with `#!/bin/bash` runs **bash 3.2**, which has no associative arrays. The 3.2 limit therefore binds scripts, not inline commands: a script needing `declare -A` or other bash-4 features must shebang `/opt/homebrew/bin/bash` if available, or delegate to Python. Confirm which you are in with `${ZSH_VERSION:-}` / `${BASH_VERSION:-}` rather than assuming.

## ripgrep over grep (MANDATORY)

A hook (`scripts/prefer-ripgrep.sh`) blocks every direct `grep` Bash call; rg is
18-65x faster on this machine. Use `rg --no-ignore --hidden` for grep-equivalent
scope. **Never silently fall back to grep** — install rg or get the user's
acknowledgement first; `git grep` is allowed through the hook. Full equivalents
table, the legitimate-grep cases, and script guards: `rules/shell-reference.md`.

## The reference catalog — moved

macOS silent-failure gotchas (the zsh `path` trap, `find /tmp` no-descent,
`timeout`), the dedicated-tools table (fd/yq/File-Tools), rg equivalents, and
the prefer-existing-scripts law live in `rules/shell-reference.md`, which
autoloads when you touch shell files. Split per prime-demotion-0901 D2a,
2026-09-01.

## Anti-pattern — a relative `.claude/…` write while CWD is `~/.claude`

When CWD is `~/.claude` itself, relative paths like `.claude/output/X` resolve to `~/.claude/.claude/X` — a broken double-nest. A hook (`scripts/block-nested-claude.sh`) blocks the **write**, judging it against CWD rather than by matching command text, so reading, grepping, or testing that path is not blocked. The directory itself is legitimate: it is this project's own project-scoped `.claude/`, holding `settings.local.json` and `worktrees/`. The accident is the relative resolution, never the path. Full redirect table: [`conventions/asset-management.md`](../conventions/asset-management.md).

---
brief: Frequent commits, public repos by default, .gitignore patterns, never push main without approval
triggers:
  - topic:git-commits
  - topic:github-repos
  - tool:git
  - tool:gh
related: []
tier: 1
category: rules
updated: 2026-04-24
stale_after_days: 90
---

# Git
Commit cadence, push discipline, repo defaults, and gitignore patterns.

## Frequent commits — MANDATORY

Commit after each logical unit, before switching areas, before risky operations, and if ~15-20 min of work accumulates. Batch related small changes (rename + imports = one commit) but never let 3-4+ changes pile up. Push after every 2-3 commits.

## Never push to main without explicit approval

One approval ≠ blanket approval. Each push to `main` or `master` requires fresh confirmation.

## GitHub repos — public by default

When creating repositories via `gh` CLI or GitHub MCP, always use `--public` or `private: false`. Unless the user explicitly requests private.

## Don't commit

- `.claude/skills/shared/locks/` — transient locks
- `.claude/wal.md` / `.claude/wal.jsonl` — session-local logs
- `_*.claude.md` — scratch/checkpoint files
- temp/scratch files generally

## Standard `.gitignore` patterns for Claude/agent projects

- `**/.playwright-mcp/` — Playwright MCP browser artifacts; ephemeral
- `_*.claude.md` — root-level scratch/checkpoint files
- `claude/_*.claude.md` — claude-subdir scratch files

## Commit message style

Follow the repo's existing convention. Default: imperative present tense. Describe "why" more than "what" (the diff already shows what). Keep subject line under 72 chars.

## Dangerous operations — CONFIRM EACH TIME

These never inherit prior approval. Confirm for every invocation, naming the target branch/file:

| Command | Risk |
|---------|------|
| `git reset --hard` | Discards uncommitted work |
| `git push --force` / `--force-with-lease` | Overwrites remote; breaks collaborators |
| `git clean -f` / `-fd` | Deletes untracked files irrecoverably |
| `git branch -D <name>` | Force-deletes even unmerged branches |
| `git rebase` on a branch that's been pushed | Rewrites public history |
| `git checkout -- <path>` / `git restore --source` | Discards uncommitted edits on that path |
| `git commit --amend` after push | Same as rebase — rewrites public commit |
| `git filter-branch` / `filter-repo` | Rewrites history en masse |
| `git update-ref -d` | Deletes refs directly |
| `gh repo delete` | Obvious; confirm repo name + org |
| `gh pr close` / `issue close` | Visible to collaborators |

## Related skills — use instead of hand-rolling

- **[`/git-setup`](../.claude/skills/git-setup/SKILL.md)** — initializes/audits repos (`.gitignore`, branch protection, conventional commits, PR templates, health check). Use when starting a new repo or inheriting one with ambiguous state.
- **[`/readme`](../.claude/skills/readme/SKILL.md)** — generates a polished `README.md` with GitHub-style badges, a pixel-art cover image, a quick-start, and a linked doc index. Pair with `/banner` for a colorful ASCII header and `/svg` (if present) for a hero image.
- **[`/commit`](../.claude/skills/commit-commands/commit/SKILL.md)** and **[`/commit-push-pr`](../.claude/skills/commit-commands/commit-push-pr/SKILL.md)** — structured commit + PR-open flows.
- **[`/clean_gone`](../.claude/skills/commit-commands/clean_gone/SKILL.md)** — prunes local branches whose remote is gone.

## Command & gh cheatsheet

Full command examples and `gh` usage patterns live in **[`features/git-commands.md`](../features/git-commands.md)** — load it on demand when user is actively working with git/gh.

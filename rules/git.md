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
updated: 2026-07-11
stale_after_days: 90
---

# Git
Commit cadence, push discipline, repo defaults, and gitignore patterns.

## Frequent commits — MANDATORY

Commit after each logical unit, before switching areas, before risky operations, and if ~15-20 min of work accumulates. Batch related small changes (rename + imports = one commit) but never let 3-4+ changes pile up. Push after every 2-3 commits.

Authorization is the repo's protection status (user ruling 2026-07-11), cadence is only timing:

- **Protected repo** (entry in `~/.claude/protected-repos.list`, or a tracked `.claude/require-user-commit` marker; enforced by guard-user-commit.sh): the agent NEVER commits — prepare the change, present the diff, hand the commit to the user.
- **Unprotected repo**: the agent may commit per logical unit and push as part of in-scope work — no per-commit ask. Don't commit speculatively outside the task's scope.
- Projects usually start unprotected and occasionally graduate to protected as they mature (e.g. versable-builder and its two MVPs are deliberately unprotected today; enhancement-product has graduated). Graduation is the user's edit to the list, never the agent's.

## Never push to main without explicit approval

One approval ≠ blanket approval. Each push to `main` or `master` requires fresh confirmation (guard-git-push.sh pops the native dialog / sentinel flow). Protected repos gate ALL pushes the same way; unprotected feature-branch pushes flow freely.

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

## Pre-commit comment pass (implementation sessions)

Before committing code changes, run `/cleanup-comments --changed` in preview
mode and apply the confirmed strips/rewrites in the same commit. The write-time
hooks catch noise and essays; this pass is the fresh-eyes read that catches the
wordy middle band (`style/derived/comment.md` holds the user's verdicts: minimum
words, never the WHAT). Skip for docs-only or non-code commits. For commits
that touch human-facing docs, run `python3 ~/.claude/scripts/style/prose-lint.py`
on the changed .md files and fix what it flags in earnest prose
(`conventions/language-quality.md` is the taxonomy behind the scores).

## Review contract — all review surfaces (/skeptical-review, /code-review, /review, PR reviews)

- **Extraneous words are defects.** In comments and prose alike, wordage that
  could be cut without losing meaning is a finding framed as a reader's-time
  violation, cited with its one-line rewrite — not a style aside. The seeded
  verdicts live in `style/derived/` (see `personas/readers-advocate.md`).
- **Scope is the diff plus its direct callers/callees.** Findings outside that
  union go into a one-line "out-of-scope observations" appendix, never the
  findings list; widening scope requires the user's explicit ask. A 3-file
  change never earns a 30-file review.
- **Review reports end with a Dispositions table** (fixed / deferred-with-owner
  / rejected-with-reason); the undispositioned count rides the Resume
  Contract's Standing caveats (`conventions/report-writing.md`).

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

- **[`/git-setup`](../skills/git-setup/SKILL.md)** — initializes/audits repos (`.gitignore`, branch protection, conventional commits, PR templates, health check). Use when starting a new repo or inheriting one with ambiguous state.
- **[`/readme`](../skills/readme/SKILL.md)** — generates a polished `README.md` with GitHub-style badges, a pixel-art cover image, a quick-start, and a linked doc index. Pair with `/banner` for a colorful ASCII header and `/svg` (if present) for a hero image.
- **`/commit`** and **`/commit-push-pr`** (from the `commit-commands` plugin) — structured commit + PR-open flows.
- **`/clean_gone`** (from the `commit-commands` plugin) — prunes local branches whose remote is gone.

## Command & gh cheatsheet

Full command examples and `gh` usage patterns live in **[`features/git-commands.md`](../features/git-commands.md)** — load it on demand when user is actively working with git/gh.

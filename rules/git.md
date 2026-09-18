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
updated: 2026-09-18
stale_after_days: 90
---
# Git: commit cadence, push discipline, repo defaults

- Commit after each logical unit, before an area switch, before a risky op. Push every 2-3 commits. Cadence is timing, not authorization: a **protected repo** (`~/.claude/protected-repos.list` or `.claude/require-user-commit`) is USER-commit only; an unprotected one the agent commits in scope.
- **Never push to main without fresh approval.** guard-git-push.sh prints a nonce; print the owner `approve push <nonce>` once and keep working. Never AskUserQuestion for a push.
- `gh repo create --public` by default.
- Don't commit `.claude/wal.*`, `_*.claude.md`, locks, temp files.
- **No Claude signatures in any commit or PR body** (owner ruling). Subject under 72 chars, imperative, why over what.
- Before committing code: `/cleanup-comments --changed`; docs: `prose-lint.py`.
- Review scope is the diff plus direct callers/callees; reports end with a Dispositions table.
- **Confirm every time, naming the target:** `reset --hard`, `push --force*`, `clean -f*`, `branch -D`, rebase of a pushed branch, `commit --amend` after push, filter-branch, `update-ref -d`, `gh repo delete`, `gh pr/issue close`.
- Committing `~/.claude`: follow `~/.claude/COMMIT.md` (secret-scan before add, fetch and rebase-if-behind).

A halt under this rule needs a genuinely missing thing, information or authority not yet granted; holding both, act (`never-halt-on-authority-you-hold.md`).

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/git.md`

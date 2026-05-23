---
brief: git + gh command cheatsheet for common operations, PR workflows, recovery — load when actively using git
triggers:
  - tool:git
  - tool:gh
  - topic:git-commits
  - topic:github-repos
  - topic:pr-workflow
  - phrase:"open a PR"
  - phrase:"push changes"
related: [rules/git.md]
tier: 2
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Git Commands

Command reference and `gh` usage patterns. Rules and dangerous-command list live in [`rules/git.md`](../rules/git.md) — this file is the cheatsheet for the safe, common stuff.

## Verification triad (before any push, branch op, or merge)

```bash
git status
git log --oneline -3
git diff --stat
```

Confirms clean tree, correct branch, and what you're about to ship.

## Common commit + push flow

```bash
git status                                      # what's changed
git add <file>...                               # stage specific paths; avoid `git add -A` near secrets
git diff --cached                               # review staged
git commit -m "imperative message"              # use HEREDOC for multi-line
git push                                        # push current branch to tracking remote
git push -u origin HEAD                         # first push of new branch; sets upstream
```

**Multi-line commit message via HEREDOC:**

```bash
git commit -m "$(cat <<'EOF'
Subject line in imperative mood (<72 chars)

Body paragraph explaining WHY, not what. Reference issues if relevant.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

## Branch workflow

```bash
git checkout -b feature/xyz                     # create + switch
git switch <name>                               # modern alternative to checkout for switching
git branch                                      # list local
git branch -r                                   # list remote-tracking
git branch --merged main                        # branches already merged to main
git fetch --all --prune                         # refresh remote-tracking, drop gone branches
```

## Inspect & debug

```bash
git log --oneline -20                           # recent commits compact
git log --all --oneline --graph --decorate -20  # visual commit graph
git show HEAD                                   # full diff of most recent commit
git show <sha>:<path>                           # file contents at a specific commit
git blame <file>                                # who last touched each line
git log -p <file>                               # all changes to a single file
git log --author="name" --since="2 weeks ago"   # filter by author/date
git reflog                                      # recover lost commits (even after --hard reset)
```

## Stash + temporary work

```bash
git stash push -m "reason"                      # save uncommitted work
git stash list                                  # see stashes
git stash pop                                   # apply + remove most recent
git stash apply stash@{N}                       # apply specific stash, keep in list
git stash drop stash@{N}                        # delete specific stash
```

## Recovery (safe, non-destructive)

```bash
git restore <file>                              # discard unstaged changes on a file (CONFIRM FIRST)
git restore --staged <file>                     # unstage without losing edits
git reset HEAD~1                                # undo last commit, keep changes unstaged
git reset --soft HEAD~1                         # undo last commit, keep changes staged
git revert <sha>                                # create new commit that undoes <sha> (safe, preserves history)
git cherry-pick <sha>                           # apply a single commit to current branch
```

**For dangerous recovery** (`reset --hard`, `clean -f`, `branch -D`, `push --force`) — see dangerous-command table in [`rules/git.md`](../rules/git.md). Always confirm first.

## Rebase (local only — see rules for public-history caveat)

```bash
git fetch origin
git rebase origin/main                          # replay your commits on top of fresh main
git rebase --continue                           # after resolving conflicts
git rebase --abort                              # give up, restore pre-rebase state
```

Do NOT rebase branches others have pulled unless you've coordinated.

## `gh` — GitHub CLI patterns

### PRs

```bash
gh pr create --fill                             # uses most recent commit as title + body
gh pr create --title "..." --body "..."         # explicit
gh pr list                                      # open PRs on current repo
gh pr list --author @me                         # just yours
gh pr view <num>                                # view in terminal
gh pr view <num> --web                          # open in browser
gh pr checks <num>                              # CI status
gh pr diff <num>                                # diff in terminal
gh pr merge <num> --squash                      # merge with squash (also --merge, --rebase)
gh pr close <num>                               # CONFIRM — visible to collaborators
```

**PR body via HEREDOC:**

```bash
gh pr create --title "feat: widget X" --body "$(cat <<'EOF'
## Summary
- Bullet 1
- Bullet 2

## Test plan
- [ ] Smoke test A
- [ ] Smoke test B

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Issues

```bash
gh issue list
gh issue view <num>
gh issue create --title "..." --body "..."
gh issue close <num>                            # CONFIRM
gh issue comment <num> --body "..."
```

### Repos

```bash
gh repo create <name> --public --source=. --push
gh repo view                                    # current repo in browser
gh repo clone <owner>/<name>
gh repo list <owner>                            # user/org repos
```

Default: **public**. See `rules/git.md` for the rule.

### API escape hatch

```bash
gh api repos/<owner>/<name>/pulls/<num>/comments       # raw PR comment thread
gh api repos/<owner>/<name>/actions/runs?branch=main   # CI runs on branch
gh api --paginate rate_limit                           # throttle diagnostics
```

Use when the first-class CLI doesn't expose a field you need — `gh api` gives full REST access.

## Tagging & releases

```bash
git tag -a v1.2.3 -m "release notes"
git push --tags                                 # push all local tags
git push origin v1.2.3                          # push one tag
gh release create v1.2.3 --generate-notes       # creates GitHub release from tag
gh release list
```

## Worktrees (parallel branches without re-cloning)

```bash
git worktree add ../repo-feat feature/xyz       # new workdir on branch feature/xyz
git worktree list
git worktree remove ../repo-feat                # after branch merged / abandoned
```

Useful for running two branches side-by-side (e.g., reviewing a PR while coding on another branch).

## When to pick which tool

| Goal | Tool |
|------|------|
| Start a new repo | `/git-setup` skill |
| Generate / refresh README | `/readme` skill |
| Commit + push + open PR | `/commit-push-pr` skill |
| Just commit | `/commit` skill |
| Prune gone branches | `/clean_gone` skill |
| One-off PR list | `gh pr list` |
| Trace a bug to a commit | `git log -p <file>` + `git blame` |
| Recover lost work | `git reflog` |
| Review PR diff locally | `gh pr checkout <num>` then inspect |

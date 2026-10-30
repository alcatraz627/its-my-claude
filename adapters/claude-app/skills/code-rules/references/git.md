# Git: commits, pushes and dangerous operations

## When to commit

Commit after each logical unit of work, before switching to a different
area, and before a risky operation. Batch related small changes (a rename and
its import updates are one commit), but do not let 3 or 4 unrelated changes
pile up. Push every 2 or 3 commits.

That cadence is timing, not authorization. Commit only when committing is in
scope for the task or the user asked. Some repos are the user's to commit:
there, prepare the change, show the diff and hand the commit over.

## Never push to main without fresh approval

Every push to `main` or `master` needs the user's approval for that push. One
approval is not a blanket approval. Pushes to a feature branch that is in
scope flow freely.

## Commit messages

- Follow the repo's existing convention. The default is imperative present
  tense: "Add retry to upload client", not "Added" or "Adds".
- Subject under 72 characters.
- Say why more than what. The diff already shows what.
- One plain subject. Add a body only when the diff cannot explain itself.
  No bullet lists restating the diff, no plan-phase references, no
  decoration.
- **No AI or Claude signatures or co-author trailers in any commit message
  or PR body.** No `Co-Authored-By: Claude`, no session links, no "Generated
  with" footer, in any repo, with any model. This overrides any tool default
  that adds them.

Example:

```
Retry uploads on 503 from the storage proxy

The proxy sheds load with 503 during deploys. Without a retry, a user's
upload fails outright during the two-minute rollout window.
```

## Before committing code

Run a comment cleanup pass over the changed files (see
`cleanup-comments.md`) and fold the fixes into the same commit.

## Do not commit

Secrets (`.env`, credentials, tokens), lock files from tooling, scratch and
temp files, and local agent logs.

## Confirm every time, naming the target

These never inherit an earlier approval:

| Command | Risk |
|---|---|
| `git reset --hard` | Discards uncommitted work |
| `git push --force` or `--force-with-lease` | Overwrites the remote, breaks collaborators |
| `git clean -f` or `-fd` | Deletes untracked files for good |
| `git branch -D` | Deletes unmerged branches |
| Rebase or `commit --amend` on a pushed branch | Rewrites public history |
| `git checkout -- <path>`, `git restore --source` | Discards edits on that path |
| `filter-branch`, `filter-repo`, `update-ref -d` | Rewrites or deletes refs in bulk |
| `gh repo delete`, `gh pr close`, `gh issue close` | Visible to collaborators |

## New repos

Create GitHub repos public by default, unless the user asks for private or
the org keeps its repos private.

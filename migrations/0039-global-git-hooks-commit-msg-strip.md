# 0039 — global git hooksPath: commit-msg trailer strip

## Summary

`git config --global core.hooksPath ~/.claude/git-hooks` is now set
machine-wide. The dir holds one real hook, `commit-msg`, which strips
AI-assistant signature trailers (`Co-Authored-By: Claude …`,
`Claude-Session: …`, `Generated with [Claude Code]` and the bare
claude.ai/code URL line) from every commit message and warns on stderr for
subjects over 72 chars, plus eleven chain-forward wrappers (pre-commit,
prepare-commit-msg, pre-push, …) that exec the repo's own
`$(git rev-parse --git-dir)/hooks/<name>` so per-repo hooks keep firing.

## Why

User ruling: no Claude signatures in commit history, any model, any repo
(rules/git.md § Commit message style; memory
feedback_no-claude-commit-trailers; backlog prop-20260722-123329-41). The
language rule alone depends on every future agent complying; the git-level
hook makes it mechanical for every commit path on the machine.

## Behavior notes

- Repos that set `core.hooksPath` locally (husky, lefthook) override global
  config; the strip does NOT run there. Known, accepted gap.
- Chain resolution must use `git rev-parse --git-dir` — `--git-path hooks/…`
  resolves through core.hooksPath back to this dir itself (bug caught by the
  mutation test: the chain silently self-referenced and a rejecting repo
  hook failed to block).
- Verified 2026-07-28, five-case battery in a scratch repo: trailer strip,
  clean-message passthrough, chain fire, chain reject (watched red then
  green), subject-length warning. Plus a post-install global-path commit.

## Rollback

`git config --global --unset core.hooksPath` restores per-repo hooks as the
only hooks. The dir itself is inert without the config.

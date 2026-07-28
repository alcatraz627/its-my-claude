# 0040 — commit signature gate: silent strip becomes hard block

## Summary

Two coordinated changes, owner-ruled 2026-07-28 ("make it a hard blocking
hook, don't make it leaky"). First, `~/.claude/git-hooks/commit-msg` (from
migration 0039) no longer strips AI-signature trailers silently: a message
carrying one aborts the commit with the offending line numbers printed.
Second, a new PreToolUse Bash guard
(`~/.claude/scripts/hooks/guard-commit-signature.sh`, registered in
settings.json) blocks two bypasses the git layer cannot see: a `git commit`
command whose text carries a trailer, and any `git commit` with
`--no-verify`/`-n`, which would skip the commit-msg hook. The
two-enhancement-product working copy of `.githooks/commit-msg` (local
hooksPath, outside the global dir's reach) is synced to the same block
behavior; that diff remains uncommitted pending the owner (protected repo).

## Why

The strip (0039) kept histories clean but was leaky by design: `--no-verify`
skipped it, local-hooksPath repos never saw it, and silent cleanup hid
non-compliance. The owner wants violations refused, not laundered.

## Behavior notes

- Verified red/green 2026-07-28: git layer blocks a trailer commit naming the
  line, passes clean commits, and still chains to repo hooks; the guard's
  five-case unit battery (trailer command, no-verify, clean commit, non-commit
  claude.ai mention, git-log-with-pattern-in-args) all behave; the last two
  prove the pipe-boundary scoping does not false-fire.
- Known, accepted false-positive class: a commit message that *quotes* the
  banned strings (docs about the ban itself) is refused; reword the message.
- Known boundary, not a leak: commits created server-side (GitHub API,
  squash-merge, cloud sessions) never touch machine hooks.
- The settings.json registration takes effect for sessions started after this
  change; the git-level block is live machine-wide immediately.

## Rollback

Remove the guard entry from settings.json PreToolUse; revert
`git-hooks/commit-msg` to the 0039 strip version (git history);
`touch ~/.claude/.no-commit-signature-gate` mutes the guard machine-wide
without unregistering.

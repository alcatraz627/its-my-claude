---
name: file-gh-issue
description: File a MINOR technical issue to the current repo's GitHub Issues, with a human gate. Dry-run by default. Use when an agent surfaces a small technical cleanup worth tracking, or when a PR review bot's finding is genuinely wrong and the defect belongs to the reviewer rather than the diff.
---

## Brief

File a minor technical issue to whatever repo you are standing in, with a human
gate. Wraps `~/.claude/scripts/file-github-issue.sh`: dry-run by default,
`--confirm` to file, and the `gh` write is still approval-gated on top of that.

Lifted into the gcc on 2026-08-19 from enhancement-product, where it had been
used to file real issues, so that every agent can reach it. The original lives
on at `frontend/.claude/scripts/file-github-issue.sh` in that repo.

# /file-gh-issue

## When to use

- An agent surfaces a small, technical-only cleanup: dead code, a missing enum
  entry, config sprawl, a stale flag, a grounded correctness nit.
- **A PR review bot's finding is wrong.** This is the newer case, and it is why
  the skill is global. Arguing a wrong finding in the PR thread teaches the
  reviewer nothing, because the thread is not read back. An issue is the only
  channel that reaches whoever maintains the reviewer. See
  [[read-the-comments-on-a-pr-you-raised]] step 5, and link the PR in the body.

**NOT** for anything with product or business value. That belongs in Linear and
is the team's call, not an agent's.

## Procedure

1. **Ground the finding first.** Verify every `file:line` claim in the actual
   code before it goes into an issue. An outward artifact must not carry an
   unverified absence or behaviour claim: probe with `test -f` and
   `rg --no-ignore --hidden`, never a paraphrase. Sub-agent findings especially
   need re-grounding.
2. **Draft** the title and body. Put the body in a scratch file. Shape:
   `## What` / `## Where (verified)` with `file:line` / `## Options` / `## Scope`.
   When the issue is about a wrong review finding, add `## The finding` with a
   link to the PR comment, and `## Why it is wrong` with the evidence.
3. **Dry-run**, which renders the issue and files nothing:
   ```bash
   bash ~/.claude/scripts/file-github-issue.sh --title "<title>" --body-file <path> --label <label>
   ```
   Default labels are `agent-filed tech-debt`. Pass real repo labels explicitly
   so `gh` does not reject an unknown one.
4. **Show the user and get an explicit go.** Filing is outward-facing.
5. **File**: re-run the exact command with `--confirm`. The script stamps
   provenance and prints the issue URL.

## Notes

- The script runs `gh` in the current working directory, so it files against
  whichever repo you are in. Check that before `--confirm`.
- Never commit or push as part of this. Filing an issue is not a git op, but it
  is outward-facing, so it stays gated.
- Scope guard: minor technical only. If it needs a product or business decision,
  it is Linear's, not this skill's.

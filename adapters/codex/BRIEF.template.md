# Codex brief: <one-line title>

<!-- Written by the Claude planner, COMMITTED on the work branch before dispatch.
     Codex reads this file first; the launcher refuses a branch whose brief is
     untracked or dirty. Every section is a contract the handback answers.
     Copy to codex-briefs/YYYYMMDD-HHMM-<slug>.md in the repo (a TRACKED path;
     _*.claude.md files are git-ignored scratch and cannot be committed). -->

**Branch:** `<work branch>` (you commit here; never push)
**Dispatched by:** `<claude alias>` on <date>
**Builder:** Codex · **Reviewer:** Claude (the model that builds never grades)

## The slice

<Two to five sentences: what to build, in the planner's words, and what "done"
looks like as a state someone can check.>

## Files you may touch

- `<path>` (why)
- Anything not listed: read freely, edit only with a note in the handback saying why.

## Shared resources this seat may use

<Ports, databases, Docker names, external services, running servers. A worktree
isolates files only. "none" if nothing beyond the files above.>

## Checks that must pass

- `<exact command>` → <what green looks like>
- <a guard you must mutation-test: break it, see red, restore, see green>

## Parity: what already works and must still work

- <surface or flow> · check: `<command or steps>`

## Do-nots

- No push, no rebase, no amend, no history rewrite (guards enforce; do not route around).
- No new dependencies without a handback note.
- <task-specific>

## Handback

Write `_codex-handback-YYYYMMDD-HHMM.claude.md` per the core-dump skill, then
`bash ~/.claude/adapters/codex/bin/gcc checkpoint <file> "<summary>"` and
`bash ~/.claude/adapters/codex/bin/gcc ipc send --to-project . --no-reply-expected "codex done: <one line>"`.
The Verified section must carry the commit sha, `git diff --stat <base>..HEAD`,
and the pasted output of every check above.

# 0037 — pr-review demoted from a global skill to a project skill

## Summary

`~/.claude/skills/pr-review/` was removed on 2026-07-23 and the skill now lives at
`frontend/.claude/skills/pr-review/SKILL.md` inside the Versable enhancement-product
repo. Nothing replaces it globally: there is no `/pr-review` in `~/.claude/skills/`
anymore, and invoking it outside that repo will not resolve.

The move went with three edits the global copy could not carry. Step 0 now resolves an
absolute package root (`PKG=$(cd "$(git rev-parse --show-toplevel)/frontend" && pwd)`)
and builds every path from it, because the skill is invocable from both the repo root
and `frontend/` and the repo root has no `.claude/skills/GUIDELINES.md`. The report
output path moved from a CWD-relative `.claude/output/…` to `$PKG/.claude/output/…`.
A Notes block records why the skill is project-scoped, so a future agent does not
"helpfully" hoist it back to global.

## Why

The skill was global in location and project-specific in content. Phase 3's entire
convention set is one repo's stack — `useQ`/`useM`, TanStack Query cache invalidation,
NextAuth session handling, Drizzle schema/migration pairing, `src/app/api/**` routing —
counted at 15 stack-specific references in a 277-line file. In any other repo those
phases are dead weight that still consume the reviewer's attention, and the skill's own
`description` advertises them, so it routes into projects it cannot serve.

The user's framing settled it: it is targeted to one project because that is the only
project that needs it, and they had assumed it was already local. `frontend/CLAUDE.md`
had in fact listed `/pr-review` among its project skills for some time — documentation
that was drift before this migration and is accurate after it.

## What moved

| Before                                    | After                                                    |
| ----------------------------------------- | -------------------------------------------------------- |
| `~/.claude/skills/pr-review/SKILL.md`     | `frontend/.claude/skills/pr-review/SKILL.md`             |
| Step 0 reads `.claude/skills/GUIDELINES.md` (CWD-relative) | Step 0 reads `$PKG/.claude/skills/GUIDELINES.md` (absolute) |
| Report at `.claude/output/…` (CWD-relative) | Report at `$PKG/.claude/output/…`                       |

Replication to the repo's other worktrees rides git: `frontend/.claude/skills/` is
tracked, so a commit reaches each worktree on its next checkout. `sync-claude.sh` covers
the uncommitted case. As of this migration the project copy is **written but not
committed** — this repo forbids agent commits, so the human owns that step.

## Known limitations (accepted at migration time)

Discovery from the repo root is inherited behavior, not something this migration
configures: a skill under `frontend/.claude/skills/` is offered from anywhere in the
project, and the directory only decides precedence when two skills share a name. Verified
empirically this session by invoking the sibling `/release-changelog` from the repo root.
If that harness behavior changes, the skill becomes `frontend/`-only and Step 0's `$PKG`
anchor is what keeps it correct rather than what makes it reachable.

The underlying Step 0 boilerplate defect is NOT fixed by this migration — it is fixed
only in this one skill's copy. 33 of 221 global skills still open with the bare relative
`Read \`.claude/skills/GUIDELINES.md\``, which silently reads either nothing or the
project's guidelines in place of the global ones. Tracked as `prop-20260722-204245-15`.

## Rollback

`cp frontend/.claude/skills/pr-review/SKILL.md ~/.claude/skills/pr-review/SKILL.md` and
revert Step 0's `$PKG` anchor plus the report path to their CWD-relative forms. The
pre-move file is recoverable from the `its-my-claude` git history (it was tracked at
`skills/pr-review/SKILL.md`) and from the macOS Trash. No other file references the
global path.

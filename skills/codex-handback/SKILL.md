---
name: codex-handback
description: Reviews a Codex hands seat's handback: checks its review packet (sha, diff-stat, pasted check output) against the brief and branch, then runs the skeptical review over the seat's commits. Use after codex-gcc exec --brief, on a "codex done" doorbell, or when asked to review Codex's work.
allowed-tools: Read, Bash, Grep, Glob, Skill
user-invocable: true
argument-hint: "[handback path] [--base <ref>]"
---

## Brief

The reviewer half of the Codex hands loop. Codex built on a branch from a
committed brief and wrote a handback; this skill turns that packet into a
verdict without reconstructing what changed. The model that built never grades,
so this always runs on the Claude side (`~/.claude/features/codex-adapter.md`,
plan at `~/.claude/assets/reports/20260910-codex-hands-plan/PLAN.md`).

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` and apply its rules for the run. Read
`~/.claude/skills/codex-handback/runtime-notes.md` if it exists.

## Phase 1: locate the packet

1. Handback: the argument, else `_codex-handback.claude.md` in the repo root
   (a symlink to the newest timestamped file). Read it in full.
2. Brief: the file the handback's Goal names, else the newest file under
   `codex-briefs/`. Read it.
3. Branch and sha: from the handback's Verified section. Confirm with
   `git rev-parse <sha>` and `git branch --contains <sha>`. A sha that does not
   exist ends the review with ISSUES-FOUND, because nothing can be graded.

## Phase 2: check the packet before reading code

Each line is a pass or a fail written into the report:

- The Verified section carries the sha, a `git diff --stat`, and pasted output
  for every "Checks that must pass" line in the brief. A summary where output
  should be is a fail.
- Files touched (`git diff --name-only <base>..<sha>`) are within the brief's
  "Files you may touch", or the handback explains each exception.
- Parity rows in the brief: re-run each check yourself now
  (`rules/exercise-based-verification.md`); read the result, not the handback's
  claim.
- No push happened (`git log origin/<branch>..<sha>` shows the commits still
  local, or the branch has no upstream).

## Phase 3: skeptical review of the diff

Invoke `/skeptical-review` scoped to `<base>..<sha>` (pass the range). Its
findings plus the Phase 2 fails are the report.

## Phase 4: verdict and hand-off

Write `<repo>/.claude/output/<YYYYMMDD>-codex-handback-review/report.md` with
a one-line verdict (PASS / PASS-WITH-NOTES / ISSUES-FOUND), the Phase 2 table,
the review findings ranked, and the disposition per finding. Then one of:

- PASS: say the branch is ready to merge; merging is the owner's call unless the
  brief said otherwise.
- ISSUES-FOUND: write the next brief on the same branch (copy the template,
  fill "The slice" with the findings to fix), commit it, and dispatch through
  `codex-gcc exec --brief <path>` if the owner has authorised a second round.
  The loop has a floor: a second ISSUES-FOUND returns to the owner.

Record the outcome for the efficacy ledger:

```bash
bash ~/.claude/scripts/skill-log.sh record codex-handback --task "<slice>" --outcome accepted|revised|discarded --gate <verdict> --note "<rounds, defects found>"
```

## Validation

The skill worked when the report's Phase 2 table has one row per brief check
with a result you ran, the verdict line is first, and the seat's sha in the
report resolves in the repo. It failed if the verdict rests on the handback's
own claims.

## Notes

- Never merge, push, or rebase from this skill.
- A handback with `UNCONFIRMED` lines is honest, not a fail; the review runs
  those lines itself and reports what it saw.

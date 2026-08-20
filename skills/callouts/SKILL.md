---
name: callouts
description: Persists the owner's review findings as re-runnable acceptance rows per surface, and gates any later "done" claim on re-running the open rows. Use when the owner calls out a defect in review, before claiming done on a surface they have reviewed, or to list what they are still owed.
allowed-tools: Read, Bash, Grep, Glob
user-invocable: true
argument-hint: "[list | gate <surface> | retire <id>]"
metadata:
  maturity: prototype
---

## Brief

A call-out from a review round used to die with the round, so the next "done" was
verified against the agent's criteria instead of the owner's accumulated ones, and
the same spot regressed. This skill is the discipline around
`~/.claude/scripts/callouts/callouts.sh`: every owner finding becomes a row with a
check, a done-claim re-runs the surface's open rows first, and only the owner
retires a row. The agent may claim fixed; claiming is not closing.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## callouts:` entries in
`~/.claude/skills/runtime-notes.md`. The store is per project
(`<project>/.claude/callouts.jsonl`; the gcc uses `~/.claude/callouts.jsonl`).

## When rows are born

The moment the owner reviews and finds something: a visual defect, a prose defect,
a behavior deviation, a style miss. One row per finding, their words verbatim:

```bash
bash ~/.claude/scripts/callouts/callouts.sh add "<their words>" \
  --surface <page|file|doc|feature> --check "<how to re-verify it>" \
  --category visual|literary|technical|behavior
```

Write the check so a stranger could run it (a command, a screenshot to take and
what to look for, a line to read). Findings from /ui-gripe and
/ui-categorical-check that the owner confirms land here the same way; a review
finding that never becomes a row is a finding that will regress unseen.

## Before any done claim on a reviewed surface

```bash
bash ~/.claude/scripts/callouts/callouts.sh gate <surface>
```

Exit 1 lists the rows owed a re-check. Run each row's check for real (this is
exercise-based verification, not a read), record it
(`recheck <id> pass|fail --evidence "..."`), fix what fails, and only then claim:
`claim <id>`. A claim without a later pass keeps the gate closed on purpose.

## Retiring

Only on the owner's word, and recorded as such:
`retire <id> --by owner`. When they say "that one's fine now" in chat, that
sentence is the authorization; cite it in the turn.

## Boundaries

Never retire a row on the agent's own judgment. Never rewrite the owner's words in
a row. The store is per project and never committed (data ledger, allowlist
gitignore).

## Validation

Efficacy dimension: repeat call-outs in the same place stop happening. Checks:
(1) rows whose surface received a second same-category call-out after a retire,
counted per month, trending to zero; (2) every done-claim on a surface with open
rows shows a gate run in the same turn (grep the transcript for the claim and the
gate); (3) rechecks carry evidence a stranger could follow, sampled monthly.

## Runtime notes and ledger

Prepend a `## callouts:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh callouts <entry.md>` when a
run taught something. Then
`bash ~/.claude/scripts/skill-log.sh record callouts --task "<surface>" --outcome unknown --corrections 0 --note "rows=<n> gate=<clean|n unmet>"`.

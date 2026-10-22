---
name: directions
description: Maintains one DIRECTIONS.md per repo, the file the owner reads to pick what comes next. Builds it from recon, closes a row with proof, reports drift. Use for "directions", "what is this repo working toward", "mark X done". Not for session next steps (/recommend) or goal rows (/tasks).
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "[build | tick <id> [proof] | check] [--repo <path>]"
---

## Brief

`/directions` maintains one file per repo, `DIRECTIONS.md`: the document the owner
reads to choose what comes next. It groups the goal record's goals, plus issues and
gaps the record does not hold, under directions (what the work is for). "Waiting on
you" lists only what the owner can act on today, each with what happens if they say
nothing. The file is rebuilt rarely and edited often: `build` is a full recon and
rewrite, while `tick` and `check` touch one row or only read.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (forbidden paths, retries, timeouts, and §10,
since the output is a document a person reads). If the project has its own
`.claude/skills/GUIDELINES.md`, it wins where they differ. Read the `## directions:`
entries in `~/.claude/skills/runtime-notes.md`. "Waiting on you" applies
`~/.claude/rules/owner-gate-means-actionable-today.md`; read it before `build` or
`check`.

## Usage

```
/directions                       show the shape table and Waiting on you
/directions build                 recon the repo, verify, rewrite the file
/directions tick <id> [proof]     close or update one row, with its proof, and commit
/directions check                 report drift without editing
--repo <path>                     another repo (default: the git root of CWD)
```

## Locating the file

Resolve the repo root with `git -C <repo> rev-parse --show-toplevel`, then find the
file with `fd -H -t f '^DIRECTIONS.md$' <root>`. Use the one found; a new file goes
to `<root>/docs/plan/DIRECTIONS.md`. Two found is drift: say so and use the one under
`docs/plan/`. None found: bare and `check` say so in one line and offer `build`;
`tick` refuses. Read the file in full before any verb.

Tools the verbs lean on, each optional: `gh` (issues) and the goal record
(`~/.claude/scripts/goals/gs`; `gs --help` for the listing verb). When one is absent
or the repo has no goal record, skip the checks that need it and say which were
skipped.

## The file's shape

Reproduce this structure on `build` and preserve it on every edit. A repo whose file
already carries its own legend keeps that legend; this is the default for a new one.

1. Title, one line naming the reader ("the owner choosing what comes next"), and
   `_Last updated: <date>_`.
2. **How to read this**: the marks (direction, goal, accepted-when, gap) and the
   three value sets: when (now, next, later), state (needs you, waiting, parked,
   ready, done), origin (owner asked, measured, agent inferred). Id prefixes: `#n`
   goal-record row, `GH#n` GitHub issue, letters for recon rows.
3. **Where things stand today**: three to five lines; the biggest gap first.
4. **The shape**: the overview table, one row per direction, with when and state.
5. **Waiting on you**: `id | ask | if you say nothing`. Then one line naming what
   waits on other people.
6. One section per direction. Each opens with when and one sentence of what it is
   for, then one sub-section per goal with its accepted-when line and a
   `id | state | task` table. A gap nobody owns gets a gap line under its goal;
   parked rows go on one closing line.
7. **Sources**: the one section written for the agent acting on a row. One bullet
   per row or group, naming the commit, issue, file, run id or report that proves
   its state.

Rows are one short line. Proof never sits in a row; it goes in Sources. Commit
hashes, ids and paths stay in Sources even when a prose-style hook flags them.

## Show (bare)

Print the overview table and Waiting on you as they stand, plus the
`_Last updated_` date. If `git -C <root> log -1 --format=%cs -- <file>` is more
than a week older than `git -C <root> log -1 --format=%cs`, add one line
suggesting `check`. Do not edit.

## Build

Use when the file is missing, or its directions no longer describe the work (the
owner asks for a rebuild, or `check` finds more stale rows than live ones).

**Recon.** Dispatch the recon seats in parallel, sonnet, each read-only except its
one report at `<root>/.claude/output/<YYYYMMDD>-directions-recon/<seat>.md` (when
the root is `~/.claude`, use `~/.claude/assets/reports/<YYYYMMDD>-directions-recon/`
instead). For each seat, write a brief from `~/.claude/scripts/seats/seat template`
naming the repo root, the seat's row below, the report path, and "every item cites a
file:line, commit, or issue number", then build the prompt with
`~/.claude/scripts/seats/seat compose <brief> --role researcher --model sonnet`.

The default set, which a repo may trim or extend. A seat earns its place when it
answers a question the file must answer that no other seat covers.

| seat         | covers                                                                                               |
| ------------ | ---------------------------------------------------------------------------------------------------- |
| capabilities | what the product can do and what is broken: open issues and PRs, defect reports, review findings     |
| deferred     | work promised and not done, across the goal record, plan docs, checkpoints, memory and runtime notes |
| consistency  | where rules, docs, memory and code disagree with each other                                          |
| layout       | how the repo is organised and what a restructure would move                                          |

Check each report file exists before reading it, and cite the recon folder in
Sources so the reports stay findable.

**Verify before writing.** Every recon source can lag git, so a seat reports items
as open that a commit already closed. For every row you are about to mark open,
check it against git (`git log --oneline -S '<symbol>'`, `git log --grep '<id>'`,
the cited file at HEAD) and, when there is one, the goal record. A row git shows
done is written done, with the commit in Sources. A row you cannot check is written
with origin "agent inferred", never as measured.

**Group.** Rows group under goals, goals under directions. A direction is what the
work is for, in the owner's terms ("what shipped is seen working"), never a component
name. Order directions by when, then by what the owner asked first.

**Waiting on you.** An entry belongs there only if the owner can act on it today and
nothing else must happen first. Anything waiting on other work, or on another person,
moves to its direction or to the "waiting on others" line. Every entry has a default.

**Rewrite.** Replace the file; do not append to the old one. Carry over any open row
of the old file that recon did not see, under Sources as "still open from the
previous file". Then commit (see Committing) with a subject naming the rebuild.

## Tick

`/directions tick <id> [proof]` changes one row: its state, its task text, or both.

1. Find the row by id. If the id appears in more than one row, list them and stop.
2. Get the proof: what the owner passed, or the commit, run id, or file that shows
   the change. Without proof, a row cannot move to done; say what proof would do it.
3. Edit the row, its line in Sources, and anything it settles: the shape table's
   state for its direction, a Waiting on you entry it answers, "Where things stand"
   if it was the biggest gap. A goal whose rows are all done gets the done mark in its
   heading.
4. Update `_Last updated_` and commit (see Committing) as `Directions: <id> done`
   or `Directions: <id> <short change>`.

## Committing

Commit only DIRECTIONS.md. First run `npx prettier --write <file>` when prettier is
available, and `python3 ~/.claude/scripts/style/prose-lint.py <file>`; fix prose
findings in rows and headings, and leave Sources' ids and paths. If the repo is
protected (`~/.claude/protected-repos.list`, or `<root>/.claude/require-user-commit`
exists), stage the file and say it waits on the owner's commit. Otherwise commit with
the repo's own commit conventions (its CLAUDE.md title tags, no agent signatures).
Push only if the repo's rules already allow it.

## Check

Read-only. Each Sources pointer has a form, and each form has its test: a commit
hash, `git -C <root> cat-file -t <hash>`; an issue, `gh issue view <n> --json
state`; a file, whether it exists at HEAD; a goal-record row, its state in `gs`.
Report, one line each, ranked by how much each would mislead the owner:

- **Stale open**: a row not marked done whose pointer shows it done.
- **Stale done**: a done row whose cited file or issue no longer holds.
- **Not actionable**: a Waiting on you entry that waits on other work or another
  person, or that has no default.
- **Missing proof**: a row with no Sources line.
- **Orphans**: open issues (`gh issue list --state open --json number`) and open
  goal-record rows that no row's id cites.
- **Lost rows**: ids present in the file's previous commit
  (`git -C <root> show HEAD~1:<path>`) that are gone now without a done mark.
- **Duplicate file**: more than one DIRECTIONS.md in the repo.

End with the count, the skipped checks (no `gh`, no goal record), and an offer of
`tick` for each stale row. Never edit in `check`.

## Reporting back

After `build` or `tick`, reply in three lines at most: what changed (directions or
the row), the commit or "staged, waits on your commit", and the top Waiting on you
entry if it changed.

## Boundaries

- Not the goal record. `/tasks` renders goals, rows and acceptance from `gs`; this
  file cites them by `#n` and never copies their acceptance rows.
- Not "what now". `/recommend` answers the next step for a session or plan; this
  file is the repo-wide board it can read.
- One file per repo (`check` reports a second one).
- A row moves to done only with proof, and an open row leaves the file only as done
  or with a note of where it went (`check` reports lost rows).

## Validation

Efficacy dimension: the owner can choose what comes next from this file alone, and
every state in it is true today.

1. **States hold.** Take up to five open and five done rows, the most recently
   changed first (`git log -p -- <file>`), and run each one's Sources test from
   Check. Pass: every one agrees.
2. **Waiting on you is actionable.** Read each entry. Pass: every entry has a
   default, and none waits on other work or another person.
3. **Rows stay short.** Read the row tables. Pass: no task cell runs past one line
   or carries a commit hash, path or run id; proof sits only in Sources.

## Runtime notes and ledger

Prepend a `## directions:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh directions <entry.md>` when the
run taught something (a recon seat that kept reporting stale items, a legend a repo
needed changed). Then
`bash ~/.claude/scripts/skill-log.sh record directions --task "<verb> <repo>" --outcome unknown --corrections 0 --note "…"`.

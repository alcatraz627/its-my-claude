---
name: feature-doc-set
description: >
  Reads a feature branch and writes its audience doc set (owner brief,
  engineering guide, team brief, PR description) plus a review contract of
  the behaviors a build cannot assert: transient states, idempotence, counted
  numbers, cross-surface effects. Use when a feature PR is raised or reviewed.
user-invocable: true
argument-hint: "[base..head | branch | PR number] [--out <dir>] [--contract-only]"
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
---

## Brief

The set of documents a feature PR owes each of its readers, written from the
code on the branch rather than from the plan that preceded it, together with a
review contract that lists the behaviors only a running build can prove. Unit
tests and a green build say the code does what the code says; the contract
says what the feature must do for a person, row by row, and which rows have
actually been driven. The worked example is the pause, cancel and metering
feature in speedway, whose final folder the owner accepted as the shape.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` (or the project's
`.claude/skills/GUIDELINES.md` when one exists) and the `## feature-doc-set:`
entries in `~/.claude/skills/runtime-notes.md`. Read
`~/.claude/conventions/doc-writing.md` before drafting any of the four docs.

## Usage

```
/feature-doc-set                          the current branch against its base
/feature-doc-set main..HEAD               an explicit range
/feature-doc-set 81                       a PR number (range from gh)
/feature-doc-set --out <dir>              where the folder lands (default below)
/feature-doc-set --contract-only          the review contract alone, for a re-verification pass
```

| Argument                   | Meaning                                                                                     |
| -------------------------- | ------------------------------------------------------------------------------------------- |
| range, branch or PR number | What counts as the feature. Default: the current branch against the repo's main branch.     |
| `--out <dir>`              | Absolute output folder. Default `<repo>/.claude/output/<YYYYMMDD>-<slug>/final/`.           |
| `--contract-only`          | Regenerate `review-agent-contract.md` only, keeping the Verified column of an existing one. |

## Inputs

1. Resolve the range with `git merge-base` and `git diff --stat`; list every
   file the feature touches, then the callers and callees of the changed
   functions (`rg` the symbol names across the repo). The doc set describes
   the feature's reach, not its diff.
2. Find the behavior authority. In order: a committed behavior contract or
   validation doc for this feature, the owner's rulings in decision pages or
   checkpoints for the work stream, the proposal that started it. Where a
   working file disagrees with the code, the code wins and the disagreement is
   named in the README's superseded table.
3. Find the checks that exist: test files, smoke scripts, emulator suites that
   mention the changed symbols. These decide which contract rows are
   suite-backed and which are open.
4. Ask the owner one batched question only when a ruling the docs need is
   genuinely absent (a billing rule with two live readings, a control that is
   staff-only in one file and customer-facing in another). Everything else is
   read from the code.

## The read pass

Build the behavior inventory before writing a sentence. Each entry is a thing a
person can do or a thing that happens to them, with the file and line that
decides it. Sweep these categories in this order, because the later ones are
what a diff review misses:

- What a user can now do, and what stops going wrong.
- Every state the feature introduces and every transition between them,
  including the transient ones a screen shows for seconds.
- Every number the product counts or guarantees and that this feature
  changes (counters, receipts, prices, quotas, limits, scores), with the
  idempotence rule for each (counted once per what, keyed by what).
- Cross-surface effects: a count on one page fed by a filter on another, a
  badge, a sidebar, an admin view, an export, an email.
- Controls: which appear, which hide, for whom (customer, staff), in which
  state, and what each confirms before it fires.
- Refusals: what the feature says no to, with the exact copy.
- Edges: the thing that was already true when the feature ran (values already
  present, a file already swept, a cycle boundary), reruns, retries, a worker
  that dies mid-way.
- What the feature deliberately does not do, and where the plan said otherwise.

Then list the surfaces the feature touches (pages, tables, modals, banners,
emails) and the environments they must be read in: both themes, phone width,
customer and staff.

## The review contract, first

Write `review-agent-contract.md` before the prose docs; the docs cite it.

- One row per behavior: `Do`, `Expect`, `Verified`. `Do` is an action a person
  or a script can take against a running build. `Expect` names what is visible
  and what the data must say, never just a status badge.
- `Verified` takes exactly three values: `preview` with the date and build
  hash it was driven on, `suite` with the script that asserts it, or
  `UNCONFIRMED`. A row is never marked from memory; a row marked `preview`
  on an older build than the one under review is reopened, in writing.
- Every category from the read pass produces at least one row where the
  feature has anything in it: transient states, idempotence, the numbers the
  product counts or guarantees, cross-surface effects, hidden controls,
  refusals, edits on a stopped thing, both themes and phone width for touched
  surfaces, staff-only paths. A category with nothing in it is omitted, not
  padded.
- A `Rows that need attention` section follows the table: open rows, rows
  whose evidence is stale, and things no suite and no hand pass covers.
- A closing paragraph states what a failure means (the contract is the
  product behavior; a build that contradicts a row fails) and names any
  ruling still live.

With `--contract-only`, regenerate the rows from the code and carry each
existing `Verified` value forward only when its build hash is the current one.

## The four documents

Each has its own reader and its own register. Section shapes are fixed so a
reader of one feature's set can read the next without relearning it.

| Document               | Reader                          | Register                                                      | Sections                                                                                                                                                                                                                           |
| ---------------------- | ------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `owner-brief.md`       | The product owner               | Plain words, no code refs, what a customer sees and pays      | The controls a customer has · what each does · what is charged and what is never charged · allowances and prices · edge cases worth knowing · decided since the first draft                                                        |
| `engineering-guide.md` | A developer touching this later | Dense, file:line, contracts and invariants                    | One section per mechanism (state machine, settle rule, fence, receipts and idempotence, counting rules, verb derivation) · where each piece lives · running the checks · deploying a preview · things to know before changing this |
| `team-brief.md`        | The wider team                  | Two minutes, what shipped, what changed and why, what is open | What shipped · what changed from the proposal and why · what is open · where the detail lives                                                                                                                                      |
| `pr-description.md`    | The PR reviewer                 | The author's briefing, content-model first                    | What a user can now do · decisions a reviewer needs to ratify · verification boundary with a verdict line · reading the diff · follow-ups not in this PR                                                                           |

The PR description follows `/pr-description`'s law: the behavioral inventory is
the source, never commit subjects, and the file is handed over for the human
to paste. A `README.md` indexes the folder: what each doc is for, what it
replaces, what moved to `archive/` and why, where the code disagreed with the
working files, and a release readiness verdict with its evidence.

## The prose pass

Before delivery, on every file in the folder:

1. Strip local paths, session ids, scratchpad folders and screenshot
   locations. A doc names repo-relative paths and file:line pointers only.
2. Run `python3 ~/.claude/scripts/style/prose-lint.py <file>` and the
   em-dash scan; fix what they flag.
3. Route the voice pass to a fresh seat that did not write the docs: an
   `Agent` call pinned to sonnet, carrying `~/.claude/personas/doc-writer.md`
   as its role, the folder path, and the instruction to write its findings to
   an absolute path before returning. Read that file, then fix what it found
   or say in one line why not.
4. Re-read the Verified column one last time against the instruments named in
   this run; a claim without an instrument becomes `UNCONFIRMED`.

## Output

- The folder, with the six files above, at the `--out` path. Files the run
  supersedes move to `archive/` beside it; nothing is deleted.
- The delivery message: the absolute folder path, the count of contract rows
  by Verified value, the open rows, and one line offering to run the open rows
  on a preview. When the run is part of raising a PR, hand `pr-description.md`
  over for the human to paste; when the owner has asked for it to be posted,
  `gh pr edit --body-file` is theirs to approve first.

## Worked example

The pause, cancel and metering feature in the speedway repo (PR #81, branch
`pause-jobs-sept-21/aakarsh`): its folder
`.claude/output/20260918-pause-cancel-credits/final/` holds all six files in
the shapes above, and its `review-agent-contract.md` shows a Verified column
carried across three builds with the reopened and the suite-only rows named.
Read it before the first run in a new repo to calibrate register and row
granularity; do not copy its sections where the feature has nothing for them.

## Boundaries

- Never commits, pushes, deploys or edits the PR on its own authority.
- Never marks a contract row verified without naming the instrument and the
  build it ran on.
- Never writes a doc from the plan when the code disagrees; the code wins and
  the disagreement is recorded.
- Never carries the owner's words into a doc as if they were the spec; a
  ruling is cited as a ruling with its date.

## Validation

Efficacy dimension: the contract catches what the build cannot, and the docs
read at their reader's altitude. Checks:

1. For each contract row, grep the suites for the behavior it names. A row a
   suite already asserts is fine to keep as `suite`; the run passes this check
   when at least one row per category names a behavior no suite asserts.
2. `rg -n "/Users/|/home/|scratchpad|session" <folder>` returns nothing, and
   prose-lint reports no em-dash on any file.
3. When the owner reviews the feature after the run, no miss they call out is
   on a surface the contract listed as verified. Record misses through
   `/callouts`; a miss on a listed surface is a failed run and a runtime note.

## Runtime notes and ledger

Prepend a `## feature-doc-set:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh feature-doc-set <entry.md>`
when the run taught something (a category the read pass missed, a doc shape
that did not fit). Then
`bash ~/.claude/scripts/skill-log.sh record feature-doc-set --task "<feature>" --outcome unknown --corrections 0 --note "<rows by verified value>"`.

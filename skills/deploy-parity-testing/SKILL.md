---
name: deploy-parity-testing
description: Runs a parity test cycle when a service moves work to a new execution path (runner, provider, flag): plan rows with a spend class each, a seat brief, a fresh seat's report (failing test names, never counts), mutation-tested fixes, then the same cycle on dev and preview. Use before any cutover claim.
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Agent
user-invocable: true
disable-model-invocation: true
argument-hint: "<plan-file> [--env local|dev|preview] [--cycle <slug>] [--rows T1,T3,...]"
---

## Brief

A parity cycle checks that a new execution path produces the same thing the old one did,
in each environment the cycle runs (local, dev, preview), with a seat that wrote none of
the code doing the checking. This skill turns a plan's test rows into a seat brief with an explicit spend
class per row, dispatches the seat, reads its report, drives each finding to a fix with a
mutation test, and repeats on dev and preview with the rows that only exist off the box.
It exists because the same traps (a harness that miscounts, a cursor walk that stops
early, a port the gate refuses, a tag no trigger hears) each cost a turn the first time.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## deploy-parity-testing:` entries in
`~/.claude/skills/runtime-notes.md`. Read the project's `CLAUDE.md` for its spend fence
and its lane rules; the spend clause below is quoted from it, never paraphrased.

## Usage

```
/deploy-parity-testing <plan-file>                       local cycle from the plan's test rows
/deploy-parity-testing <plan-file> --env dev             the same cycle plus the off-box rows
/deploy-parity-testing <plan-file> --cycle <slug>        names the output directory
/deploy-parity-testing <plan-file> --rows T1,T12         a re-run of named rows after a fix
```

| argument      | meaning                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------ |
| `<plan-file>` | the plan of record, absolute path; its test rows (T-rows or equivalent) are the input      |
| `--env`       | `local` (default), `dev`, or `preview`; selects the environment table and the off-box rows |
| `--cycle`     | output directory slug under `<project>/.claude/output/<YYYYMMDD>-<slug>/`                  |
| `--rows`      | run only these rows; used after a fix, never for a first cycle                             |

## Preconditions, read from instruments

Refuse to plan until each of these is read from the named instrument, not from memory or
from a checkpoint:

- Every service under test serves the commit under test: `GET /build-info` (or the
  project's equivalent) on each, compared to `git rev-parse --short HEAD` in its tree.
- Unpushed work is counted with `git rev-list --count origin/<branch>..HEAD`; a number in
  a plan's prose is a claim, not a count.
- Launch ports come from `bash ~/.claude/scripts/dev-servers/ports.sh list`; framework
  defaults (8000, 5173, 3000) are refused by the gate and a proxy that hardcodes one means
  that surface cannot be started honestly without a config change, which is a finding.
- A Python entrypoint under pm2 needs `--interpreter none`; a process that reads online
  while its log is a node stack trace has not started.
- A service that starts with a dead credential in its log (`RefreshError`, `reauth`) is up
  and blocked on that credential at the same time; the row that needs it is written
  BLOCKED with the log line, and auth is never fixed from a seat.

## Rows and their spend class

Every test row in the plan becomes one table row: id, what to do, pass condition, spend
class. Three classes and nothing else:

| class        | meaning                                                                  | rule                                                                                                         |
| ------------ | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| free         | reads existing data, runs a suite, walks a cursor                        | no limit                                                                                                     |
| capture-mode | creates a job with `capture_request:true` or the project's no-spend flag | purged after the row                                                                                         |
| paid-capped  | a real provider call                                                     | named in the brief with a cap in parts and calls; the total is written; only rows the plan itself authorises |

A row that cannot run in this environment is written NOT RUN with the reason. It is never
dropped and never replaced by a lookalike (an events replay is not a callback test).

The spend clause the brief carries, quoted from the project's CLAUDE.md where one exists,
otherwise this house default:

> Do not trigger real work against a paid provider, and do not create jobs, runs, or
> records in order to inspect a surface. Look for existing data that already shows what
> you need; if none exists, come back and ask rather than creating it.

## The seat brief

One file, `<project>/.claude/output/<YYYYMMDD>-<cycle>/seat-brief.md`, four sections:

1. Dispatch clauses: model pin (sonnet, effort high), no sub-agents, scope close, the
   output path written before returning, the spend clause, read-only on shared trees (no
   `git add`, `stash`, `checkout`), never print a secret, never read `*user-notes.md`.
2. Environment table: service, URL, the check that proves it is the right build, and the
   local quirks that would otherwise read as failures (a local verifier that accepts any
   bearer makes two conformance rows fail by design; say so).
3. Rows table, in order, with the previous cycle's exact commands linked when they exist.
4. Not covered: what this environment cannot show, so the seat writes it rather than
   inferring it.

Dispatch the seat with the four clauses from `rules/subagent-dispatch-prompt.md`. The
seat's return is the report path plus one line per FAIL; anything longer is the report
pasted back and is not read.

## Reading the report

The report is `validation.md` beside the brief, one table: row, result, number,
instrument, not covered. Then findings with file:line, then bugs in the validation's own
tooling as a separate section, then the spend incurred.

- Read failing test NAMES. Three mutations can each print "2 failed" and fail different
  tests.
- A harness is a row too. Run its self-test (a planted known diff) before believing its
  numbers in either direction; one harness tripled a token count by summing per field.
- Cursor walks: `after=` present and empty on page one; a zero-row page is not the end
  while `more` is true.
- A finding in the seat's own tooling is not a defect in the service; keep the sections
  apart.

## Fixes and the re-run

Each finding is fixed by the building lane with a mutation test: plant the defect, watch
the named test go red, restore, watch it go green. Then `--rows` re-runs only the rows the
fix touches, live, against the restarted service. The report gains a "re-run" column;
nothing in the original table is edited.

## The deploy between cycles

- Read the build config's provision step before pushing, so a non-trivial step is known
  in advance. A deploy that does not go trivially is flagged to the owner and abandoned.
- Every push to a protected branch needs its own fresh owner approval (this house: the
  sentinel flow in `rules/git.md`, one touch per push, consumed on use). Batch the ASK
  into one message naming every push; the approvals themselves cannot be batched.
- A tag pushed with no trigger listening looks exactly like one with. The build's assert
  step and `/build-info` on the service are the instrument; a green push is not.
- A re-issued key is minted only if absent. A pre-existing key without a capabilities
  list stays that way; check with a request that needs the capability (a 422 naming the
  known capabilities means the old key). The key reaches a seat's environment from a
  terminal, never from a seat reading the secret store.

## The off-box rows

Added when `--env` is `dev` or `preview`, beside the local rows. These are CLASSES of
check; derive the project's own rows from them and skip a class the project has no
surface for (no queue means no forged-push row). The four below are one project's
derivation, kept as examples of the shape:

| class                             | one derivation                                                                         | pass                                                                     |
| --------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| auth boundary (forged push)       | the task-handler path with the queue's header forged and no identity token             | 403                                                                      |
| restart survival                  | one job of N items; the instance restarts mid-flight; usage events counted             | exactly N provider calls, one per item, counted from events not outcomes |
| latency comparison (stage timing) | the same file on the old path and the new, cold start measured separately and excluded | new ≤ old × the plan's factor                                            |
| concurrency (contention)          | two callers in flight on the shared queue                                              | measured and reported; a gate only when per-caller queues exist          |

The restart is an owner step when the seat may not run cloud commands: the brief hands
the owner one command at the moment the job is settling, with the seat's report waiting
on it.

## Handing over the walk

When the environment's rows are green, the owner gets the walk as exact steps: which
page, which file, what to read, what to press, what to expect. The moment it is ready,
not at the end of the cycle.

## Recording

The report path goes on the project log with the instrument and what it does not cover.
Task rows close with the same line. The checkpoint's verification-state line names the
report.

## Boundaries

- Never fixes a finding inside the seat; the seat reports, the building lane fixes.
- Never widens the spend past the brief; a row that needs more comes back as a question.
- Never runs cloud CLI commands when the project fences them; restarts and secrets are
  owner steps handed over as commands.
- Never edits a report's original table after the fact; re-runs are columns or new
  reports.

## Validation

Efficacy dimension: does a cycle catch the defects a cutover would have shipped, at the
spend the brief named. Checks: (1) every FAIL in the report has a file:line and a
matching fix with a red-then-green mutation test in the same work stream; (2) the spend
the report records is at or under the brief's total, with the actors named; (3) the
report's NOT RUN rows equal the plan's rows this environment cannot run, no more, no
fewer.

## Runtime notes and ledger

Prepend a `## deploy-parity-testing:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh deploy-parity-testing <entry.md>`
when the run taught something. Then
`bash ~/.claude/scripts/skill-log.sh record deploy-parity-testing --task "…" --outcome unknown --corrections 0 --note "…"`.

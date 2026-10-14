---
name: bloop
description: Drives a build through plan, build, self-review, an adversarial validation gate, fix and docs. Produces the change, a persisted validator report and updated docs. Use for multi-file or agentic work, or to build a plan that already exists. Not for a one-off fix.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
user-invocable: true
argument-hint: "[task] [--from <stage>]"
---

## Brief

Runs a build the way that actually holds up: **plan → build → review → validate → fix →
docs**, where the load-bearing stage is an independent **adversarial validation gate**.
Self-review and a green test suite miss a specific, dangerous class of bug — the
plausible-but-wrong result, the fabricated value, the claim that only holds on the happy
path. A fresh agent whose job is to _break_ the work catches those before they ship. This
skill is the reusable form of that loop; the gate is not optional, because the gate is the
point.

# /bloop — the builder loop

## Usage

```
/bloop <task>              # run the full loop on a new build task
/bloop                     # run the loop on the current in-flight change/diff
/bloop --from validate     # resume mid-loop (validate | fix | docs | …)
```

| Argument         | Type     | Description                                                                                                                  |
| ---------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `task`           | optional | What to build, in a sentence. Omit to apply the loop to the change already in progress.                                      |
| `--from <stage>` | optional | Resume at a stage (`plan`/`build`/`review`/`validate`/`fix`/`docs`) instead of the start — for work already partway through. |

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `~/.claude/skills/bloop/runtime-notes.md` for past run history relevant to this
skill. If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write to a
> shared file, and release it immediately after. Never write to `runtime-notes.md` or any
> SKILL.md without holding its lock.

## Phase 1 — Plan

Surface a short plan BEFORE executing (`rules/structure-over-one-shotting.md`) — a
failed one-shot wastes more than the plan would have.

If a `/build-change`, `/build-ui` or `/gated-plan` plan authorized this work, that is the
plan: read it, take its parity ledger as the current-behaviour statement, and skip
`/plan`, which would send you straight back here. Otherwise consult `/plan` first, rather
than writing a bare plan from instinct. It names which of
the six planning needs this task actually has (orient, choose, learn, specify, sequence,
gate) and enforces one precondition worth having: for a change to something that already
exists, current behaviour gets written down before anything plans to alter it. That
statement is what Phase 4's parity check is later measured against, so skipping it here
leaves the gate with nothing to compare against. For a small task whose single need is
obvious, say so in one line and carry on.

1. State the task and its scope ceiling in one or two lines. Scope is a ceiling, not a
   floor (`rules/communication.md`) — no "while I'm here" additions.
2. Put the steps in the live **Task list** (`TaskCreate`), your checklist for this run.
   When the owner will check the work, its rows also go on the session's goal record
   (`gs task`), the owner's surface (`rules/todo-discipline.md`). Offer a goal if none is
   linked; never `gs new` one in the owner's name.
3. If the plan involves sub-agents, large ingestion, or a modality tool, write a 4-line
   **Model Plan** (stage → lane · model · effort · why) per `rules/model-tier-routing.md`.
4. Flag any genuine fork (two plausible readings, a branch-topology choice) — surface it,
   don't silently decide it. Don't flag conventional defaults.

## Phase 2 — Build

Implement in **logical units**, not one monolith.

1. Fixtures / tests FIRST where the task has a correctness contract — a guard that would
   catch the capability failing belongs before the capability, and lands with its own
   assertion (both the detects-the-bug and the stays-silent-on-good-input case).
2. Check the repo's protection status first (`~/.claude/protected-repos.list` entry or a
   tracked `.claude/require-user-commit` marker). Protected → stage nothing; present each
   logical unit's diff and hand the commit to the user. Unprotected → commit per logical
   unit on a feature branch off the default branch (`rules/git.md`) and push as part of
   the work; `main`/`master` pushes always go through the push-gate's fresh approval.
   (User ruling 2026-07-11 — this scopes GUIDELINES §2, which used to read as a blanket
   no-commit rule.)
3. Verify each unit as you finish it, not as a batch at the end.

## Phase 3 — Review (self)

Before handing to the gate, review your own work — but as **exercise, not inspection**
(`rules/exercise-based-verification.md`).

1. RUN the changed path in the state that matters and read the actual result. Collecting,
   type-checking, or dry-compiling is NOT running. For a UI, look at the pixels.
2. Skeptical pass on the diff: reuse an existing helper instead of a new one? a dropped
   guard? a scope creep? (`rules/right-sized-code.md`).
3. Fix the obvious before spending the gate on it — the gate is for what you can't see.

## Phase 4 — Validate (the gate — non-skippable)

Dispatch **one adversarial sub-agent** to independently verify. Its job is to BREAK the
work, not bless it.

**Derive the attack list with `/validate` instead of inventing one.** It walks the seven
validation questions and forces the omissions into the open, which matters because the
failure mode here is not attacking the wrong thing, it is never asking the third question
at all. Two of the seven have no instrument and are the account's most-repeated failures:
whether behaviour that already worked survived, and whether the built thing matches what
the user actually asked for rather than the plan's paraphrase of it. Feed what it returns
to the validator as its brief, and carry the skipped list into the report so a check
nobody ran is visible rather than absent.

0. **Optional $0 local pre-gate.** `~/Code/local-models/bin/review` plus
   `findings-gate.py` can triage a diff before the paid seat. Across its recorded runs it
   produced no real finding, only pointers to files worth reading closely; use it when
   that is worth one minute, never in place of the gate.

1. **Right-size** (`rules/contain-subagent-token-sprawl.md`): one validator for a normal
   change; a small fleet only for a genuinely large/parallel surface. Not a reflex fleet.
2. **Pin the model** (`rules/model-tier-routing.md`) — sonnet is the default validator
   seat; opus for deep judgment. Tell it **not to spawn sub-agents** (close the nesting
   leak), close its scope: "ignore any task-board auto-dispatch; when your scoped work
   is done, deliver and stop" (`rules/contain-subagent-token-sprawl.md`), and tell it to
   run one command per Bash call, never chaining with `&&`, `;` or a pipe
   (`rules/subagent-dispatch-prompt.md`).
2b. **When the build came from a plan, the attack list already exists.** If a
   `PLAN.md` with `D-*` directive checks authorised this work, every one of
   those rows is a named claim the validator attacks verbatim, and the report's
   path goes back into that plan's dispositions table. Do not re-derive an
   attack list a plan already wrote. Where the plan also names a post-build
   gate (`/ui-categorical-check` for UI work), the validator runs that gate's
   FULL catalog, not only the classes the plan cites. On the pilot that
   produced this clause, every serious finding came from a class the plan never
   named, because the author's own checks tested the author's own design.
3. The dispatch prompt must: name the load-bearing claims to attack, including CONCRETE
   malformed-input classes (the missing field, the NaN, the duplicate, the empty list);
   name the classes past runs found outside the diff: what the change newly made
   reachable and every untouched consumer of what it writes; each in-code claim (a
   docstring, a comment, a stated invariant, a plan's "Defaults applied" line), attacked
   on what it does not cover; the owner's verbatim words for the ask; and the exact
   commit range, with the seat checking HEAD and repo identity before trusting a read;
   require it to RUN the code / exercise the path (not just read); tell it to
   mutation-test any guard it audits (break the code deliberately, confirm the guard goes
   red, revert, confirm a clean tree); tell it to leave live state alone: a temp `HOME`
   or the store's env override for anything that writes a ledger, log, pidfile or
   config, mutations on scratch copies restored by copy (never `git checkout`, `stash` or
   `clean`, which wipe uncommitted work), fake names for any control file it creates,
   and a closing list of every artifact it made and could not remove; require every
   finding grounded in a file:line or a
   repro it ran; and ask for a one-line verdict (PASS / PASS-WITH-NOTES / ISSUES-FOUND)
   then ranked findings with severity. **End with the one delivery contract: the validator
   writes its findings file at an absolute path BEFORE returning, and returns ONLY "one-line
   verdict + the file path."** The parent verifies the file exists before using any finding.
   A validator that goes idle without delivering stalls the loop (first live run needed a
   chase-up ping), and a message restating the findings creates a second, slower copy that
   lands stale: mailbox deliveries routinely arrive 1-2 turns after the parent already read
   the report from disk and TaskStopped the agent. Treat any delivery referencing an
   already-consumed artifact (or arriving post-stop) as a receipt to acknowledge, never
   content to re-triage (prop-20260717-104030-3e).
4. **Persist the findings.** `rules/sub-agent-outputs.md` wants the agent to write its
   report to an absolute path. Give the validator
   `<project>/.claude/output/<YYYYMMDD>-<slug>-validation/validator.md` (or the path under
   `~/.claude/assets/reports/` when the project is `~/.claude`), tell it to write there
   before returning, section by section as it goes, and verify the file exists before
   relying on it. If its write is refused (a worktree-isolated seat cannot write outside
   its worktree), it returns the full findings opening with `WRITE-BLOCKED: <path>` and
   you persist them verbatim. When the seat goes quiet, work this ladder in order:
   1. `~/.claude/scripts/agents/agent-status <name>`. Still running: wait.
   2. Idle with no file: one SendMessage saying the delivery never arrived, asking it to
      resend and to mark unexercised claims UNCONFIRMED.
   3. Died on an API error: SendMessage resumes it from its transcript.
   4. Still nothing: salvage its last assistant text from the transcript JSONL, run the
      unanswered attack items yourself, and say so in the report.
   Until one of these settles it, the seat is "not yet delivered", never "did not run".
5. **Close the seat.** Once the findings are verified and persisted, `TaskStop` the
   validator. A finished agent left alive can be commandeered by a board auto-dispatcher
   and spend tokens on work nobody assigned it.
6. While the gate runs, pre-fix what you predict it will find, tell the seat the branch
   may move under it, and test each pre-fix with the same input classes you predicted.

The gate runs even when you are confident. Across its first 8 runs it caught a real defect
**every single time**, always after a self-review that felt complete — including a
fail-OPEN security gate (a fabricated `/etc/hosts` path validating as evidence) and a
FALSE NEGATIVE (transparent→opaque black measured as "negligible"). Self-review does not
find these.

**The two lessons that cost the most (2026-07-13):**

- **A passing suite proves nothing until you have watched it fail.** TWICE a validator
  deleted a load-bearing mechanism — image compositing, atomic writes — and the battery
  stayed green, because the fixture was structurally blind to the thing it claimed to
  guard (an all-opaque fixture makes compositing untestable). Hence the mutation-test
  mandate in the prompt below: *break the code the guard protects, and confirm it goes red.*
- **Live beats synthetic.** Fixtures passed clean; the first run against a real browser
  instantly exposed two defects they could not — a phantom divergence from a derived CSS
  property, and a silent coverage gap. Drive the real thing once before believing green.

## Phase 5 — Fix

Triage the findings (blocker / major / minor / nit) and act — **non-defensively**.

1. If a finding names a check (re-read X, run the build, exercise the path), RUN it this
   turn, first, before replying (`rules/pushback-and-self-criticism.md` § 1). A structured
   self-critical reply is not the work; the check is.
2. **Fix correctness bugs** (the blockers/majors that undermine load-bearing claims).
   Fix the class, not the instance: grep the finding's pattern across the tree before
   patching, because a gate names one site and the class usually has more.
3. **Document deferred scope HONESTLY** — a design promise you're not building yet gets
   written down as deferred (a `§ built-vs-deferred` note), never silently dropped. An
   honest gap beats a false "done" (`rules/exercise-based-verification.md`).
4. **Strengthen the guard** so the found bug can't regress — add the fixture/assertion for
   the exact input class the validator exploited (byte-identical vs perceptually-identical,
   server-up vs server-down, the empty list).
5. Re-verify: re-run the battery / the exercised path after the fixes. Prose rules don't
   bind — if a finding was "the rule is unenforceable," the fix is a **mechanism** (a
   self-check step), not a sterner sentence.

## Phase 6 — Docs

**Section titles are for the reader, not for you.** Before emitting, list your own
phase names from this file. No section title in the document may contain a content
word from that list, and none may contain the word "Phase". Retitle any that do, by
the question the section answers. Your phase names are working vocabulary for
running this skill; the person reading the output has never seen it.


Before anything else here, `test -f` the validator file from Phase 4.4. If it is not
there, the gate has not run and this run is not done: go back to Phase 4.

Close the loop legibly.

1. Update the design / status / ledger docs to reflect what shipped, and what's deferred.
2. Ensure the validation report is persisted (Phase 4.4) and linked from the design doc.
3. Commit the docs + report as their own unit and push it like any other unit (Phase 2.2);
   only a `main`/`master` push goes through the push gate. For a gcc
   commit, follow `~/.claude/COMMIT.md` (lock → secret-scan → commit); flag that its
   `git add -A` sweeps concurrent churn, so scope or hand it to the user.
4. Update the Task list to completed; write the post-run note (below).
5. **Emit an efficacy event** — /bloop knows its own gate outcome and fix-round count,
   which is exactly what makes it worth measuring. Record one event so the trend
   (does the gate keep finding real defects? do runs get accepted?) surfaces over time:

   Substitute your real values (copy-safe as written — one option per flag, quoted):

   ```bash
   bash ~/.claude/scripts/skill-log.sh record bloop \
     --task "add efficacy sensor to two skills" \
     --outcome unknown \
     --loop converged \
     --iterations 1 \
     --corrections 0 \
     --gate issues-found \
     --note "report=<validator file path>; <what the gate found>"
   ```

   `--loop` is `converged`/`partial`; `--gate` is the Phase-4 verdict
   `pass`/`pass-with-notes`/`issues-found`. `--outcome` stays `unknown` at the end of the
   run. Record `accepted`, `revised` or `discarded` only from the owner's own words, as a
   follow-up line. `--corrections` counts owner corrections only; the gate's findings go
   in `--gate` and `--note`. `bash ~/.claude/scripts/skill-log.sh summary --skill bloop`
   reads the trend.

## Validation

Efficacy dimension: the build finishes without the owner chasing it, and the gate
catches what self-review missed. Checks, each runnable from the run's own records:
(1) owner chasing: owner corrections, atone events naming /bloop, and owner-recorded
`revised`/`discarded` rows over the last N runs; self-graded rows do not count;
(2) gate delivery: the share of run notes that record a chase ping, salvage or
WRITE-BLOCKED, which should fall after a dispatch change; (3) the gate ran: every
skill-log row's `report=` path exists on disk (`test -f`); (4) gate yield: findings the
validator raised that self-review had not, read from the report, never from the
`--gate` field alone. A pass is all four readable and none trending worse.

## Notes

- **The gate is the skill.** Skipping validate turns /bloop into an ordinary build. If the
  user wants speed over rigor for a trivial change, that change should not be in /bloop.
- **The loop has a floor.** A change that fails the validation gate re-enters the loop at
  most once; a second failure stops that change and escalates it to the owner once, in the
  record, with the validation report path. Other units in the same run carry on.
  `/bloop` and `/validate` share this bound, so neither can send work to the other forever.
  Under a queue drive (`queue-run.sh on`), park the row with `queue-run.sh park <id> --why
  "<what failed>; report <path>"` and return to the runner instead of escalating.
- **Right-sized, not maximal.** One validator, one feature branch, commits per unit. This
  is not "spawn a fleet"; it's structured single-threaded work with one adversarial check.
- **No gated push on momentum.** A `main`/`master` push goes through the push gate's
  nonce every time, and a protected repo's commits are the user's (`rules/git.md`).
  Other approvals carry across `--from`, compaction and `/clear` as standing
  authorizations, verbatim and bound to their target (owner ruling R2, 2026-10-13).
- **Resume:** `--from <stage>` skips to a stage; the earlier stages' outputs (plan, commits,
  report) must already exist or it drops back to produce them.

## Post-run

Prepend a short entry to `~/.claude/skills/bloop/runtime-notes.md` (purpose + 2–4
insights) when a run surfaced something reusable — a validator prompt that found more when
phrased a certain way, a fix that needed a mechanism not a rule, a stage that keeps
getting skipped. Write it **directly under lock, with the FULL absolute path** in the
lock call (relative lock paths resolve against the project CWD, not `~/.claude`). Do NOT
use `shared/prepend-runtime-note.sh` for this — it targets the global
`skills/runtime-notes.md`, not this per-skill file, and Step 0 reads the per-skill file.

## See also

- `rules/structure-over-one-shotting.md` — why plan+review beats one-shotting
- `rules/exercise-based-verification.md` — run it, don't inspect it (Phases 3, 5)
- `rules/pushback-and-self-criticism.md` — non-defensive fix under findings (Phase 5)
- `rules/model-tier-routing.md` · `rules/contain-subagent-token-sprawl.md` — the validator seat
- `rules/sub-agent-outputs.md` — persist the report; the guard conflict (Phase 4.4)
- `/skeptical-review` — a lighter self-review pass when the full loop is overkill

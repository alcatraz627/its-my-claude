---
name: deadline
description: Run work against a hard deadline while spending the user's scarce return visits as the true currency — one front-loaded decision exchange, reversible-default autonomy with a veto ledger during absences, pre-authorized scope shedding as the burn projection slips, and a fixed decision-first brief at every return. Rare-use, high-stakes; arm it when a real commitment with a clock is at risk. For ordinary work with the user present, don't — the skill itself pushes back if deadline machinery adds nothing.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, Agent, Skill
user-invokable: true
argument-hint: "<when> [goal] | check | off"
---

## Brief

The scarce resource is not agent time and not turn count — it is the user's
attention at unpredictable return moments. An agent that blocks on a question
at minute 7 of a 2-hour absence wastes 113 minutes; the same agent with a
pre-authorized default wastes zero. One conversion powers everything here:
**synchronous consultation → asynchronous review.** Questions become one
batched exchange, decisions become defaults-plus-veto-ledger, status becomes
glanceable state, and blocking becomes pre-authorized shedding.

**Objective (not "minimize turns" — the user rejected the literal reading):
maximize work-completed per unit of user attention, and never sit idle-blocked
during an absence.** Two acceptance metrics: away-time utilization (~100%) and
attention-yield (every return resolved something load-bearing). Asking a cheap
question while the user is PRESENT is good spend; the failure is needing one
while they are gone.

Settled user rulings (2026-07-18, confirmed): reversible-by-default execution
with a veto list · sequencing strategy proposed per-situation, never hardcoded
· returns lead with the decision queue, status after · re-baseline continuously
and surface the cut list unprompted.

## Step 0: Load Shared Guidelines and Runtime Context

Read `~/.claude/skills/GUIDELINES.md` and `~/.claude/skills/deadline/runtime-notes.md`
(if present) before proceeding. Lock protocol applies to every shared-file write.

## Usage

```
/deadline <when> [goal]     arm against a hard time ("6pm", "EOD", "tue standup")
/deadline                   arm onto the work already in flight this session
/deadline check             render the return brief on demand
/deadline off               land early: final state, retro, disarm wake
```

## Phase 1 — Arm: the single upfront exchange

This is the ONLY guaranteed synchronous turn; it earns its cost by deleting
future blocked ones. In order:

1. **Fix T absolutely** (clock time + date, timezone-aware) and subtract a
   safety margin (default 15% of remaining runway). All projections target
   T-minus-margin, never T.
2. **Define DONE as a checkable artifact** — a demo-able flow, a passing
   suite, a deployed URL. Never "mostly working". If the user's goal phrasing
   is not checkable, converge it in this exchange.
3. **Limits-runway check (do not skip):** run
   `bash ~/.claude/scripts/wake/limits-check.sh` and project the usage window
   against T. If the window plausibly closes before T-minus-margin, say so NOW
   — "your 5h window is the real deadline" — while the user can still act.
   No plan survives an empty tank; this is the collision both first-draft
   designs missed.
4. **Decompose into parts**, tagging each: estimate · reversible? ·
   blocks-others? · needs-you? Assign every part a ring:
   - **CORE** — the commitment itself; what the team sees at T
   - **HARDENING** — what makes it not embarrassing (error paths, obvious
     edge cases, verification depth beyond smoke)
   - **POLISH** — everything else
   The rings ARE the pre-authorized shed order — the user agrees to it here,
   so shedding later needs no turn.
5. **Propose a sequencing strategy with reasoning** from the tag counts —
   riskiest-and-unblocking-first / critical-path-first /
   fastest-visible-progress-first — user confirms or overrides (their ruling:
   situation-chosen, never hardcoded).
6. **Front-load every foreseeable decision** into one pre-answered surface
   (`/decision-wizard`: inline menu for ≤3 picks, the :5197 page for more).
   For the unforeseeable, pre-authorize reversible defaults: "if X turns out
   to be Y, I take Z unless vetoed."
7. **Capture the availability forecast** ("here ~10min, gone 2h, back after
   dinner") and schedule needs-you parts INTO presence windows; mechanical
   parts fill absences.
8. **Arm `/wake`** (its halt-check discriminates deliberate stops). An API
   death 10 minutes into a 2-hour absence is the worst deadline failure;
   wake caps it at ~one interval.
9. **Write the Deadline state block** (format below) into the session
   workspace doc `session-notes/<sid>.md` — the authoritative status surface.
   Mirror to the Task tool only as a courtesy when it exists; it is
   unprovisioned on some harness versions (prop-20260717-070332-3b), and a
   deadline run must not depend on it.
10. **Push back when unwarranted:** if the task gains nothing from deadline
    pressure ("40 minutes of work and you're here"), say so and don't arm.

## Phase 2 — Run: autonomous stretches

- **Reversible-by-default.** On any fork the agent cannot resolve alone: take
  the most defensible reversible option, log it to the **veto list** with a
  revert cost, keep working. HALT only for the irreversible set — deploy,
  delete, external send, spend, destructive migration — plus any per-run
  additions the user named at arm time.
- **Three-signal burn ledger** (never blend them — each maps to a different
  user lever), updated at part boundaries with clock time from WAL/checkpoint
  timestamps, never felt duration:
  - **DRIFT** = actual/est on completed parts (EWMA) — "are estimates low?"
  - **GROWTH** = new parts added mid-run, each with its own estimate,
    attributed out loud ("added bulk-import, +1.5h — scope, not slippage")
  - **BURN** = projected finish vs T-minus-margin — the bottom line
- **Side goals classify into a ring at intake, out loud:** "lands in POLISH;
  survives only if CORE closes by HH:MM." The tradeoff surfaces when scope
  shifts, never silently at 3 AM.
- **When BURN crosses T-minus-margin:** shed pre-authorized rings outward
  (POLISH first) automatically and REPORT the shed. If projections demand
  cuts deeper than the pre-authorization (into CORE), compose the
  regret-ranked cut list for approval — and while it pends, keep executing
  the surviving CORE parts; a pending decision never idles the run.
- **Fan-out is in scope.** Independent parts (blocks-others: no) may run as
  parallel sub-agents under the standing model-tier and sprawl rules —
  deadline raises parallelism, never the tier ceiling or the gates.
- **Gates scale per ring:** CORE ships through the adversarial gate
  (/bloop-grade), HARDENING gets targeted verification, POLISH a smoke run.
  A gate-skipped 4 AM delivery is the failure this skill exists to prevent;
  verification is never in the shed order.
- **Glanceable state:** keep tab-title showing T-minus + on/off-track status
  (`~/.claude/scripts/tab-title/tab-title.sh`), so a passing glance costs
  zero turns.

## The Deadline state block (in the workspace doc)

```
## Deadline: <goal> — due <absolute datetime> (margin → target <T-minus-margin>)
Strategy: <chosen mode> (<reasoning one-liner>)
Baseline: <N> parts / est <H>h / start <t0> → projected <tP>
Now (<t>): DRIFT <x>x · GROWTH +<h>h (<parts>) · BURN → <projected> = ON-TRACK|SLIPPING
Limits runway: <window resets at / headroom note>

Parts (ring / est / actual / status / reversible):
  1  <part>   CORE / 45m / 40m / done / reversible
  2  <part>   CORE / 90m / --  / building / IRREVERSIBLE at deploy — WILL HALT
  ...

Veto list (reversible choices made in your absence — flip any in one line):
  - <choice> (<t>) — <why this default> · revert: <cost>

Decision queue (answer FIRST on return — pre-drafted, one word each):
  Q1 <question>: <optA> ✓rec / <optB> / <optC>

Shed log / cut list:
  auto-shed  <part>  POLISH  <t>  (pre-authorized)
  PENDING    <part>  CORE    needs your call — ranked by regret below
```

## Phase 3 — The return brief (fixed shape, decision-first)

Every user reappearance (any message counts as a return; `/deadline check`
renders it on demand) gets exactly this, in this order:

```
⏳ <N> decisions unblock the next stretch:    ← one word each, pre-drafted
BURN: on/off-track vs T — DRIFT and GROWTH split out
DID:  closed since your last visit
VETO: ledger delta — flip any in one line
NEXT: the standing plan if you leave right now
```

Ten seconds of attention: the decision lines alone are useful. Five minutes:
BURN and VETO spend it well. Never an open-composition question where a pick
works.

Lowest-attention channel, live today (verified against the code, not
assumed): the :5197 decision page's Submit button POSTs `/_submit/<slug>`,
writing `<slug>/.answer.json`; the agent watches that file (Monitor, or poll
`decision-page.sh answer <slug> --consume`) and wakes with zero chat traffic
— `features/decision-pages.md` §Submit-to-wake. `/wake` covers the
crash-recovery half: an outage that kills the watcher still gets revived.
Chat messages remain a return channel alongside it.

## Phase 4 — Landing

At T, at DONE, or on `/deadline off`: render the final state block, disarm
`/wake` (CronDelete), and append the retro to
`~/.claude/skills/deadline/runtime-notes.md` under lock:

- T hit/missed by how much · final DRIFT · GROWTH total
- **User turns consumed vs planned — the real success metric**
- Assumptions vetoed: each one is a mis-modeled preference; graduate it to
  memory/glossary so the next run guesses better
- If measured user-turns are not falling across uses, the skill is failing
  its one job — flag for design revisit.

## Acceptance bar (all must hold on a real run)

- [ ] Away-time utilization ≈ 100% — never idle-blocked during an absence
- [ ] Zero irreversible actions without the user
- [ ] Every return led with a pre-drafted one-pass decision queue
- [ ] DRIFT / GROWTH / BURN reported split, never blended
- [ ] Slip surfaced with shed/cut action BEFORE unrecoverable
- [ ] Full state survived /clear + compaction (workspace doc, verbatim in
      any Resume Contract: T, rings, veto list, decision queue)
- [ ] Ran correctly with NO Task tool present
- [ ] /wake armed; limits runway checked at arm time

## Validation Examples

### Example: Arm against a closing usage window

**Scenario:** `/deadline 4am` while the 5h limits window resets at 02:00.
**Expected behavior:**

- [ ] Phase 1 step 3 projects window-close against T BEFORE decomposition
- [ ] The collision is stated with the tradeoff ("fits before 02:00, or accept a manual finish") — arming never proceeds silently past it
- [ ] The state block records the limits runway line

### Example: Mid-absence slip within pre-authorization

**Scenario:** BURN crosses T-minus-margin during a 2h absence; POLISH parts remain.
**Expected behavior:**

- [ ] POLISH sheds automatically — no approval turn consumed
- [ ] The shed is logged and reported at the next return, never silent
- [ ] A cut reaching INTO CORE composes the regret-ranked list, and surviving CORE work continues while it pends

### Example: Harness without the Task tool

**Scenario:** Armed on a session where TaskCreate is unprovisioned.
**Expected behavior:**

- [ ] All state lives in `session-notes/<sid>.md`; no step depends on the Task tool
- [ ] The Task-tool mirror is skipped silently when absent

### Example: Return after a long absence

**Scenario:** The user sends any message after 2h; two veto entries and one queued decision exist.
**Expected behavior:**

- [ ] The reply leads with the pre-drafted decision queue, one-word answerable
- [ ] BURN is reported with DRIFT and GROWTH split, never blended
- [ ] The veto delta is shown flip-able in one line, and NEXT states the standing plan

## What this is NOT

Not a cron or daemon — a mode over one session's work (fan-out included).
Not a panic mode: gates never shed. Not frequent-use: rare, real
commitments only, and the skill says so when invoked without one.

## See also

- Design + comparison: `assets/reports/20260718-deadline-skill-design/`
  (merged from two independent designs; adversarial cross-review on file)
- `skills/wake/SKILL.md` — the outage defense this arms
- `rules/model-tier-routing.md` · `rules/contain-subagent-token-sprawl.md`
- `features/decision-pages.md` — the batched-decision surface

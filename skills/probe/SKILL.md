---
name: probe
description: Drives a defect to its confirmed mechanism before any fix: a runnable probe isolates the one unknown, the harness is ruled out first, and a second fix attempt on the same spot is refused without new evidence. Use when a fix did not work or a cause is still a guess.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
user-invocable: true
argument-hint: "<the symptom, or the file:line being re-edited>"
metadata:
  maturity: prototype
---

## Brief

The probe-confirm-fix doctrine lives in the rules and keeps being violated
(fix-without-root-cause, re-edit-thrash, patching-symptoms, dismissing-user
symptoms). This skill is the doctrine as a procedure with a counter: establish the
mechanism by experiment before touching the fix, and treat a second edit to the
same spot as the signal to stop editing and start probing. The owner's efficacy
bar for this class is the useful ratio: probes that confirmed a mechanism, over
probes run.

## Step 0

Read `~/.claude/skills/GUIDELINES.md` and the `## probe:` entries in
`~/.claude/skills/runtime-notes.md`. The doctrine's tags are in
`~/.claude/rules/testing-patterns.md` (`[root-cause]`, `[re-edit-thrash]`,
`[instrument-describes-the-wrong-moment]`).

## The procedure

1. **State the symptom as an observation, not a cause.** "The header renders
   black on dark" is a symptom; "the CSS var is wrong" is a hypothesis wearing a
   symptom's clothes. Keep the owner's report verbatim; a dismissed user symptom
   is a recorded mistake class.
2. **Rule out the harness first.** A network abort, a stale process, a cached
   module, a `.pyc`, a leftover env var, a truncated tool result: each reads as a
   product bug and is not. One command each, before any hypothesis about the code.
3. **Name the ONE unknown.** What single fact, if known, decides between the live
   hypotheses? If you cannot name it, re-read the failing path until you can.
4. **Build the probe.** A throwaway script or command (`probe-*.sh`, `probe-*.py`
   in the scratchpad) that isolates that unknown and prints a fact. It must be
   able to come out either way; a probe that can only confirm is a rationalization
   (`[mutation-test-the-guard]` thinking applies to probes too).
5. **Run it. Read it. Say the mechanism in one sentence.** "X happens because Y,
   proven by probe output Z." Only now is a fix authorized.
6. **Fix, then re-run the probe and the original symptom's check.** The probe
   going quiet plus the symptom gone is the done signal. If the surface has open
   call-outs, `bash ~/.claude/scripts/callouts/callouts.sh gate <surface>` before
   any done claim.

## The re-edit counter

Editing the same function or block a second time in one thread of work, without a
new probe fact in between, is the stop signal: return to step 3. A third edit
without a confirmed mechanism is not allowed by this skill; say so and probe. This
is `[re-edit-thrash]` made mechanical: hypotheses are free, edits are not.

## Boundaries

Never delete or "clean up" while probing; probes observe. Never attribute to the
code what step 2 has not cleared the harness of. Throwaway probes stay in the
scratchpad and are named `probe-*` so nothing mistakes them for product code.

## Validation

Efficacy dimension: the useful ratio (owner-named for this class). Checks:
(1) probes that confirmed or refuted a mechanism / probes run, from the skill-log
notes, aiming high; (2) re-edit-thrash and fix-without-root-cause recurrence in
atone, bending down across months of use; (3) sampled runs show the mechanism
sentence with its probe output, not a hypothesis promoted by repetition.

Maturity bar: the `maturity: prototype` flag flips to stable when check (1) shows
a confirmed-or-refuted mechanism on at least three real runs. Not before, and
never by a maturation pass alone; the flag is a claim about evidence, not effort.

## Runtime notes and ledger

Prepend a `## probe:` entry via
`bash ~/.claude/skills/shared/prepend-runtime-note.sh probe <entry.md>` when a run
taught something. Then
`bash ~/.claude/scripts/skill-log.sh record probe --task "<symptom gist>" --outcome unknown --corrections 0 --note "probes=<n> confirmed=<mechanism|refuted|inconclusive> harness-cause=<yes|no>"`.

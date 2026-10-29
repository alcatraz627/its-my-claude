---
name: probe
description: When a fix did not work or a bug's cause is still a guess, isolates the mechanism with one runnable check before any fix. Not for bugs whose cause is already confirmed.
---

# Probe

Establish the mechanism by experiment before touching the fix. A second edit
to the same spot without a new fact in between is the signal to stop editing
and start probing.

## Procedure

1. **State the symptom as an observation, not a cause.** "The header renders
   black on dark" is a symptom. "The CSS variable is wrong" is a hypothesis.
   Keep the user's report verbatim; never dismiss a symptom they reported.
2. **Rule out the environment first.** A stale process, a cached module, a
   leftover env var, a network abort, a truncated paste: each reads as a code
   bug and is not. One check each, before any theory about the code.
3. **Name the one unknown.** Which single fact, if known, decides between the
   live hypotheses? If you cannot name it, re-read the failing path until you
   can.
4. **Build the probe.** One command or throwaway script that isolates that
   unknown and prints a fact. It must be able to come out either way. A probe
   that can only confirm is a rationalization. In chat, hand the user the exact
   command to run and say what each possible output would mean.
5. **Read the result and say the mechanism in one sentence.** "X happens
   because Y, shown by output Z." Only now is a fix justified.
6. **Fix, then re-run the probe and the original symptom.** The probe going
   quiet and the symptom gone together are the done signal.

## The re-edit counter

Changing the same function or block a second time without a new probe fact in
between: return to step 3. A third change without a confirmed mechanism is
not allowed. Say so and probe.

## Boundaries

Probes observe. Never delete or clean up while probing. Never blame the code
for something step 2 has not cleared.

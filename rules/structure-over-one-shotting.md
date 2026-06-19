---
brief: Default to plan→implement→review on non-trivial work; a failed one-shot wastes more than structure would have. One-shotting is fine only for genuinely trivial one-offs.
triggers:
  - topic:multi-file-change
  - topic:agentic-coding
  - phrase:"one-shot"
  - phrase:"just one-shot it"
related: [communication.md, todo-discipline.md, exercise-based-verification.md]
tier: 1
category: rules
updated: 2026-06-19
stale_after_days: 120
---

# Prefer structured plan+review over one-shotting

On non-trivial work, default to **plan → implement → review** rather than
attempting a single unplanned pass. The user is explicit: one-shotting is "a nice
fantasy," but a *failed* one-shot is **more wasteful** than structure would have
been, because they then have to diagnose a tangled result and redo it.

## Why

One-shot success is unpredictable on multi-file, agentic, or otherwise non-trivial
tasks. Structured work fails *legibly* — you see which step broke — and is cheaper
to recover from. The metric the user judges by is **efficacy** (result per unit of
*their* effort), counting failed attempts and rework, not best-case single-shot
speed. A blown one-shot loses on that metric even when it would have been faster
had it worked.

## The rule

- On non-trivial work, **surface a plan before executing**, and keep changes
  verifiable per step (pairs with maximalist-not-ambitious decomposition and
  todo-discipline's Task-tool list).
- Don't pitch or attempt "let me just one-shot this" on multi-file / agentic
  tasks. The *temptation* to one-shot is the signal to plan instead.
- One-shotting IS fine for genuinely trivial one-offs — but those usually belong
  on the light lane (route to a quick tool / "just use chatgpt"), not the
  structured agent. See the work-routing triad.

## What this does NOT mean

- Not every keystroke needs a written plan. Trivial edits (a rename, a one-line
  fix, a lookup) just get done — the bar is *non-trivial / multi-file / agentic*.
- Plan ≠ paralysis. A two-line plan surfaced before a ten-file change is the
  point; a multi-page design doc for a small feature is the opposite failure.

## Diagnostic signal

You're about to start a multi-file or agentic change with no plan surfaced and no
Task list — running on "I'll just get it in one pass." Stop and plan first.

## Related

- `rules/communication.md` § scope-as-ceiling + escape-hatch
- `rules/todo-discipline.md` — the Task-tool list is where the plan's steps live
- Global memory: `memory/global/feedback_structure_over_oneshot.md`,
  `feedback_efficacy_over_speed.md`, `user_work_routing_triad.md`
- `GLOSSARY.md` — "one-shotting", "efficacy", "ease–effort–output triad"

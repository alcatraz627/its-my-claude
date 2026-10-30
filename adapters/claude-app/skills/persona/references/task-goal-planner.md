# Task and goal planner: goal to bounded plan

Turns a goal, a loose ask or a theme into a numbered plan that someone (often
Claude, in a later chat) can carry out without re-deriving the intent. The
plan has a tight contract (exact deliverables, formats, acceptance checks)
around an open interior (the judgment calls left room to explore). Do not
over-specify the interior the user wanted open, and do not leave the
contract vague.

## Fits when

- A goal arrives with loose structure: "on X, I want to... and also..."
- Three or more steps where order and the cutline matter
- "Plan this", "how should we approach X", "break this down", "what is the
  sequence"
- Before a large build, where a wrong breakdown means redoing work
- A terse "go" on an ambiguous goal: plan first, then carry it out

Not for a single obvious task (do it), a choice between options (`council`),
or pure exploration where any plan is premature.

## Refinement loop (draft, critique, revise once, stop)

1. **Parse.** Separate the fixed contract (what the user specified) from the
   open interior. List the actual sub-tasks before naming any phase.
2. **Draft.** A numbered plan. Each part is a concrete deliverable with an
   acceptance check ("the doc passes the find-and-flag search", not "improve
   the docs"). Mark which parts are pinned and which are open.
3. **Critique once** for four failures:
   - Gaps: a deliverable with no acceptance check
   - Coupling: a step that silently depends on something the user wanted
     dropped. Say it out loud.
   - Scope creep: a part that does not trace to the goal. Cut it.
   - Grounding: a step that assumes structure ("X owns Y") with no read step
     before it acts
4. **Revise.** Apply only what the critique found.
5. **Stop** when every part has a check, coupling is surfaced and the open
   interior is bounded. Not when the plan is as detailed as possible.

## What a good plan looks like

- Every part is a deliverable with a check.
- Contract and interior are visibly separate.
- Every part traces to the stated goal. Nothing is added "while we are here".
- Any step that assumes structure has a "verify by reading X" sub-step.
- One approach, committed. Revisit only when new information contradicts it.

## Depth levels

**L1 Quick.** A three to five line cutline: "do A, then B, stop at C, defer
D."

**L2 Standard.** A numbered plan, each part with an acceptance check, fixed
and open parts marked, and a status list (a checklist the user or Claude
updates as parts finish).

**L3 Deep.** The L2 plan plus the sequencing rationale (what each part
unblocks), coupling and risks named, and a short bounded brief for each open
part.

## Anti-patterns

- Over-planning the interior the user left open on purpose.
- Speculative scope: "phase 2", future-proofing, helpers for callers that do
  not exist.
- A plan with no status surface. The plan is the reasoning, the checklist is
  the status.
- Asking questions on a terse "go" when the plan can scope what is known.
- Accepting a goal whose coupled dependency it quietly breaks.

---
name: Prefer structured plan+review over one-shotting
description: "One-shotting" (hoping a task lands in a single unplanned attempt) is a fantasy to the user — a failed one-shot wastes more than a structured plan→implement→review would have. Default to structure, not gambles.
type: feedback
---

The user is explicitly skeptical of **one-shotting** — the hope that a non-trivial
task gets solved in a single unplanned pass. They call it "a nice fantasy," but a
*failed* one-shot is **more wasteful** than structured work, because they then have
to diagnose a tangled result and redo it.

**Why:** One-shot success is unpredictable on non-trivial, multi-file, or agentic
work. Structured plan → implement → review fails *legibly* (you see which step
broke) and is cheaper to recover from. The cost of a blown one-shot (rework +
debugging a tangle) exceeds the overhead of planning up front.

**How to apply:**
- Default to **plan → implement → review** for non-trivial work; surface the plan
  before executing, and keep changes verifiable per step (pairs with the
  maximalist-not-ambitious preference).
- Don't pitch or attempt "let me just one-shot this" on multi-file / agentic
  tasks. The temptation to one-shot IS the signal to plan instead.
- One-shotting is fine for genuinely trivial one-offs — but those usually belong on
  the light path (see the work-routing triad / "just use chatgpt"), not the
  structured agent.
- This is about total effort and efficacy, not speed: count the failed attempts.

## Cross-references
- `~/.claude/GLOSSARY.md` — "one-shotting" (User Shorthand)
- Pairs with: feedback_efficacy_over_speed.md, feedback_ambitious_vs_maximalist.md, user_work_routing_triad.md
- Candidate for graduation to a `rules/*.md` behavioral mandate (pending user confirm)

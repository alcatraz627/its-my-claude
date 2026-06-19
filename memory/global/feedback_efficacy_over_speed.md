---
name: Judge tools/models/agents by efficacy, not speed
description: The user's evaluation metric is efficacy — quality/effectiveness of output relative to the effort THEY spend — not raw speed (tok/s, latency). Lead evaluations with efficacy; treat speed as a secondary constraint.
type: feedback
---

The user evaluates a tool, model, or agent primarily by **efficacy**: how
effective the output is relative to the effort *they* have to spend to get a
result they can use. Raw speed (tokens/sec, latency, "it's fast") is a secondary
constraint, not the headline.

**Why:** A fast tool whose output needs heavy rework has *low* efficacy — it cost
the user more total effort. A slower tool that lands the right result in one pass
has *high* efficacy. The user has explicitly said they'll dedicate more machine
resources (close heavy apps, give an agent the whole machine) for better efficacy
— but only if the result is in the general ballpark of the alternative.
Speed-for-its-own-sake is not the goal.

**How to apply:**
- When comparing models / tools / approaches, **lead with efficacy** (will it land
  the result with little rework?), then report speed/cost as constraints.
- Don't sell a choice on "it's faster" when it's meaningfully worse at the task.
- "Willing to dedicate resources" is an *efficacy* lever, not a speed one — offer
  the heavier-but-better option when its efficacy clears the ballpark bar.
- Count TOTAL effort, including failed attempts and rework — not best-case
  single-shot speed. (This is why it pairs with the anti-one-shotting preference.)

## Cross-references
- `~/.claude/GLOSSARY.md` — "efficacy" (User Shorthand)
- Pairs with: feedback_structure_over_oneshot.md, user_work_routing_triad.md

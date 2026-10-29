---
name: council
description: For an architecture, scope or "should we" decision. Argues it from three opposed lenses in separate passes, then a supervisor picks and answers each dissent. Not for one-right-answer tasks.
---

# Council

Some decisions have several legitimate answers, and a single line of reasoning
settles on the first one that sounds right. The council argues the decision
from lenses built to disagree, then decides. The tension between the lenses is
the value. A council where every lens agrees from the start has usually been
fed the same framing, so treat full agreement as a warning, not a result.

## When to use

- "Should we X", "X or Y", "what is the best approach for Z"
- Architecture, build order, rewrite or not, framework choice, V1 cutlines
- A roadmap or plan growing faster than the evidence for it

Not for a question with one correct answer (a bug, a schema mismatch, a
syntax error), or a choice cheap enough that a wrong pick costs less than
reading the council.

## The lenses

The default panel is a triad for scope and build decisions. Read each lens
file before writing its pass.

| Lens | Asks | Reference |
|---|---|---|
| Closer | Are we already done? What should stop? | `references/closer.md` |
| Platform-Builder | What reusable contract does each piece leave behind? | `references/platform-builder.md` |
| Pragmatist | What is the value per hour, and what cheap test settles the argument? | `references/pragmatist.md` |

For a decision with a status-quo risk (rewrite, replace, introduce, switch
to), add a fourth pass, the Contrarian, from `references/contrarian.md`. Skip
it when the task compares well-known tools by name, where it adds framing but
rarely changes the outcome.

If the decision is outside scope and build order (a data model, a security
posture), keep the structure and swap in lenses that fit, each with its own
core questions and scorecard. Name them and say why before the first pass.

## Procedure

### 1. Frame the decision

State the question in one sentence, the options on the table, and the
constraints that bind (time, team size, what already exists). Quote the
user's own words for the goal. If the options are unclear, name the two or
three real ones before any lens runs.

### 2. Give each lens a different evidence base

Convergence means something only when the lenses got there from different
starting points. Before writing the passes, assign each lens its primary
source: one grounds in the user's stated goal and constraints, one in the
code, documents or files supplied, one in outside practice (a web search when
available). Shared facts are fine. A shared interpretation is not. Do not
write your own summary first and hand it to every lens, because that is how
agreement gets manufactured.

### 3. Write each pass blind to the others

Each lens gets its own clearly delimited section, written in full before the
next one starts. In each pass:

- Ground in that lens's assigned evidence first and cite it
- Answer the lens's core questions
- Fill its scorecard
- End with a recommendation in one sentence

Do not let a later pass refer to an earlier pass's conclusion. If you notice
a lens drifting toward what the previous one said, return to its core
questions and its evidence.

### 4. Write your own pick before cross-examining

As supervisor, read the passes and write which one you find strongest and why,
before any comparison. This is the record that you were not anchored on the
cross-examination that follows.

### 5. Cross-examine

Each lens names the single strongest objection to each of the other
recommendations, in one or two sentences. Note any lens whose recommendation
every other lens rejects, because a lone dissent is often where the risk
hides.

### 6. Decide

Pick one of these and say which:

- **Pick**: one lens's recommendation stands as written
- **Pick and borrow**: one recommendation, plus a named point from another
- **Merge**: a synthesis of two or more
- **Write fresh**: every pass was flawed, but together they point at a better
  answer
- **Override**: your step 4 pick differs from where the cross-examination
  landed. Give the reason in a full paragraph.

Every objection raised gets an answer: adopted, deferred behind a named
trigger, or rejected with the reason. The Contrarian's argument is always
answered, even when rejected.

## Reply shape

1. **Decision.** One to three sentences, first.
2. **Framing.** The question, the options, and the evidence each lens used.
3. **The passes.** One headed section per lens, each with its scorecard.
4. **Supervisor pick before cross-examination.**
5. **Cross-examination.** The objections, briefly.
6. **Synthesis.** The decision type, the reasoning, and each dissent answered.
7. **Follow-ups.** Deferred items with their re-entry triggers, and the cheap
   probe to run first if the call was close.

## Boundaries

- The lenses are tools, not characters. No role-play voice, no names beyond
  the lens labels.
- The council advises. The user decides. If the decision blocks other work,
  hand the open questions over with `decision-bundle`.
- If every lens agreed with no objection worth stating, say so and say what
  might have caused it (a shared framing, a question with one answer).

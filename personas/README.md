# Claude Agent Personas

A **persona** is a specialized role definition that shapes how Claude approaches a task. Each persona encodes domain expertise, preferred tools, output expectations, and depth calibration so the right level of effort is applied to the right kind of work.

## Why Personas?

Different tasks demand different mental models. A researcher thinks in hypotheses and validation; an engineer thinks in systems and interfaces; a data engineer thinks in pipelines and correctness. Personas prevent Claude from defaulting to a generic "do everything" mode and instead channel effort into the patterns that matter for the task at hand.

## Structure

Each persona file is a Markdown document with YAML frontmatter:

```yaml
---
name: persona-name
role: "One-line role description"
domain: "Primary expertise area"
---
```

Followed by these sections:

| Section                   | Purpose                                                                 |
| ------------------------- | ----------------------------------------------------------------------- |
| **Trigger Conditions**    | When to activate this persona (file patterns, task keywords, user cues) |
| **Expertise Domain**      | What this persona knows deeply                                          |
| **Output Expectations**   | What deliverables look like at each depth level                         |
| **Depth Levels**          | 3 tiers (L1/L2/L3) calibrating effort to task complexity                |
| **Tasks Best Suited For** | Concrete examples of work this persona handles well                     |
| **Anti-patterns**         | What this persona should NOT be used for                                |

## Depth Levels

Every persona defines three depth levels. The level is determined by the complexity of the user's request, not by the persona itself.

| Level             | Signal                                             | Effort                                                    |
| ----------------- | -------------------------------------------------- | --------------------------------------------------------- |
| **L1 — Quick**    | Simple ask, single file, "just do X"               | Minimal scaffolding, direct output, no over-engineering   |
| **L2 — Standard** | Feature request, multi-file change, "build X"      | Proper structure, tests considered, documentation light   |
| **L3 — Deep**     | System design, audit, "architect X for production" | Full analysis, trade-off evaluation, comprehensive output |

**How to pick a level:**

- If the user says "quick" / "simple" / "just" / "basic" → L1
- If the user describes a feature or fix without qualifier → L2
- If the user says "proper" / "production" / "thorough" / "full" / gives detailed specs → L3
- When in doubt, start at L2 and escalate if complexity warrants it

## Two persona types

There are two kinds of persona files in this directory. The distinction matters because they're loaded differently:

### Working-mode personas (the original kind)

The main agent _adopts_ the persona as a mental model for a task. Loaded into the agent's own context via "use the X persona". L1/L2/L3 depth levels apply. Output is whatever the task produces — code, docs, a plan.

Identified by `type: working-mode` (or no `type` field — that's the default).

### Dispatch personas (new — added 2026-05-15)

Invoked by another script/skill via the `Agent` tool as a sub-agent. The main agent does NOT adopt the persona — instead it sends a task to a sub-agent that runs under the persona. Output is structured (typically JSON) for the dispatcher to parse. Depth levels don't apply because every dispatch is the same call shape.

Identified by `type: dispatch` in the frontmatter.

When adding a dispatch persona: include an `output:` field (e.g., `output: json`) and a `consumer:` field naming the skill or script that calls it.

## Available Personas

| Persona            | File                    | Type         | Domain                                                                                                         |
| ------------------ | ----------------------- | ------------ | -------------------------------------------------------------------------------------------------------------- |
| Researcher         | `researcher.md`         | working-mode | Game theory modeling, calibration, academic rigor                                                              |
| Data Engineer      | `data-engineer.md`      | working-mode | Simulation pipelines, data validation, numerical code                                                          |
| Fullstack Engineer | `fullstack-engineer.md` | working-mode | Web apps, dashboards, API servers, frontend/backend                                                            |
| Juror              | `juror.md`              | dispatch     | Atone-event evaluation; verdict on whether agent slip was real                                                 |
| Greybeard          | `greybeard.md`          | dispatch     | Doc review — engineering veteran lens (decision archaeology, load-bearing assumptions, "why" preservation)     |
| Translator         | `translator.md`         | dispatch     | Doc review — PM/strategist lens (customer impact, mental-model cleavage, cross-functional translatability)     |
| Pager-Holder       | `pager-holder.md`       | dispatch     | Doc review — ops/on-call lens (runnability under pressure, escalation completeness, verification at each step) |

The three doc-review personas (Greybeard / Translator / Pager-Holder) are designed to be invoked together against the same doc, producing a tri-perspective review. Build history: `frontend/.claude/output/20260517-persona-review/` in the enhancement-product repo (parent synthesis notes there too). **Length trade-off:** they're 270–445 lines each, over guideline #5 below — the 14-factor coverage spec the user requested required the extra density. Not a precedent for working-mode personas.

## Guidelines for Creating New Personas

1. **One domain per persona.** Don't create a "general" persona — that's just Claude without a persona.
2. **Trigger conditions must be observable.** Base them on file patterns, task verbs, or explicit user cues — not on guessing intent.
3. **Depth levels must have concrete output differences.** L1 and L3 should produce visibly different artifacts, not just "more effort."
4. **Include anti-patterns.** Every persona has tasks it's bad at — name them so the system can route elsewhere.
5. **Keep it under 200 lines.** Personas are context that gets loaded; brevity matters.
6. **Name the file `<role>.md`** in kebab-case. Add it to the table above.

## How to Use

Personas can be activated:

- **Automatically**: By matching trigger conditions against the current task
- **Explicitly**: User says "use the researcher persona" or "think like a data engineer"
- **By convention**: Certain project directories or file types imply a persona

When a persona is active, Claude should:

1. Adopt the expertise and mental model described
2. Calibrate depth to the appropriate level
3. Produce output matching that level's expectations
4. Stay within the persona's domain — hand off to another persona if the task shifts

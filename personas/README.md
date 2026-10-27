# Claude Agent Personas

A **persona** is a specialized role definition that shapes how Claude approaches a task. Each persona encodes domain expertise, preferred tools, output expectations, and depth calibration so the right level of effort is applied to the right kind of work.

## Why Personas?

Different tasks demand different mental models. A researcher thinks in hypotheses and validation, an engineer thinks in systems and interfaces, and a data engineer thinks in pipelines and correctness. Personas keep Claude out of a generic "do everything" mode and channel effort into the patterns that matter for the task at hand.

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
| **L1: Quick**    | Simple ask, single file, "just do X"               | Minimal scaffolding, direct output, no over-engineering   |
| **L2: Standard** | Feature request, multi-file change, "build X"      | Proper structure, tests considered, documentation light   |
| **L3: Deep**     | System design, audit, "architect X for production" | Full analysis, trade-off evaluation, comprehensive output |

**How to pick a level:**

- If the user says "quick" / "simple" / "just" / "basic" → L1
- If the user describes a feature or fix without qualifier → L2
- If the user says "proper" / "production" / "thorough" / "full" / gives detailed specs → L3
- When in doubt, start at L2 and escalate if complexity warrants it

## Two persona types

There are two kinds of persona files in this directory. They are loaded differently, so the distinction matters.

### Working-mode personas (the original kind)

The main agent _adopts_ the persona as a mental model for a task. It is loaded into the agent's own context via "use the X persona". L1/L2/L3 depth levels apply. Output is whatever the task produces: code, docs, a plan.

These carry `type: working-mode` (or no `type` field, which is the default).

### Dispatch personas (added 2026-05-15)

Another script or skill invokes these via the `Agent` tool as a sub-agent. The main agent does NOT adopt the persona. It sends a task to a sub-agent that runs under the persona. Output is structured (typically JSON) for the dispatcher to parse. Depth levels don't apply because every dispatch is the same call shape.

These carry `type: dispatch` in the frontmatter.

When adding a dispatch persona, include an `output:` field (e.g., `output: json`) and a `consumer:` field naming the skill or script that calls it.

## Available Personas

| Persona            | File                    | Type         | Domain                                                                                                         |
| ------------------ | ----------------------- | ------------ | -------------------------------------------------------------------------------------------------------------- |
| Researcher         | `researcher.md`         | working-mode | Game theory modeling, calibration, academic rigor                                                              |
| Data Engineer      | `data-engineer.md`      | working-mode | Simulation pipelines, data validation, numerical code                                                          |
| Fullstack Engineer | `fullstack-engineer.md` | working-mode | Web apps, dashboards, API servers, frontend/backend                                                            |
| Juror              | `juror.md`              | dispatch     | Atone-event evaluation; verdict on whether agent slip was real                                                 |
| Greybeard          | `greybeard.md`          | dispatch     | Doc review through an engineering veteran lens (decision archaeology, load-bearing assumptions, "why" preservation) |
| Translator         | `translator.md`         | dispatch     | Doc review through a PM/strategist lens (customer impact, mental-model cleavage, cross-functional translatability) |
| Pager-Holder       | `pager-holder.md`       | dispatch     | Doc review through an ops/on-call lens (runnability under pressure, escalation completeness, verification at each step) |
| Doc Writer         | `doc-writer.md`         | dispatch     | Doc authoring + voice review: professional-copywriter register, AI-smell removal; applies `~/.claude/conventions/doc-writing.md` |
| Closer             | `closer.md`             | working-mode | Scope discipline / YAGNI: declare done, defer until a need pulls it (strategic-lens triad)                     |
| Platform-Builder   | `platform-builder.md`   | working-mode | Architecture sequencing / reusable substrate: realize the vision without over-abstracting (strategic-lens triad) |
| Pragmatist         | `pragmatist.md`         | working-mode | Value-per-effort triage / cheap-option-buying, with DO-NOW/DEFER/KILL scorecards (strategic-lens triad)         |
| Art Director       | `art-director.md`       | working-mode | Vague impulse → realized image: guided creative brief (TUI wizard), direction synthesis, prompt + pipeline design, generate→critique→refine for local image gen |
| Motion Illustrator | `motion-illustrator.md` | working-mode | Hand-authored animated SVG for READMEs and docs: project-noun scenes, SMIL/CSS motion within GitHub's `<img>` limits, dark/light palettes, render-checked; raster sibling of Art Director |
| Task/Goal Planner  | `task-goal-planner.md`  | working-mode | Goal/ask/theme → bounded numbered plan that seeds the Task tool; separates fixed contract from open interior; draft→self-crit→revise→stop loop |
| Technical Doc Writer | `technical-doc-writer.md` | working-mode | Authors a real-value technical doc end-to-end (classify→ground→draft→find-flag→rewrite→render-check); routes the final voice pass to the dispatch `doc-writer` |
| Skeptical Reviewer | `skeptical-reviewer.md` | dispatch     | Harsh-but-focused code auditor; recurrence-weighted hunt list, re-anchor refinement loop, scoped `/magi` escalation; the reusable lens the `/skeptical-review` skill can dispatch |
| Web Researcher     | `web-researcher.md`     | working-mode | General multi-source web research: search→verify(≥2 src)→close-gaps→cited synthesis; honest Uncertainties; defers heavy deliverables to `/deep-research`. NOT the game-theory `researcher` |

The five personas authored or revised 2026-06-18 (planner, technical-doc-writer, skeptical-reviewer, web-researcher, plus the juror rewrite) each carry a **first-class refinement loop** (`identify → act → self-critique → revise → stop-rule`) and the **reflexivity rule**: the persona must not commit the slip it guards against. The reviewer cites its own file:line, the researcher cites every claim, the juror names a mechanical tell, and the doc-writer runs find-and-flag on its own draft. Grounding: `~/.claude/assets/reports/20260618-persona-grounding-scan/`.

The three strategic-lens personas (Closer / Platform-Builder / Pragmatist) are a complementary set for **scope / prioritization / "what-to-build-and-how-much"** decisions, and their tension is the value. They are designed to be dispatched together as MAGI voters; first run `~/.claude/assets/magi/20260609-1604-local-models-direction/`.

The three doc-review personas (Greybeard / Translator / Pager-Holder) are designed to be invoked together against the same doc, producing a tri-perspective review. Build history: `frontend/.claude/output/20260517-persona-review/` in the enhancement-product repo (parent synthesis notes there too). **Length trade-off:** they run 270–445 lines each, over guideline #5 below, because the 14-factor coverage spec the user requested required the extra density. They set no precedent for working-mode personas.

## Guidelines for Creating New Personas

1. **One domain per persona.** Don't create a "general" persona, because that is just Claude without a persona.
2. **Trigger conditions must be observable.** Base them on file patterns, task verbs, or explicit user cues, and avoid guessing intent.
3. **Depth levels must have concrete output differences.** L1 and L3 should produce visibly different artifacts, so "more effort" alone does not qualify.
4. **Include anti-patterns.** Every persona has tasks it's bad at, so name them and let the system route elsewhere.
5. **Keep it under 200 lines.** Personas are context that gets loaded, so brevity matters.
6. **Name the file `<role>.md`** in kebab-case. Add it to the table above.

## How to Use

Personas can be activated:

- **Automatically**: by matching trigger conditions against the current task
- **Explicitly**: the user says "use the researcher persona" or "think like a data engineer"
- **By convention**: certain project directories or file types imply a persona

When a persona is active, Claude should:

1. Adopt the expertise and mental model described
2. Calibrate depth to the appropriate level
3. Produce output matching that level's expectations
4. Stay within the persona's domain, and hand off to another persona if the task shifts

## Logging persona usage (efficacy trail)

Every persona invocation should leave a residue event so the efficacy of each persona is
reviewable over time. Dispatch personas log mechanically from their dispatch script or skill
(juror, skeptical-reviewer). **Working-mode personas log by convention.** When you finish
working under a persona, record it:

```bash
bash ~/.claude/scripts/persona-log.sh record <persona> --mode adopted --depth L2 \
  --task "<1-line>" --outcome accepted|revised|discarded --loop converged|partial \
  --corrections <N> --note "<what worked / what the persona missed>"
```

Review with `persona-log.sh summary` (per-persona outcome/loop/correction distributions).
The full design (the activation trigger, the dispatch-vs-working-mode split, the nudge) is in
[`features/persona-activation.md`](../features/persona-activation.md).

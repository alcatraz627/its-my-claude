---
name: Work-routing by the ease–effort–output triad ("just use chatgpt" mode)
description: The user routes a task to a tool by weighing ease (of invoking), effort (their own input), and output (quality needed). Low-stakes one-offs go to ChatGPT or a small local model; structured heavy work goes to the agent. "Just use chatgpt" = the light path, not a knock on the agent.
type: user
---

The user mentally routes each task across an **ease–effort–output triad**:

- **Ease** — how little friction it takes to invoke the tool
- **Effort** — how much of their own input/structuring it demands
- **Output** — the quality bar the task actually needs

From this they pick a lane:

| Lane | When | Tool |
|---|---|---|
| **"Just use chatgpt"** (light path) | one-off, low-stakes, acceptable-quality answer; quick lookup | ChatGPT / a small local `lm` model (`q`) |
| **The agent** (structured path) | multi-file, ongoing, must-be-right, Claude-Code-like feature work | Claude Code / a heavy local agentic model |

**Why:** Spinning up the structured agent for a trivial one-off is over-investment;
"just use chatgpt" is the deliberate escape hatch optimizing for ease + low effort.
Conversely, pushing heavy structured work through the light path under-serves the
output bar. Saying "I can just use chatgpt" is **not** a signal the agent is bad —
it signals the *task* is light.

**How to apply:**
- Don't over-engineer trivial asks — match the structure to the lane.
- Reserve heavy planning/review machinery for the structured lane.
- When the user invokes "just use chatgpt" / "use the small model," read it as a
  routing decision (the task is light), not a quality complaint.
- For the local-models project: the heavy local agentic tier exists to serve the
  STRUCTURED lane offline; one-offs stay on ChatGPT / small `lm` (`q`).

## Cross-references
- `~/.claude/GLOSSARY.md` — "ease–effort–output triad", "just use chatgpt (mode)"
- Pairs with: feedback_efficacy_over_speed.md, feedback_structure_over_oneshot.md
- local-models project: docs/GOALS.md (routing), the `q` small-model lane

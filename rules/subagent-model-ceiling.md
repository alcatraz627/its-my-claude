---
brief: Sub-agents are NEVER dispatched on the session flagship model (Fable/Mythos-class) — Opus is the hard ceiling for any sub-agent at any nesting depth; every dispatch pins model explicitly (sonnet default, opus only for judgment-heavy work) and must gate nested spawns
triggers:
  - tool:Agent
  - tool:Workflow
  - topic:sub-agents
  - topic:model-selection
  - phrase:"spawn an agent"
related:
  - rules/sub-agent-outputs.md
  - rules/model-tier-routing.md
  - memory/global/feedback_subagent_model_never_fable.md
tier: 0
category: rules
updated: 2026-07-07
stale_after_days: 365
---

# Sub-agent model ceiling — Opus max, never the flagship

No sub-agent, at any nesting depth, ever runs on the session's flagship model
(Fable / Mythos-class / whatever tier sits above Opus). **Opus is the hard ceiling
for sub-agents**, reserved for judgment-heavy work the user has sanctioned. The
flagship is for the supervising main loop only.

Graduated 2026-07-07 from two same-day occurrences in the versable-builder planning
session (user: "do NOT CALL FABLE… keep this in mind" → recurrence → "Opus is the
highest for sub-agents. Add a rule for yourself"). Cost blast radius: fan-out research
on flagship pricing multiplies a cheap sweep into a large bill with zero quality gain.

## The rule

1. **Every `Agent` dispatch carries an explicit `model:` param.** Never rely on
   inheritance — an unpinned spawn can resolve to the session model (the flagship).
   Same for Workflow scripts: set `model`/`effort` per `agent()` call.
2. **Tiering:** `sonnet` = default for research, inventory, mechanical, capture work.
   `opus` = only for judgment-heavy analysis/review seats. `haiku` = trivial lookups.
   Flagship = never.
3. **Close the nesting leak** — this is how the ceiling was breached even with
   top-level pins in place. Every delegation prompt must include ONE of:
   - "Do NOT spawn sub-agents" (preferred for bounded tasks), or
   - "Any sub-agent you spawn must carry an explicit model pin of sonnet or lower."
4. In-flight agents are let to finish; the rule governs new dispatches.

## Diagnostic signal

You are composing an `Agent`/`workflow.agent()` call and the `model` field is absent —
or your dispatch prompt allows delegation and says nothing about the delegate's model.
Stop and pin both.

## Related

- [[model-tier-routing]] — extends this ceiling with the effort axis, the local-lm and
  gemini lanes, the Model Plan obligation, and the mechanical enforcement
  (`guard-model-tier.sh`: hard block on fable/mythos dispatch, warn on missing pin).

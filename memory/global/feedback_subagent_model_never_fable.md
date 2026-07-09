---
name: subagent-model-never-fable
description: Background/research sub-agents must NEVER run on Fable — pin model explicitly on every Agent dispatch (sonnet default, opus for judgment-heavy), and instruct spawned agents to pin models on THEIR sub-agents too
metadata:
  type: feedback
---

Background and research sub-agents must never run on the flagship model (Fable /
whatever the session's top-tier model is). Recorded 2026-07-07 after the user caught a
Fable-billed agent during the versable-builder planning session ("for bg sub agents for
research do NOT CALL FABLE"). **Recurred same day** despite top-level pins (nested
delegation leak) → graduated to a hard rule: the sub-agent ceiling section of
[[model-tier-routing]] in ~/.claude/rules/ (absorbed subagent-model-ceiling.md,
2026-07-09) — Opus is the ceiling for ANY sub-agent at ANY nesting depth.

**Why:** research/inventory/fan-out agents are volume work; flagship pricing turns a
cheap sweep into a large bill with no quality gain. The flagship is for the supervisor
loop, not the fleet.

**How to apply:**
- Every `Agent` dispatch carries an explicit `model:` param. Never rely on
  inheritance — an omitted model can inherit the session model (the flagship).
- Default: `sonnet` for research/inventory/mechanical work; `opus` only for
  judgment-heavy analysis the user has sanctioned; `haiku` for trivial lookups.
- When a sub-agent may spawn its own sub-agents, the dispatch prompt must instruct it
  to pin cheap models on those too (nested inheritance is the leak path).
- Same rule inside Workflow scripts: set `model`/`effort` per `agent()` call for fleet
  stages.

---
brief: Every sub-agent dispatch prompt carries five clauses. They are a model pin, no nested seats, a scope close, an output path written before returning, and one command per Bash call. This file owns the wording. /subagent walks the whole dispatch.
triggers:
  - tool:Agent
  - topic:sub-agent
  - topic:dispatch
related:
  - rules/contain-subagent-token-sprawl.md
  - rules/model-tier-routing.md
  - rules/sub-agent-outputs.md
  - skills/subagent/SKILL.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# The five clauses every sub-agent dispatch carries

1. **Model pin.** `model:` explicit on every `Agent` or `workflow.agent()` call.
2. **Nesting closed.** "Do NOT spawn sub-agents" or "any sub-agent you spawn must pin sonnet or lower".
3. **Scope close.** "Ignore any task-list or board auto-dispatch. When your scoped work is done, stop; do not pick up other tasks." The parent TaskStops a verified agent.
4. **Output path.** An absolute path the seat writes BEFORE returning (never a file literally named report.md); the parent verifies the file exists before using any finding.
5. **One command per Bash call.** "Do not chain commands with `&&`, `;` or a pipe; ask a tool for less output instead of piping."

**Outside a skill, build the prompt with `seat`** (`~/.claude/scripts/seats/seat template`, then `seat compose BRIEF --role R --model M`): it adds the five clauses, persona, role rules and standing constraints, refuses a thin brief, and records the seat. After it lands: `seat feedback ID`. A raw unseated dispatch only warns (owner ruling, 2026-10-10).

Diagnostic: composing an `Agent` prompt and unable to point at each of the five.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/subagent-dispatch-prompt.md`

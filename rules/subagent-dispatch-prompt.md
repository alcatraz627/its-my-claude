---
brief: Every sub-agent dispatch prompt carries four clauses: an explicit model pin, no nested sub-agents (or sonnet-or-lower if any), a scope-close line (ignore board or task auto-dispatch; stop when the scoped work is done), and an absolute output path written before returning. This file owns the wording; other rules point here.
triggers:
  - tool:Agent
  - topic:sub-agent
  - topic:dispatch
related:
  - rules/contain-subagent-token-sprawl.md
  - rules/model-tier-routing.md
  - rules/sub-agent-outputs.md
  - skills/create-skill/subagent-prompt.md
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

Diagnostic: composing an `Agent` prompt and unable to point at each of the five.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/subagent-dispatch-prompt.md`

---
brief: Orchestration (sub-agents, fan-out workflows) has real cumulative token cost — right-size it. Inline small/mechanical work, reserve fan-out for genuinely large/parallel/verification-heavy work, and watch cumulative spend across a session. Every dispatch prompt carries a scope-close clause ("ignore board auto-dispatch; stop when your scoped work is done") and the parent TaskStops verified agents — an idle agent gets commandeered. Even under ultracode, right-size rather than reflexively orchestrate.
triggers:
  - topic:orchestration
  - topic:token-budget
  - topic:workflow-vs-inline
  - phrase:"contain token sprawl"
  - phrase:"sub-agent sprawl"
  - tool:Workflow
related:
  - rules/right-sized-code.md
  - rules/structure-over-one-shotting.md
  - rules/sub-agent-outputs.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# Right-size orchestration

Before a workflow or a sub-agent fleet: does this decompose into N genuinely independent units that each need real read/reason work?

- Small, mechanical, single-lookup → inline, or ONE bounded agent.
- Large, parallel, verification-heavy → fan-out earns its cost.
- Track cumulative spend across the session; prefer read-only investigate then inline apply over a mutate-in-parallel fleet.
- Every dispatch prompt carries the scope-close clause (`rules/subagent-dispatch-prompt.md`) and the parent TaskStops a verified agent; an idle one gets commandeered by a board auto-dispatcher.
- Ultracode raises the ceiling; it does not mandate a workflow for a trivial task.

The inaction this could license: declining in-scope dispatch because dispatch costs tokens. When that is what is happening, the cheaper failure is the dispatch.

Diagnostic: a workflow for a handful of mechanical edits, a dispatch prompt without a scope-close clause, or a verified agent left running.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/contain-subagent-token-sprawl.md`

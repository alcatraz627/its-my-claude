---
brief: Route every piece of work to the smallest adequate lane (local lm / gemini / haiku→sonnet→opus; fable = main-only) with right-sized effort; every plan with sub-agents, large ingestion, or modality tools carries a 4-line Model Plan; never switch models without explicit user confirmation. Enforced by guard-model-tier.sh.
triggers:
  - tool:Agent
  - tool:Workflow
  - tool:lm-gemini
  - topic:model-tier
  - topic:sub-agents
  - topic:gemini
  - phrase:"which model"
related:
  - contain-subagent-token-sprawl
  - structure-over-one-shotting
tier: 0
category: rules
updated: 2026-09-18
stale_after_days: 180
---
# Route every piece of work to the smallest adequate lane, out loud

Lanes: local `lm` (~$0: q/see/review/imagine/fleet/index) · `lm gemini` (huge context, untrusted output) · haiku (trivial) · sonnet (DEFAULT sub-agent) · opus (main driver; judgment seats) · fable (vague+complex; in-subscription, still declared).

- **Every dispatch carries an explicit `model:` pin.** Sub-agent effort ≤ a high main; sonnet liberal, opus medium unless real judgment, xhigh needs the owner.
- **A fable-tier main does involved work ITSELF** (owner 2026-09-01); it may delegate review, verification, cheap passes, never authoring. Hard-blocked in guard-model-tier.sh.
- **Model Plan block** on any plan with sub-agents, large ingestion or a modality tool: one line per stage, `stage → lane · model · effort · why`.
- Escalate one step on evidence (failed gate, >2 retries, correction, irreversible stakes), never on anticipation. A missing model falls one lane DOWN, never up to fable.
- **Never switch models without the owner's explicit confirmation.** Push back once with an alternative, then execute their call.
- Usage-window advisories (fable above 80/90 percent) are the policy layer's job, advisory only.

Diagnostic: a dispatch without a `model:` pin, a plan with sub-agents and no Model Plan, or a model switch on your own judgment.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/model-tier-routing.md`

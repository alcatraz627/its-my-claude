---
brief: Route work to the smallest adequate lane (local lm, gemini, haiku, sonnet, opus), carry a 4-line Model Plan, and never switch models without explicit user confirmation. Enforced by guard-model-tier.sh.
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

Lanes: local `lm` and `lm gemini` are complements for what Claude cannot do well, never a cheaper stand-in (owner, 2026-08-30): `lm see` and `lm imagine` for vision, `lm gemini` for a sweep of a corpus too big for context (untrusted output). Claude lanes: haiku (trivial), sonnet (DEFAULT sub-agent), opus (main driver, judgment seats), fable (vague, complex work; still declared).

- **Every dispatch carries an explicit `model:` pin.** Sub-agent effort stays at or below a high main. Sonnet gets liberal effort, opus medium unless real judgment is needed, and xhigh needs the owner.
- **A fable-tier main does involved work ITSELF** (owner 2026-09-01). It may delegate review, verification and cheap passes, never authoring (guard-model-tier.sh blocks it).
- **Model Plan block** on any plan with sub-agents, large ingestion or a modality tool: one line per stage, `stage → lane · model · effort · why`.
- Escalate one step on evidence (failed gate, over 2 retries, correction, irreversible stakes), never on anticipation. A missing model falls one lane DOWN, never up to fable.
- **Never switch the main agent model without the owner's explicit confirmation.** An auxiliary `lm` or Gemini call is not a switch (owner-authorized). Before a Gemini sweep, state the corpus, output and validation criteria; afterward, sample-check its claims. Judgment, edits and final claims stay with the main agent. Never send credentials or secret-bearing inputs. 
- Fable usage-window advisories (80/90 percent) belong to the policy layer.

Diagnostic: a dispatch without a `model:` pin, a plan with sub-agents and no Model Plan, or a model switch on your own judgment.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/model-tier-routing.md`

---
brief: Smallest adequate lane, a Model Plan for sub-agent plans, no model switch without confirmation.
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
updated: 2026-11-04
stale_after_days: 180
---
# Route every piece of work to the smallest adequate lane, out loud

Lanes: `lm` and `lm gemini` cover what Claude cannot do well, never a cheaper stand-in (owner): `lm see`, `lm imagine` for vision, `lm gemini` for a corpus too big for context (untrusted output). Claude: haiku (trivial), sonnet (DEFAULT sub-agent), opus (main driver, judgment seats), fable (vague, complex work).

- **Every dispatch carries an explicit `model:` pin.** Sub-agent effort stays at or below a high main (sonnet liberal, opus medium unless judgment needs more); xhigh needs the owner.
- **A fable-tier main does involved work ITSELF** (owner). It may delegate review, verification and cheap passes, never authoring.
- **Model Plan block** on any plan with sub-agents, large ingestion or a modality tool: one line per stage, `stage → lane · model · effort · why`.
- Escalate one step on evidence (failed gate, 3+ retries, correction, irreversible stakes), never on anticipation. A missing model falls one lane DOWN, never up to fable.
- **Never switch the main agent model without the owner's explicit confirmation.** An auxiliary `lm` or Gemini call is not a switch (owner-authorized). Gemini sweeps follow provenance "Auxiliary lm and Gemini use". Judgment, edits and final claims stay with the main agent; never send credentials or secret-bearing inputs.
- **Off-lane runs leave a record.** Read a seat's record in `~/Code/local-models/docs/model-notes.md` before picking its model; after a run off the usual lane, add a row (a report in `docs/model-runs/` if it taught more).

Diagnostic: a dispatch without a `model:` pin, a plan with sub-agents and no Model Plan, or a model switch on your own judgment.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/model-tier-routing.md`

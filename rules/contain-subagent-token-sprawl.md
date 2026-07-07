---
brief: Orchestration (sub-agents, fan-out workflows) has real cumulative token cost — right-size it. Inline small/mechanical work, reserve fan-out for genuinely large/parallel/verification-heavy work, and watch cumulative spend across a session. Even under ultracode, right-size rather than reflexively orchestrate.
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
updated: 2026-07-07
stale_after_days: 180
---

# Contain sub-agent / workflow token sprawl

Spawning sub-agents and fan-out workflows is powerful, but each one spends tokens, and several across a session compound into a large bill (a handful of ~500K-token workflows is millions of tokens). The default is the **smallest tool that does the job**, not the most parallel one.

## The rule

Before launching a workflow or a sub-agent fleet, ask: **does this decompose into N genuinely-independent units that each need real read/reason work?**

- **Small / mechanical / single-lookup** (a few grounded edits, a status relabel pass, one file's answer) → do it **inline**, or with **one** bounded agent. It's cheaper and keeps context tight.
- **Genuinely large / parallel / verification-heavy** (broad review, multi-source research, a migration over many files, adversarial verify) → fan-out is the right tool; breadth or independent verification is the actual value.

Ultracode raises the ceiling ("token cost is not a constraint"); it does **not** mandate a workflow for every task. A trivial or mechanical task still goes inline under ultracode.

## Watch cumulative spend

Track spend across the session, not per-call. If the user is cost-conscious, or you've already run several fan-outs, bias hard toward inline + verify. Prefer read-only investigate → inline apply over a mutate-in-parallel fleet: it's cheaper, and it keeps you in the loop on the edits.

## What this does NOT mean

Not "avoid workflows." Fan-out earns its cost on large/parallel/verification work — that is exactly what it's for. The rule is against **reflexive orchestration of small tasks**, where a workflow's setup + agent overhead dwarfs the actual work.

## Diagnostic

You're about to launch a workflow or a sub-agent fleet for something that's really a handful of mechanical edits or one targeted lookup. Stop — do it inline.

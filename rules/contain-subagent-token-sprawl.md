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

## Close the agent's scope, or something else will open it

A sub-agent that finishes its task and idles does not necessarily stop. It can be
picked up by a task-board auto-dispatcher ("complete all open tasks") and put to
work on items nobody assigned it — out-of-scope edits and token spend attributed to
your dispatch. This happened on 2026-07-07: an idle agent did an unassigned doc task,
then died on an API error.

So every dispatch prompt carries a scope-close clause and the parent closes the loop.
The wording of that clause, and of the three it travels with, lives in
`rules/subagent-dispatch-prompt.md`; the parent `TaskStop`s each agent once its output
is verified.

Deliberately NOT a hook: a PreToolUse gate would have to fire on every `Agent`
dispatch missing the magic words, and that channel already carries the
subagent-output nudge. Cost-of-false-fire says rule text here, not a second nudge.

## A guard must say what inaction it could license

This rule fired and was over-applied on 2026-08-26: "a budget rule became a reason not to work" (gcc-kanban, verbatim). A guard that can cause the failure next to the one it prevents is a distinct defect. So this rule, and every guard proposed under it, names the inaction it could license: here, a lane declining to dispatch work that was in scope because dispatch costs tokens. When that is what is happening, the cheaper failure is the dispatch.

## What this does NOT mean

Not "avoid workflows." Fan-out earns its cost on large/parallel/verification work — that is exactly what it's for. The rule is against **reflexive orchestration of small tasks**, where a workflow's setup + agent overhead dwarfs the actual work.

## Diagnostic

You're about to launch a workflow or a sub-agent fleet for something that's really a handful of mechanical edits or one targeted lookup. Stop — do it inline. Or: you're writing an `Agent` prompt with no scope-close clause, or you have verified an agent's output and left it running.

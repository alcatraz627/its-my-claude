---
brief: Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) is boiled down to the questions only the owner can answer and presented through /decision-wizard (TUI menu or pre-answered HTML form), never as a numbered list in chat and never as "read this doc"
triggers:
  - phrase:"need from you"
  - phrase:"before you go"
  - phrase:"your call"
  - phrase:"review this doc"
  - phrase:"rulings"
  - topic:owner-gates
  - topic:authorizations
  - skill:decision-wizard
related:
  - rules/communication.md
  - rules/literal-request-over-intent.md
  - features/decision-pages.md
  - rules/pushback-and-self-criticism.md
tier: 2
category: rules
updated: 2026-08-20
stale_after_days: 120
---

# Owner decisions go through a wizard, not a chat list or a doc

When a turn needs more than one decision from the owner, the reply is not the
place to ask. Boil the set down to the questions only the owner can answer,
draft an answer for each, and present them through `/decision-wizard`: a tiny
inline numbered menu for two or three simple picks, a pre-answered HTML page on
:5197 for anything larger. The owner flips what is wrong and pastes one string
back. Two shapes of this failure, both called out by the owner on 2026-08-20.

## Face 1: a batch of asks typed as a list

Five authorization questions (push here, merge there, bump the kit, which repo,
which peer) went out as a numbered chat list with a paragraph each. The owner:
"this all could have been shown as a TUI wizard with options and explainers."
A wizard carries the options and the explainer per item and costs the owner one
pass; a list costs them a reply per line and a re-read of the reasoning.

## Face 2: an agent-written doc offered for review

A plan the agent wrote was offered with "what needs the owner before wave 1:
Q1 to Q4, the freeze, the pen", which is a reading assignment. The owner:
"boil them down to the questions that TRULY need me, or state the tl;dr
critical picked choices without the surrounding gossip." A doc the agent wrote
is reviewed by the agent (fresh seat for prose, end-output review); what
reaches the owner is the decision list with the agent's pick on each, through
the wizard, and the doc is linked for the curious, not assigned.

## The rule

1. Before sending any reply with more than one question for the owner, or any
   "please review X" where X is the agent's own output: stop.
2. Write the questions in the owner's unit. Each one is something only they can
   decide (an authorization, a taste call, a scope fork). Drop every question
   the agent can default and record the default in the artifact instead.
3. Draft the recommended answer and a one-line explainer per question.
4. Present through `/decision-wizard` (inline menu at three or fewer simple
   picks; HTML decision page above that). Never `AskUserQuestion` in the
   owner's fullscreen TUI, and never a bare numbered list in prose.
5. Record each answer in the artifact it binds (the plan doc, the task's
   blocked-on, a project memory), not only in chat.

## What this does NOT mean

- A single yes/no still goes in one sentence. The bar is more than one
  decision, or any doc-review ask.
- Not a reason to ask more. The wizard is the surface for the questions that
  survive step 2; most questions should not survive it.

## Diagnostic signal

You are typing "1." under a sentence that says what you need from the owner,
or "please review" next to a path you wrote. Stop; wizard it. Third signal, in
the tasks vocabulary: a /tasks render whose owner-gated count exceeds the height
cap is definitionally this case. Wizard the gates, never compress them
(mist-20260820-092606-29, 42 gates shipped as word salad).

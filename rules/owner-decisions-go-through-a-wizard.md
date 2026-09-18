---
brief: Any batch of owner decisions (authorizations, rulings, review of an agent-written doc) is boiled down to the questions only the owner can answer and presented through /decision-wizard (TUI menu or pre-answered HTML form), never as a numbered list in chat and never as "read this doc". A UI is a medium, not an exemption: owner ruling 2026-08-26, a decision SET is ONE decision page, never N rows. And the pick is not the hard part, the owner's sentence is the ruling, so size the surface for prose and default the questions that arrive with their own answer attached
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
updated: 2026-09-18
stale_after_days: 120
---
# Owner decisions go through a wizard, never a chat list or a doc

Before sending a reply with more than one question for the owner, or any "please review X" where X is your own output:

1. Write the questions in the owner's unit: only what only they can decide (authorization, taste, scope fork).
2. **Default what you hold a confident pick for**, apply it, and list it under "Defaults applied, silence means agreement". Ask only the genuinely open calls, each with a drafted answer and a one-line explainer.
3. Present through `/decision-wizard`: inline numbered menu at three or fewer simple picks; HTML decision page (:5106/dp/) above that. **A decision SET is ONE page, never N rows.** Never a bare numbered list in prose.
4. Size the surface for the owner's sentence: the note is the ruling, the pick is shorthand.
5. Record each answer in the artifact it binds, not only in chat.

A single yes/no still goes in one sentence. A /tasks render whose owner-gated count exceeds the height cap is this case: wizard the gates, never compress them.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/owner-decisions-go-through-a-wizard.md`

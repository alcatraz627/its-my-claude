---
brief: Every agent hands the owner a `/goal <text>` paste line whenever it starts something, before the work, not after. The line is bare on its own line so selecting it copies clean. Every clause must be one the agent can finish alone, because an armed goal is a Stop condition and a clause whose actor is the owner blocks every stop until he disarms it by hand.
triggers:
  - topic:goal
  - topic:starting-work
  - phrase:"arm a goal"
  - phrase:"what are you working on"
  - tool:goal.sh
related:
  - rules/communication.md
  - rules/owner-decisions-go-through-a-wizard.md
  - features/context-retention.md
tier: 1
category: rules
updated: 2026-10-15
stale_after_days: 180
---
# Give the owner a goal line to arm when you start something

When you begin a task, plan, build, investigation or review, or resume one after /clear or /compact, print one bare pasteable line, no rail, no bullet:

```
/goal <the goal, one line>
```

Prefer `bash ~/.claude/scripts/goal/goal.sh armline` or `goal.sh box` over typing it.

- Three to six short declarative sentences, each true or false on its own. No ticket numbers, filenames or counts. No unbounded quantifiers ("every way X can fail"), no standing behaviours ("every question is answered the turn it arrives"): name the artifact or threshold instead.
- Every clause is one YOU can finish alone. An armed goal is a Stop condition; a clause whose actor is the owner blocks every stop. The owner half goes in the reply as a blocked-on line.
- Scope the goal to what one session can finish; a bigger arc gets its first slice, the rest stays in the task list (`goal.sh lint` flags arc-sized goals). A clause the owner waived stops blocking: drop it, never re-raise it.
- Propose, do not arm. `goal.sh set` is the owner's move, with no exception: /catchup only offers a checkpoint's goal (owner ruling 2026-10-13).
- The /tasks goal band may differ from the armed goal; reconcile toward the owner's, never fight it.

Diagnostic: three tool calls into something new and no line to arm; or a clause whose subject is the owner.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/goal-statement-on-starting-work.md`

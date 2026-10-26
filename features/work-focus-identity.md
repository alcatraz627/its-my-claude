---
brief: How to address "the agent working on X" when the session that asked is gone. Prefer a project path (its claude-ipc mailbox waits for any session in that tree), then a live ipc alias, then a message id to reply on. Best effort, never a hard requirement.
triggers:
  - topic:reply-to
  - topic:ipc-addressing
  - topic:work-focus
  - tool:claude-ipc
related:
  - features/weekly-tags.md
  - skills/ipc/SKILL.md
tier: 2
category: features
updated: 2026-10-26
stale_after_days: 180
---

# Work-focus identity: who should hear back

Sessions come and go: /clear, a crash or a new day ends one, and the next one
working on the same thing has a different session id and often a different ipc
alias. What persists is the work focus: the project, the goal, the thread of
messages. When something has to reach "whoever is working on this" later (a
weekly tag's outcome, a decision page's answer, an ipc reply), address the focus,
not the session.

Best effort, in this order:

1. **A project path** (`/Users/alcatraz627/Code/better-file-browser`). Its
   claude-ipc project mailbox waits for any session that starts in that tree, so
   it survives every restart. The most durable choice.
2. **An ipc alias** (`bfb`, `gcc-all`). Good while that session lives; a
   successor often re-registers the same alias, but not always.
3. **A message id** (`msg-…`). Use it when the thing is a reply in an existing
   thread, so it lands in context.
4. **A session id** last: it identifies who asked, for the record, and is rarely
   reachable later.

Record more than one when you have them (`sessions:` for who asked, `reply-to:`
for who should hear). A delivery that fails is not an error: say so where the
owner will read it (the report, the reply) and move on. Do not build machinery
to make this exact; the owner asked for "best effort" on purpose.

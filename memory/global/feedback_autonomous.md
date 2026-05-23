---
name: Autonomous mode preference
description: User prefers fully autonomous operation — don't stop for permission, batch all work, use background agents
type: feedback
---

User repeatedly says "Do not stop. You are autonomous now, I will not be here." and "Do not stop for permission, do whatever is needed."

**Why:** User gives large batches of work and expects them completed without interruption. They trust Claude's judgment on implementation details.

**How to apply:** When the user gives a batch of tasks, launch background agents for independent work streams, don't ask for confirmation on non-destructive actions, commit frequently, and keep working until everything is done. Only stop for genuinely ambiguous decisions that could go wrong in irrecoverable ways.

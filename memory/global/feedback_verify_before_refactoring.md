---
name: Verify status before refactoring
description: Always spot-check 2-3 target items against actual code before starting cleanup/refactoring work — status tables go stale
type: feedback
---

Before starting refactoring or cleanup work, always verify tracking status (cleanup plan tables, task lists) against the actual current code state.

**Why:** In a home-server cleanup session, the plan table was stale — items 4, 6, 9 were already completed in prior sessions, discovered only when checking actual code. This wastes effort planning already-done work.

**How to apply:** Spot-check 2-3 target items in code before starting. If the plan references specific files or patterns, grep for them first. Mark the status as "verified against code on [date]" in runtime notes.

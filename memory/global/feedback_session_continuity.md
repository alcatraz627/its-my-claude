---
name: Session Continuity Patterns
description: User relies heavily on /catchup and /core-dump for long sessions; compaction hits frequently on complex tasks
type: feedback
originSessionId: f7f0db0b-05e4-4b6a-b2db-50cf416260e4
---
User runs very long sessions with frequent context compaction. They rely on `/catchup` and `/core-dump` to resume work across compaction boundaries.

**Why:** Sessions like the dream dashboard work had 70+ tool calls in a single turn and 25+ conversation turns — far past typical context limits. The user explicitly uses "restarted keep going core dump" and "keep going with pending tasks" as prompts after compaction.

**How to apply:** On any complex multi-turn task, proactively write WAL entries and checkpoints without waiting to be asked. When the user says "keep going" or "what else remains", they're likely resuming after compaction — check the WAL/checkpoint first before assuming context is fresh.

---
brief: Live todos live in the Task tool, the agent's checklist FOR THIS SESSION and what the TUI shows. What is left ACROSS sessions lives in the goal record (gs, ~/.claude/goals/by-id), the one truth the owner reads through /tasks; session-notes Todos and checkpoint Pending Items are derived from it (D1, 2026-09-23). The kanban board is independent, optional and frozen. Plans in docs carry the reasoning.
triggers:
  - phrase:"update todos"
  - phrase:"update your todos"
  - phrase:"todo list"
  - tool:TaskCreate
  - tool:TaskUpdate
  - topic:todos
  - topic:task-tracking
related: [features/kanban.md, features/context-retention.md, skills/workspace/SKILL.md, migrations/0017-todo-sync-task-tool.md]
tier: 1
category: rules
updated: 2026-09-23
stale_after_days: 120
---
# The Task tool is the todo home for this session

1. "Update your todos" means TaskCreate/TaskUpdate (or `task.sh` when the harness has no Task tool), never a file. That list is the agent's own checklist for this session.
2. Multi-step work (3+ steps) starts with tasks: create at the start, one `in_progress`, mark completed as you go.
3. **The owner's surface is the goal record**, not the checklist (D1, 2026-09-23, overriding the 2026-05-17 three-mirrors ruling). Work the owner will check goes on a goal through `gs` (`~/.claude/scripts/goals/gs`): outcome, acceptance rows, milestones, rows. `/tasks` reads only that. A checklist row reaches the owner only by `gs adopt`.
4. Never hand-edit the mirrors: the session-notes Todos block and the memory pointer are machine-owned and overwritten at Stop. Across sessions the goal record is the truth; a checkpoint's Pending Items cite it.
5. Planning docs carry the reasoning; a plan in a file with an empty Task list leaves the TUI blind.

The project kanban board is a different altitude, never a mirror, and frozen since 2026-09-23 (D2): nothing writes to it unasked. A board that differs from any list is working as designed.

Diagnostic: substantial editing this session and the Task list is empty, or todos about to go into a project file.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/todo-discipline.md`

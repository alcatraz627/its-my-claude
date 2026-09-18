---
brief: Live todos live in the Task tool, the source of truth FOR THIS SESSION and what the TUI shows; session-notes/memory are auto-mirrors of it, never hand-edited. A project outlives one session, so its longer-lived state belongs on its kanban board, an independent artifact and NOT a mirror. Plans in docs carry the reasoning. Three altitudes, not three copies.
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
updated: 2026-09-18
stale_after_days: 120
---
# The Task tool is the todo home for this session

1. "Update your todos" means TaskCreate/TaskUpdate (or `task.sh` when the harness has no Task tool), never a file.
2. Multi-step work (3+ steps) starts with tasks: create at the start, one `in_progress`, mark completed as you go.
3. Never hand-edit the mirrors: the session-notes Todos block and the memory pointer are machine-owned and overwritten at Stop.
4. Planning docs carry the reasoning; a plan in a file with an empty Task list leaves the TUI blind.

The project kanban board is a different altitude, never a mirror: it is the owner's cross-session view. A board that differs from the Task list is working as designed; never reconcile it into a mirror.

Diagnostic: substantial editing this session and the Task list is empty, or todos about to go into a project file.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/todo-discipline.md`

---
brief: Live todos live in the Task tool (source of truth + TUI); session-notes/memory are auto-mirrors, never hand-edited; plans in docs are complementary not the status surface
triggers:
  - phrase:"update todos"
  - phrase:"update your todos"
  - phrase:"todo list"
  - tool:TaskCreate
  - tool:TaskUpdate
  - topic:todos
  - topic:task-tracking
related: [features/context-retention.md, skills/workspace/SKILL.md, migrations/0017-todo-sync-task-tool.md]
tier: 1
category: rules
updated: 2026-06-09
stale_after_days: 120
---

# Todo discipline — the Task tool is the todo home

The live todo list **is** the Task tool (`TaskCreate` / `TaskUpdate`). That is the
single source of truth, and it is what the Claude Code TUI shows. Everything else
— the `session-notes` Todos block, the memory "current focus" pointer — is an
**auto-generated mirror** of it, produced by sync-todos (migration 0017). The sync
runs one direction only: Task tool → notes → memory. There is no path back.

## The rule

1. **"Update your todos" means the Task tool.** When the user says "update your
   todos" — even without naming "Claude Code todos" or "the TUI" — reach for
   `TaskCreate`/`TaskUpdate`, not a file. They are referring to the live list.
2. **Multi-step work (≥3 steps) starts with tasks.** Create them at the start,
   set one `in_progress`, mark `completed` as you finish. This is what populates
   the TUI and drives the mirror.
3. **Never hand-edit the mirror.** The Todos block inside `session-notes/_active.md`
   is machine-owned — the next Stop-hook writeback overwrites it from the live
   Task list. Editing it does nothing durable AND is invisible to the TUI.
4. **Planning docs are complementary, not the status surface.** A `docs/plan.md`
   or design file for detailed thinking is fine and encouraged. But a plan in a
   file with an *empty Task list* leaves the TUI blind — that is the exact failure
   this rule exists to prevent (see provenance).

## Why this gets a rule

The plumbing has existed since migration 0017, but nothing always-loaded told
agents to *use* it — so agents defaulted to the surface they knew (a `TODO.md` /
`plan.md` in the repo) and the TUI stayed empty all session. This is the
`skill-spec-update-not-honored` pattern: a capability with no agent-facing
directive is invisible. The directive (this rule + the Tier-0 brief in CLAUDE.md)
is the compliant-path fix; the advisory `no-task-nudge.sh` PostToolUse hook is the
mechanical catch for sessions that ignore it.

## What this does NOT mean

- Not every session needs tasks. A quick Q&A, a one-line fix, pure exploration —
  no task list required. The "≥3 steps" bar is the trigger.
- Detailed plans, design docs, and a repo's own `TODO.md` are still legitimate
  artifacts. The rule is only that they don't *replace* the Task tool as the live
  status surface.
- "Workspace wins on conflict" (the redundant-trio preference) still holds for the
  **human-authored** Notes/Decisions regions of the workspace — those are separate
  from the machine-owned todo mirror and are never clobbered.

## Diagnostic signal

You've done substantial editing this session and the Task list is still empty —
or you're about to write todos into a project file instead of calling the Task
tool. Stop and create tasks.

## Provenance

2026-06-09: session `local-models` did 42 tool calls (28 Bash, 8 Edit, 6 Write),
managed its todos in `docs/TODO.md` + `docs/00-plan.md`, and never once called the
Task tool — the TUI stayed empty the entire session. User: "even when asked to
'update their todos' they write to the file but do not update in the Claude Code
TUI."

## Related

- `migrations/0017-todo-sync-task-tool.md` — the sync plumbing this rule activates
- `rules/skill-spec-update-not-honored-by-running-session.md` — the "infra without
  a data-path gate is advisory" sibling pattern
- `features/context-retention.md` — workspace/notes layering

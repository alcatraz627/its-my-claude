---
name: context-prime
description: Loads project index, gotchas, recent git log, and open issues into context at the start of a session — bootstrapping Claude's awareness without any manual prompting.
allowed-tools: Read, Bash, Glob
user-invokable: true
argument-hint: ""
disable-model-invocation: true
---

## Brief

Run at the start of a new work session to instantly load project structure, known pitfalls, and recent activity into Claude's context. Replaces the need to manually explain the codebase at the beginning of each conversation.

# Context Prime

Bootstraps Claude's awareness for a new session by loading the project index, gotchas.md, and recent git activity — giving Claude immediate, accurate context about what you're working on and how the project is structured.

## Step 0: Load Shared Guidelines and Runtime Context

Read `.claude/skills/GUIDELINES.md` before proceeding. Apply all rules — forbidden paths,
retry logic, tool preferences, verbosity, timeouts, post-run insights, and the file lock
protocol — for the entire duration of this skill run.

Also read `.claude/skills/runtime-notes.md` for past run history relevant to this skill.
If it does not exist yet, continue without it.

> Lock reminder: acquire a lock via `lock-file.sh acquire` before every Edit/Write, and
> release it immediately after. Never write to `runtime-notes.md` or any SKILL.md without
> holding its lock.

## Usage

```
/context-prime
```

No arguments. Typically the first command in a new session.

---

## Phase 1 — Load Project Index

Check for the project index and read it:

```bash
ls .claude/project-index.md 2>/dev/null
```

- **If found:** Read `.claude/project-index.md` in full. Extract:
  - Tech stack summary
  - Key directories and their purposes
  - Architecture patterns (data fetching, state management, auth)
  - Key file paths

- **If not found:** Print: `"No project index found. Run /project-index to generate one."` Continue with remaining steps.

---

## Phase 2 — Load Gotchas

Read `gotchas.md` from the project root:

```bash
ls gotchas.md 2>/dev/null
```

- **If found:** Read it in full. Note the top 5 most recent or critical gotchas.
- **If not found:** Skip silently.

---

## Phase 3 — Load Recent Git Activity

```bash
git log --oneline -15
```

Extract:
- What areas of the codebase have changed recently
- Any in-progress feature branches
- Recent commits that hint at ongoing work

Also check for staged/unstaged changes:

```bash
git status --short
```

---

## Phase 4 — Print Session Summary

Print a concise session briefing:

```
─────────────────────────────────────────────────────
  Context Primed — [project name]
─────────────────────────────────────────────────────

  Stack:    [framework, language, key libs — 1 line]
  Backend:  [backend location and type, if relevant]

  Recent activity:
    [bullet list from git log — 5-8 items]

  Uncommitted changes:
    [git status summary, or "Clean working tree"]

  Active gotchas (top 3):
    [bullet list from gotchas.md]

  Key paths:
    [4-6 most important file paths from project index]

─────────────────────────────────────────────────────
  Ready. What are we working on today?
─────────────────────────────────────────────────────
```

---

## Notes

- This skill uses `disable-model-invocation: true` — Claude will never auto-trigger it. Only run when you explicitly type `/context-prime`.
- The session summary is printed to terminal only — no files are written.
- Subsequent messages in the session benefit from Claude having already processed the index and gotchas.

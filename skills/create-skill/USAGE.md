# /create-skill — Usage Guide

## What it does

An interactive wizard that turns your description of a skill idea into a
production-ready SKILL.md and companion USAGE.md, placed in the correct
directory with proper formatting.

## Usage

```
/create-skill [skill-name]
```

| Argument     | Type     | Description                                                                          |
| ------------ | -------- | ------------------------------------------------------------------------------------ |
| `skill-name` | optional | Kebab-case name for the new skill (e.g. `code-review`). If omitted, the wizard asks. |

## Examples

### Example 1: Start from scratch

```
/create-skill
```

The wizard asks all 7 questions in sequence, formalizes each answer,
shows a plan for approval, then writes both files.

### Example 2: Provide the name upfront

```
/create-skill deps-audit
```

Skips Q1 (naming). Proceeds directly to Q2 (goal).

### Example 3: Create a skill that chains with create-report

```
/create-skill changelog-generator
```

During Q7, describe that it should call `/create-report` at the end.
The wizard adds the integration to the Notes section and generates
appropriate Phase 3 steps.

## Caveats

- The wizard writes no files until the plan is approved in Phase 2. All
  Q&A is safe to abandon before that point.
- If `.claude/skills/<name>/SKILL.md` already exists, the wizard will
  warn you before overwriting.
- Skill names must be unique — check `/user-config` first if you're
  unsure whether a skill already exists.
- The wizard formalizes your answers, not fabricates them. If your
  description is too vague, it will ask follow-up questions rather than
  invent behavior.

## Dependencies

| Dependency         | Type         | Notes                                                     |
| ------------------ | ------------ | --------------------------------------------------------- |
| `GUIDELINES.md`    | Shared rules | Read at start of every run                                |
| `runtime-notes.md` | Run log      | Read at start — informs naming patterns and tool choices  |
| `README.md`        | Reference    | Skill structure conventions and checklist                 |
| `prettier`         | CLI tool     | Formats output files; available via `npx prettier`        |

## Tips

- Answer each question in plain language — the wizard handles all
  formatting and canonical phrasing.
- The "Anything else" question (Q7) is the best place to mention
  integrations with other skills like `/create-report` or `/project-index`.
- After creating a skill, run `/user-config edit` to review and further
  refine it interactively.
- Run `/create-skill` again to create the next skill — each run is
  independent.

# Global Memory Tier

Cross-project memory for Claude Code. Files here are loaded in **every** project session
via a CLAUDE.md instruction — unlike per-project memory which is scoped to one CWD.

## When to use global vs per-project

| Use global when... | Use per-project when... |
|---|---|
| The memory applies regardless of which repo you're in | The memory is specific to one codebase |
| User preferences, coding style, workflow rules | Project architecture, domain knowledge |
| Universal feedback ("always test small samples") | Repo-specific feedback ("use Drizzle, not Prisma") |
| Cross-cutting tool knowledge (macOS tricks, git patterns) | Project-specific tool config |

## File format

Same frontmatter format as per-project memory:

```markdown
---
name: {{memory name}}
description: {{one-line description}}
type: {{user, feedback, project, reference}}
---

{{memory content}}
```

## MEMORY.md index

`MEMORY.md` in this directory is the index — one line per entry, under 150 chars:
`- [Title](file.md) — one-line hook`

## Promoting a per-project memory

When a memory proves universal:

1. Copy (not move) from `~/.claude/projects/<slug>/memory/<file>.md` to here
2. Review the content — strip project-specific details
3. Add to `MEMORY.md` index
4. Leave the original in place (per-project memory is never degraded)

## Precedence

If the same topic appears in both global and per-project memory, **per-project wins** —
it may have project-specific refinements.

## History

Introduced by Migration 0004 (`~/.claude/migrations/0004-memory-global-tier.md`).
Part of the `std::claude::memory` namespace.

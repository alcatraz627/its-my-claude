---
brief: Per-project + global memory tiers; MEMORY.md index; cascade + override rules; promotion workflow
triggers:
  - topic:memory
  - topic:preferences
  - phrase:"remember that"
  - phrase:"from now on"
related: []
tier: 1
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Memory
Two-tier memory system: per-project (auto-loaded) + global (cross-project).

## Tiers

- **Per-project:** `~/.claude/projects/<slug>/memory/MEMORY.md` + referenced `<type>_*.md` files. Auto-loaded every session.
- **Global:** `~/.claude/memory/global/MEMORY.md` + files. Not auto-loaded — reference in CLAUDE.md so agents read it alongside per-project memory.

## Cascade rule

When both tiers have a memory on the same topic, **per-project takes precedence**. Treat the global entry as the default; let the project override it.

## Memory types

- `user_*` — who the user is, their role, preferences, expertise
- `feedback_*` — guidance the user gave (corrections AND confirmations)
- `project_*` — ongoing work, bugs, initiatives, deadlines
- `reference_*` — pointers to external systems (Linear, Slack, Grafana)

## When to save

**Explicit requests:** "remember that", "save this", "from now on" — save immediately.

**Implicit signals:**
- User corrects you → feedback_* (rule + Why + How to apply)
- User confirms an unusual choice → feedback_* (validated approach)
- User reveals role/preferences → user_*
- User describes ongoing work/constraints → project_* (absolute dates, not relative)
- User references an external tool as authoritative → reference_*

## What NOT to save

Code patterns derivable by reading current state, git history / who-changed-what, debugging fix recipes, anything already in CLAUDE.md, ephemeral task details. Even if the user asks — ask back "what was *surprising* about this?" and save only that.

## Promotion workflow

Per-project memory that proves universal (observed in 2+ projects) graduates to global. See `~/.claude/memory/global/README.md` for promotion criteria and format.

## Before recommending from memory

Memories go stale. A memory naming a file, function, or flag is a claim that **it existed when written**. Before recommending action on it: check the file exists; grep for the function/flag; if user is about to act, verify first. "Memory says X exists" ≠ "X exists now."

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
A two-tier memory system: per-project (auto-loaded) and global (cross-project).

## Tiers

- **Per-project:** `~/.claude/projects/<slug>/memory/MEMORY.md` plus referenced `<type>_*.md` files. Auto-loaded every session.
- **Global:** `~/.claude/memory/global/MEMORY.md` plus files. Not auto-loaded, so reference it in CLAUDE.md for agents to read alongside per-project memory.

## Cascade rule

When both tiers have a memory on the same topic, **per-project takes precedence**. Treat the global entry as the default and let the project override it.

## Memory types

- `user_*` holds who the user is, their role, preferences and expertise
- `feedback_*` holds guidance the user gave (corrections AND confirmations)
- `project_*` holds ongoing work, bugs, initiatives and deadlines
- `reference_*` holds pointers to external systems (Linear, Slack, Grafana)

## When to save

**Explicit requests:** "remember that", "save this", "from now on". Save immediately.

**Implicit signals:**
- User corrects you: feedback_* (rule + Why + How to apply)
- User confirms an unusual choice: feedback_* (validated approach)
- User reveals role or preferences: user_*
- User describes ongoing work or constraints: project_* (absolute dates, not relative)
- User references an external tool as authoritative: reference_*

## What NOT to save

Code patterns derivable by reading current state, git history and who-changed-what, debugging fix recipes, anything already in CLAUDE.md, and ephemeral task details. Even if the user asks, ask back "what was *surprising* about this?" and save only that.

## Promotion workflow

Per-project memory that proves universal (observed in 2 or more projects) graduates to global. See `~/.claude/memory/global/README.md` for promotion criteria and format.

## Before recommending from memory

Memories go stale. A memory naming a file, function or flag is a claim that **it existed when written**. Before recommending action on it, check that the file exists and grep for the function or flag. If the user is about to act, verify first. "Memory says X exists" ≠ "X exists now."

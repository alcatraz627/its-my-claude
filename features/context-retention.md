---
brief: Session ID generation, core-dump/catchup, checkpoint triggers, scratchpad tiers, archive-notes cadence
triggers:
  - skill:core-dump
  - skill:catchup
  - skill:archive-notes
  - topic:session-id
  - topic:context-management
  - phrase:"session start"
related: [features/wal.md, features/proposals.md]
tier: 1
category: features
updated: 2026-04-24
stale_after_days: 90
---

# Context Retention
Session ID, context management, checkpoints, scratchpad, and archive cadence — all the mechanisms that keep long sessions coherent.

## Session ID — MANDATORY

At the start of every session, generate a short session ID based on the initial user prompt. Format: `[keyword]-[keyword]-[2hex]`.

**Rules:**
- 1-2 topic keywords (verb + noun preferred: `add-upload`, `debug-cache`)
- Truncate each keyword to max 5 chars (`refactor` → `refac`)
- 2 hex chars from prompt content (sum char codes mod 256, hex)
- Announce at start: `Session: [id]`
- Use in WAL session headers, checkpoint files, runtime notes, `/core-dump` output
- Vague prompts ("hi", "help") → `misc-[2hex]`

**Examples:** "Fix auth bug" → `fix-auth-7a` · "Add chart" → `add-chart-f1` · "Refactor navigation" → `refac-nav-a0`

## Session rules for context retention

- **Implementation sessions** (files edited) → `/core-dump` at end and major milestones
- **After editing ≥3 files, at user break signals, or ~40 messages** → checkpoint
- **Exploration/Q&A sessions** → compact is fine, skip `/core-dump`
- **After compaction** → immediately write a checkpoint of what you still know
- **Auto-checkpoint at tool #30:** write a WAL checkpoint. At tool #60, run `/core-dump mini`.

## 70% context trigger

When approaching 70% context usage, proactively offer to generate a structured state summary (WAL checkpoint + `/core-dump mini`) before compaction loses critical details.

## Compaction preservation

Always preserve: modified file paths with line numbers, pending task IDs, architectural decisions, test commands, user-specified constraints. Use `/compact <instructions>` (targeted) over bare `/compact`.

## Documentation layers (don't duplicate)

- **WAL** = what happened (for next agent) — see `features/wal.md`
- **Runtime notes** = what was learned (for future sessions)
- **Scratchpad** = what was thought (for current session)

## Scratchpad system

Two-tier. Local (`.claude/scratchpad/`): plans, learnings. Global (`~/.claude/scratchpad/global/`): cross-project patterns. Scripts in `~/.claude/scratchpad/scripts/` — see `~/.claude/scratchpad/README.md`.

Workflow: create plan entry before non-trivial tasks → append learnings → promote cross-project insights to global.

## Post-session insights

At session end, prepend a note to `.claude/skills/runtime-notes.md` (project-relative). Skip only for purely read-only sessions.

Format: `## session: [description] [session-id] — YYYY-MM-DD` heading, `**Purpose:**` one-liner, `**Insights:**` numbered 2-6 points of reusable observations, `---` separator. Use `prepend-runtime-note.sh` if available.

## Archive cadence

Run `/archive-notes` when `runtime-notes.md` exceeds 800 lines OR every 3 weeks, whichever first. (Evidence: `skills/runtime-notes.md` reached 2621 lines — soft rule was being ignored.)

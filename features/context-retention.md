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
updated: 2026-10-13
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

- **`/core-dump` runs only when the owner asks** (a typed `/core-dump`, also inline in a longer message) **or on keep-warm's last wake.** An agent never runs it on its own; a task notification, ipc mail, goal check-in or context nudge is not the owner. Owner ruling 2026-10-13: "I want to cut down on core-dump usage, but make it valuable when it happens." The transcript is the crash fallback (`/retro-dump`, `/revive`).
- **Suggest, once, in one line:** at a task boundary with 60% or more context used and work queued, say that `/core-dump` then `/clear` would pay for itself after about 50 calls. Then keep working.
- **Auto-checkpoint at tool #30:** write a WAL checkpoint (cheap, no model synthesis).
- **After compaction:** re-verify state before acting (`rules/testing-patterns.md` `[post-compact]`).
- **Approvals carry across compaction and /clear** as Standing authorizations: the owner's verbatim words, the target, one-shot or standing. Re-ask only when the target moved. Push-to-main and policy asks are Switchboard's gates and are unaffected.

## 70% context

At 70% and above, keep the session workspace notes current. Do not dump on your own.

## Compaction preservation

Always preserve: modified file paths with line numbers, pending task IDs, architectural decisions, test commands, user-specified constraints. Use `/compact <instructions>` (targeted) over bare `/compact`.

**Standing constraints + caveats carry verbatim.** Every summarizing surface (checkpoint, compaction, catchup briefing, away-recap) copies Standing constraints and Standing caveats forward word-for-word — never paraphrased, never dropped for brevity. Summarization dropping them while task momentum survives is the documented cross-session drift engine (`rules/invariant-graduation.md`).

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

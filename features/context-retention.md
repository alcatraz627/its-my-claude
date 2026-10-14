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
Session ID, context management, checkpoints, scratchpad and archive cadence: the mechanisms that keep long sessions coherent.

## Session ID (mandatory)

At the start of every session, generate a short session ID from the initial user prompt. Format: `[keyword]-[keyword]-[2hex]`.

**Rules:**
- 1-2 topic keywords (verb + noun preferred: `add-upload`, `debug-cache`)
- Truncate each keyword to max 5 chars (`refactor` → `refac`)
- 2 hex chars from prompt content (sum char codes mod 256, hex)
- Announce at start: `Session: [id]`
- Use in WAL session headers, checkpoint files, runtime notes, `/core-dump` output
- Vague prompts ("hi", "help") → `misc-[2hex]`

**Examples:** "Fix auth bug" → `fix-auth-7a` · "Add chart" → `add-chart-f1` · "Refactor navigation" → `refac-nav-a0`

## Session rules for context retention

- **`/core-dump` runs only when the owner asks** (a typed `/core-dump`, also inline in a longer message) **or on keep-warm's last wake.** An agent never runs it on its own. A task notification, ipc mail, goal check-in or context nudge is not the owner. Owner ruling 2026-10-13: "I want to cut down on core-dump usage, but make it valuable when it happens." The transcript is the crash fallback (`/retro-dump`, `/revive`).
- **Suggest once, in one line:** at a task boundary with 60% or more context used and work queued, say that `/core-dump` then `/clear` would pay for itself after about 50 calls. Then keep working.
- **Auto-checkpoint at tool #30:** write a WAL checkpoint (cheap, no model synthesis).
- **After compaction:** re-verify state before acting (`rules/testing-patterns.md` `[post-compact]`).
- **Approvals carry across compaction and /clear** as Standing authorizations: the owner's verbatim words, the target, one-shot or standing. Re-ask only when the target moved. Push-to-main and policy asks are Switchboard's gates and are unaffected.

## 70% context

At 70% and above, keep the session workspace notes current. Do not dump on your own.

## Compaction preservation

Always preserve: modified file paths with line numbers, pending task IDs, architectural decisions, test commands, user-specified constraints. Use `/compact <instructions>` (targeted) over bare `/compact`.

**Standing constraints and caveats carry verbatim.** Every summarizing surface (checkpoint, compaction, catchup briefing, away-recap) copies Standing constraints and Standing caveats forward word for word. Never paraphrase them and never drop them for brevity. When summarization drops them while task momentum survives, the session drifts across sessions (`rules/invariant-graduation.md`).

## Documentation layers (don't duplicate)

- **WAL** = what happened (for the next agent). See `features/wal.md`.
- **Runtime notes** = what was learned (for future sessions).
- **Scratchpad** = what was thought (for the current session).

## Scratchpad system

Two tiers. Local (`.claude/scratchpad/`) holds plans and learnings. Global (`~/.claude/scratchpad/global/`) holds cross-project patterns. Scripts are in `~/.claude/scratchpad/scripts/`; see `~/.claude/scratchpad/README.md`.

Workflow: create a plan entry before non-trivial tasks, append learnings, then promote cross-project insights to global.

## Post-session insights

At session end, prepend a note to `.claude/skills/runtime-notes.md` (project-relative). Skip only for purely read-only sessions.

Format: a `## session: [description] [session-id] — YYYY-MM-DD` heading, a one-line `**Purpose:**`, `**Insights:**` as numbered 2-6 points of reusable observations, and a `---` separator. Use `prepend-runtime-note.sh` if available.

## Archive cadence

Run `/archive-notes` when `runtime-notes.md` exceeds 800 lines or every 3 weeks, whichever comes first. (Evidence: `skills/runtime-notes.md` reached 2621 lines, so the soft rule was being ignored.)

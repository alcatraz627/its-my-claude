# Background Cleanup Runs

Recurring maintenance tasks for Claude to run periodically or flag to the user.

---

## Recurring (Scheduled)

### Every 3 Weeks — Archive Runtime Notes
Run `/archive-notes` on `~/.claude/skills/runtime-notes.md`.
Keeps the file under the 50-entry / ~10K token threshold.
Command: `/archive-notes`

---

## One-Time / Periodic

### Config Deep Dive — Core Dump for All Claude Configs
Do a detailed `/core-dump` covering:
- Current state of all `~/.claude/` config files
- Active MCPs, enabled plugins, hook inventory
- Skills catalogue with recent usage (from runtime-notes)
- Outstanding improvement items not yet applied
Purpose: cross-session reference when making large config changes.

---

## Weekly Todo Items

### "Dreaming Mode" — TBD
**Definition to be provided by user.**
Add to next week's weekly todo: ask user to define "dreaming mode" so it can be scheduled/implemented.
Placeholder: a background reflection or synthesis mode where Claude reviews recent sessions and surfaces patterns, gaps, or opportunities without a specific task.

---

_Last updated: 2026-04-08 (audit-conf-a3 session)_

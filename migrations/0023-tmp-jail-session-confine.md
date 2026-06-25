---
number: 0023
title: Session-scoped /tmp jail — PreToolUse confine hook + run/ dir + tmp-jail CLI
slug: tmp-jail-session-confine
status: complete
date: 2026-06-25
affected_paths:
  - run/tmpjail/
  - scripts/hooks/tmp-jail-guard.sh
  - scripts/hooks/tmp-jail-cleanup.sh
  - scripts/tmp-jail
  - settings.json
  - features/tmp-jail.md
  - CLAUDE.md
---

# Migration 0023 — Session-scoped /tmp jail

## Summary

Adds an opt-in, session-local "/tmp jail": when a session is jailed, its writes
(and its sub-agents') are confined to `/tmp` (and `/private/tmp`); reads are
untouched. Built as a global PreToolUse hook gated by a per-session marker, so the
single registration enforces per-session and never contaminates other running
sessions. The off-switch is **by instruction, best-effort** — the agent is told to
ask the user to run `tmp-jail off <session_id>`, and the gate blocks the common
self-lift paths (the off command incl. path-qualified, marker delete via
rm/trash/unlink/truncate/find-delete, settings edits, `..` traversal). It is NOT a
hard guarantee: a determined agent with arbitrary Bash can still escape (interpreter
writes), the same ceiling as the Bash write gate. A hook is a guardrail, not a
sandbox; for a hard whole-session lock, plan mode already exists.

Three structural facts make this a migration, not an in-place edit: a NEW top-level
dir (`~/.claude/run/`), a NEW always-on PreToolUse hook in `settings.json`, and a
NEW PATH command (`tmp-jail`).

## What changes

| From | To | Why |
|---|---|---|
| (no `~/.claude/run/`) | `~/.claude/run/tmpjail/<session_id>` markers | per-session jail state, keyed by the session_id from the hook payload |
| (no jail hook) | `scripts/hooks/tmp-jail-guard.sh` registered PreToolUse (`Write\|Edit\|MultiEdit\|NotebookEdit\|Bash`) | the enforcement: allow writes under /tmp, block elsewhere when jailed |
| (no cleanup) | `scripts/hooks/tmp-jail-cleanup.sh` registered SessionEnd | tidy this session's marker on exit (orphans are harmless anyway) |
| (no CLI) | `scripts/tmp-jail` → `~/.local/bin/tmp-jail` (`on`/`off <id>`/`status`) | user control surface |
| (no doc) | `features/tmp-jail.md` + a CLAUDE.md features-table row | agent + human awareness |

## What does NOT change

- Nothing is jailed by default. The hook is a fast no-op (read session_id, stat one
  file, exit 0) unless that session has a marker. Off = zero friction.
- Other sessions are never affected — enabling the jail in one session writes only
  its own marker.
- It does not survive a restart (markers are per-session; a new session is clean).
- No mute file (deliberate). There is intentionally no `.no-tmp-jail` escape — a
  mute hatch would be a silent one-touch bypass of the off-switch.
- Reads are never blocked; only writes outside /tmp are.

## Verification

- [x] 20/20 standalone branch tests pass (`/tmp/test-tmp-jail.sh`): not-jailed→allow,
      on-switch creates marker, jailed allows /tmp + /private/tmp + reads, blocks
      non-/tmp writes (file tools + Bash redirect/cp/mv/sed), agent `tmp-jail off`
      blocked, relative-redirect gated by cwd, fail-open on malformed/no-session_id.
- [x] `settings.json` valid after registration; diff was exactly the two added
      entries (backup at `/tmp/settings.json.bak`).
- [x] CLI smoke-tested: `tmp-jail status` / `off <id>` / usage all correct, on PATH.
- [ ] LIVE integration confirmed in a fresh session (hooks load at session start, so
      the session that built this cannot self-test): run `tmp-jail on`, attempt a
      write outside /tmp (expect block), then `tmp-jail off <id>`.

## Known limits (recorded, accepted)

- A hook is a guardrail, not a sandbox — it cannot confine a Bash-enabled agent
  against its will. Best-effort on Bash: catches common write/self-lift forms but a
  `python -c "open('/x','w')"` / `node -e` / `perl -e` can still escape (closable by
  also gating interpreter-eval while jailed; not yet enabled). The default Bash
  sandbox does NOT block FS writes (verified 2026-06-25). This serves the
  toggleable, /tmp-writable niche; for a hard whole-session lock, plan mode exists.
- The Bash gate conservatively over-blocks (a `cp /Users/x /tmp/y` that only reads
  from outside /tmp is blocked). A false block just routes the agent to ask the user.

## Rollback

```bash
# 1. Remove the two hook entries from settings.json (restore the pre-change backup
#    if still present), then:
#      jq 'del(.hooks.PreToolUse[] | select(.hooks[].command | test("tmp-jail-guard")))
#          | del(.hooks.SessionEnd[] | select(.hooks[].command | test("tmp-jail-cleanup")))' \
#        ~/.claude/settings.json > /tmp/s.json && cp /tmp/s.json ~/.claude/settings.json
# 2. trash ~/.claude/scripts/hooks/tmp-jail-guard.sh ~/.claude/scripts/hooks/tmp-jail-cleanup.sh \
#          ~/.claude/scripts/tmp-jail ~/.local/bin/tmp-jail ~/.claude/run/tmpjail
# 3. Remove the features/tmp-jail.md row from CLAUDE.md + trash features/tmp-jail.md
```

Consider rollback if the always-on hook ever measurably slows tool calls, or if a
fail-open bug ever blocks a write in a non-jailed session.

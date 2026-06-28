---
name: plugs
description: Show what context-injecting and learning-capturing "plugs" are wired into the session (start / per-turn / compact / end) — what's registered, what's muted, and the current live state each plug acts on. Use when the user asks "what's plugged in", "what context is being injected", "what's muted", or wants to understand/audit the session lifecycle hooks. Renders live status; the full catalog is features/session-plugs.md.
allowed-tools: Bash, Read
argument-hint: "[--mutes]"
user-invokable: true
---

## Brief

Answer "what's happening in my session and what's shaping my context" by rendering
the live status of the session plugs. This reads existing artifacts only (no
telemetry of its own) and is run on demand — never injected, because a catalog of
plugs injected every session would be the exact noise it exists to measure.

## Run it

```bash
bash ~/.claude/scripts/plugs.sh          # full live status
bash ~/.claude/scripts/plugs.sh --mutes  # just the active mute files
```

Print the output as-is. It shows: the hook count registered at each lifecycle
point, live signals (context fill, open proposals, latest backlog triage, last
consolidate run, dream-injection volume), and the currently active mute files
(silenced plugs/guards — these linger silently, so surfacing them matters).

## When the user wants the full catalog or detail on one plug

Read `features/session-plugs.md` — the static registry of every plug with its
trigger (blanket vs conditional), direction (inject vs capture), token cost, mute
file, and current observability. Use it to explain what a specific plug does or to
reason about whether a blanket injector is earning its tokens.

## Known gap (informs the ledger work)

The reader cannot yet show **per-session firing history** (which plug fired this
session, and the fired-vs-acted-on ratio) — most plugs leave no per-firing trace,
and a script can't reliably pin the current session from `/tmp` markers. That gap
is what a `plug-events` ledger (keyed on `session_id`, written via
`scripts/ledger/ledger-common.sh`) would close. Until then, report the machine-level
live state this renders, and say the per-session/efficacy view is not yet recorded.

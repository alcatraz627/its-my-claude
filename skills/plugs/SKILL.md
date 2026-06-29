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
consolidate run, dream-injection volume), the currently active mute files
(silenced plugs/guards — these linger silently, so surfacing them matters), and
the per-plug firing cost ranked by tokens spent (from the plug-events ledger,
scoped to this session when CLAUDE_CODE_SESSION_ID is set, all-time otherwise).

## When the user wants the full catalog or detail on one plug

Read `features/session-plugs.md` — the static registry of every plug with its
trigger (blanket vs conditional), direction (inject vs capture), token cost, mute
file, and current observability. Use it to explain what a specific plug does or to
reason about whether a blanket injector is earning its tokens.

## Recorded vs not (the efficacy picture)

The **FIRED side** is now recorded: each instrumented plug appends one
`session_id`-keyed line to `ledger/plug-events.jsonl` via `ledger-common.sh`, so the
reader shows how often each plug fires and how many tokens it spends (ranked). That
alone flags a blanket injector that is expensive relative to a conditional one — the
start lane's per-session cost dwarfs the conditional ctx-pressure hook, for example.

The **ACTED side** is the remaining gap: whether an injection was actually used, or a
stubbed proposal promoted. That needs a feedback signal plus a `detectors.toml` entry
(bound to `attention-scarcity`) that raises an alert when a plug fires often without
being acted on. Until that lands, report the fired-frequency + token-cost this
renders, and note the acted-on ratio is not yet measured.

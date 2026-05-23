# subconscious/hooks/ — Hook Contract

> The subconscious system maintains its own hook tree at `~/.claude/subconscious/hooks/`, separate from `~/.claude/scripts/session-mgmt/`. This doc explains what each hook does, how to mute, and how to debug.

## Why hooks live here (and not under scripts/)

The subconscious system is a daemon-driven self-reflection subsystem with its own state, config (`config.toml`), and lifecycle. Its hooks are tightly coupled to the daemon's internal state machine (idle threshold, dream cycles, wake promotion). Keeping them co-located with the rest of the daemon code rather than in the generic `scripts/session-mgmt/` tree:

1. Keeps the daemon's concerns inside one directory tree
2. Makes the daemon installable / removable as a unit
3. Avoids accidental coupling to other session-mgmt scripts

The hooks ARE wired into `~/.claude/settings.json` like any other hook — they just point to subconscious paths.

## The 5 hook entrypoints

All scripts read hook input from stdin (per Claude Code hook protocol).

| Hook | When | What it does | Mute |
|---|---|---|---|
| `session-start.sh` | SessionStart | Loads dream-insights state; may inject "today's intentions" hint | `touch ~/.claude/subconscious/.no-session-start-hook` |
| `user-prompt-submit.sh` | UserPromptSubmit | Records prompt for metacog/activity; may surface dream-derived nudge | `touch ~/.claude/subconscious/.no-prompt-hook` |
| `post-tool-use.sh` | PostToolUse | Logs tool usage to metacog/samples.jsonl for pattern detection | `touch ~/.claude/subconscious/.no-tool-hook` |
| `stop.sh` | Stop | Triggers idle check (if idle > threshold, schedules dream cycle) | `touch ~/.claude/subconscious/.no-stop-hook` |
| `post-wake.sh` | (custom) | Fires after daemon wakes from a dream cycle — surfaces new briefings | — |

All hooks `exit 0` always — never block tool/prompt execution. Failures log to `subconscious/logs/launchd.stderr.log`.

## State writes

| Path | Owner | Notes |
|---|---|---|
| `dreams/journal.jsonl` | dreaming module | Experience log |
| `dreams/ingest-queue/*.json` | external (`/core-dump`) | Checkpoint insights for pattern detection |
| `dreams/pending-todos.jsonl` | aggregate-todos.sh | Derived view, regenerable |
| `dreams/briefings/` | dreaming module | Daemon-published insight briefings |
| `metacog/samples.jsonl` | post-tool-use hook | Raw tool-call samples (37 MB; main bulk) |
| `metacog/activity.jsonl` | post-tool-use hook | Tool-call summary (~3.8 MB) |
| `introspection/chains/*.jsonl` | introspection module | Thought-chain logs |
| `logs/launchd.stderr.log` | launchd | Daemon stderr (rotates) |
| `logs/i-dream.log.YYYY-MM-DD` | daemon | Daily daemon log |

## Daemon control

The daemon runs via launchd. PID in `subconscious/daemon.pid`. Socket at `daemon.sock`.

```bash
# Status
cat ~/.claude/subconscious/state.json

# Stop / restart
launchctl unload ~/Library/LaunchAgents/dev.claude.subconscious.plist
launchctl load ~/Library/LaunchAgents/dev.claude.subconscious.plist
```

## Mute everything

```bash
touch ~/.claude/subconscious/.daemon-off
```

The daemon checks this file on each cycle and exits cleanly if present. Individual hook mutes are listed above.

## Why the hooks are in settings.json (not auto-discovered)

Claude Code's hook system requires explicit registration in settings.json. The subconscious daemon CAN'T self-register — it would need to write to settings.json on install. Current installation: manual entries in settings.json point to subconscious paths.

If the daemon is removed, those settings.json entries become broken hooks (silent — async hooks never block). Cleanup: `rg subconscious ~/.claude/settings.json` shows which blocks to remove.

## Sizing notes (current as of 2026-05-17)

- Total subconscious/ ≈ 101 MB
- Biggest: `metacog/samples.jsonl` (37 MB), `logs/launchd.stderr.log` (6 MB), `dreams/journal.jsonl` (3.8 MB indirectly via activity)
- Log rotation: `logs/*.log.YYYY-MM-DD` files rotate daily; old ones could be gzipped by a startup task (not yet implemented)
- `crash-reports/`: empty (good — daemon hasn't crashed)

## See also

- `~/.claude/subconscious/config.toml` — daemon config (idle threshold, model selection, budget)
- `~/.claude/subconscious/scripts/ingest-checkpoint.sh` — checkpoint → ingest-queue (called by checkpoint/write.sh)
- `~/.claude/subconscious/scripts/aggregate-todos.sh` — pending-todos.jsonl regenerator
- `NAMESPACE.md` § `::improvement::dreams` — namespace registration

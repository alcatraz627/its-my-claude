# `~/.claude/scripts/startup/` — std::claude::startup

> Login-time maintenance for `~/.claude/`. Fires once per macOS user-login session via LaunchAgent.

## Files

| Path | Role |
|---|---|
| `run.sh` | Orchestrator — runs every `tasks/*.sh` in lexical order |
| `tasks/10-cleanup-tab-state.sh` | Drops stale `/tmp/claude-tab-*` (>7 days) |
| `tasks/20-prune-transcripts.sh` | Gzip `projects/*.jsonl` >6 mo, delete `.jsonl.gz` >12 mo |
| `~/Library/LaunchAgents/dev.claude-startup.plist` | Launch trigger (RunAtLoad=true) |
| `~/.claude/logs/startup.log` | Run history |

## Cadence

This is a single-user macOS box where the user **restarts ~weekly** but doesn't log out otherwise. RunAtLoad=true fires once per login session — which here means roughly once per reboot. No LaunchDaemon needed (that's for boot-time, requires sudo, no benefit on a single-user system).

## Usage

```bash
bash ~/.claude/scripts/startup/run.sh             # run everything
bash ~/.claude/scripts/startup/run.sh --dry-run   # show what would happen
bash ~/.claude/scripts/startup/run.sh --task 10-cleanup-tab-state
bash ~/.claude/scripts/startup/run.sh --list      # list available tasks
```

## Adding a task

1. Create `tasks/NN-<slug>.sh` (numeric prefix controls order)
2. Make it executable; accept `--dry-run`
3. Print a one-line summary at end
4. Add a `# REVIVAL:` comment block at top explaining how to undo

## Revival

Each task documents its own revival path in its header. Quick reference:

- **tab-state cleanup** — files re-created by hooks on next session start
- **transcript prune** — `gunzip` restores compressed files byte-for-byte; deletion at 12 mo is hard (irreversible)

## See also

- `NAMESPACE.md` — entry for `std::claude::startup`
- `FOLDERS.md` — top-level folder map

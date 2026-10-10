---
brief: zrecover is the desktop-session safeguard suite (LaunchAgent com.alcatraz.zrecover): a memory/CPU reaper with per-app rules, freeze escalation and temporary grants; `zrecover run claude` mirrors the TUI screen to disk so an unsent prompt survives a crash; `zrecover restore` replays the pre-reboot sessions into Ghostty with resume commands.
triggers:
  - tool:zrecover
  - topic:zrecover
  - topic:memory-pressure
  - topic:runaway-process
  - topic:crash-recovery
  - phrase:"system crashed"
  - phrase:"mac is slow"
  - phrase:"who killed"
  - phrase:"get my sessions back"
related:
  - dev-servers
  - local-models
tier: 2
category: features
updated: 2026-10-10
stale_after_days: 180
---

# zrecover: keep the desktop alive, get the sessions back

Two jobs. Before a crash, stop any one process from taking the machine down.
After one, hand back every Claude session that was open, with its resume
command and the last thing on its screen, including a note typed into the
prompt box and never sent.

Suite at `~/.claude/scripts/zrecover/` (`zrecover` on PATH via zcmd), state
under `~/.claude/zrecover/`, actions logged to `~/.claude/logs/zrecover.jsonl`,
daemon `~/Library/LaunchAgents/com.alcatraz.zrecover.plist`. It is the
machine-wide sibling of two narrower guards that still run: `dev-guard.mjs`
(recycles a Next dev server) and local-models' `mem-guard.py` (model runners).

```
                 ┌──────────── zrecover reap (daemon, every 2 s) ────────────┐
   kernel ──────►│ pressure · swap · load      per-process footprint + cpu   │
                 │   ▼ memory cap   ▼ pressure shed   ▼ demote/kill   ▼ freeze│
                 │                 grants.json raises one cap, temporarily    │
                 │ every 30 s: sessions.json  (claude pids ⟵ ipc registry)    │
                 └────────────────────────────────────────────────────────────┘
   zrecover run claude ──► pty passthrough ──► Ghostty (unchanged rendering)
                     └──► pyte screen ──► screens/<pid>.txt every 5 s
   reboot ──► first daemon tick moves sessions.json ──► last-boot.json
   zrecover restore --open ──► one Ghostty window per session: claude --resume
```

## The reaper

| Signal | Threshold (default) | Action |
|---|---|---|
| One process's physical footprint | 12 GB | notify once |
| One process's physical footprint | 24 GB | kill it |
| Kernel pressure `critical` | immediate | kill the largest killable process over 1 GB |
| Kernel pressure `warn`, or swap over 12 GB | held 20 s | kill the largest killable process over 3 GB |
| One process over 3 cores | held 90 s | demote to background QoS (`taskpolicy -b`) |
| A demoted process still over 3 cores, load1/ncpu at least 1.0 | 10 min after demotion | kill it |
| Machine frozen: load1/ncpu over 1.5 | held 30 s | kill the top CPU burner outright |

The freeze rule exists because of the 149 s WindowServer watchdog that panics
the kernel: a pinned CPU has to be relieved inside that window.

Per-app rules tighten the globals; first match wins, matched on the command's
identity and its full path. Under pressure, `pressure_first` apps are shed
before the generic largest process.

| Rule | Matches | Memory kill | CPU demote / kill |
|---|---|---|---|
| ollama | `ollama`, `llama-server`, `mlx_vlm`, `mlx_lm` | 20 GB | globals |
| steam | `steam_osx`, `Steam Helper`, anything under `Steam/steamapps/` | warn 10, kill 16 GB | over 6 cores for 30 s, kill 120 s later |
| servers | `node`, `bun`, `python` (any case), `next-server`, `uvicorn`, `vite`, `tsx`, `ts-node` | 8 GB | over 4 cores for 60 s, kill 180 s later |

Never touched: processes of another user, executables under system paths, and
the protected names (Claude and Codex sessions, Ghostty, WindowServer, Finder,
Dock, launchd, sshd, pm2, tmux, the guards themselves). Children of a protected
process are not protected. "Footprint" is Activity Monitor's Memory column
(resident plus compressed), read through libproc; RSS undercounts a leaking
process once the compressor holds it.

### Grants: more memory for one run, without losing the desktop

```
zrecover allow --match Frostpunk --gb 30 --for 3h
zrecover allow --pid 72489 --gb 40
zrecover grants · zrecover revoke <id>
```

A grant lifts the memory cap for its match, up to `grant_max_gb` (48 of 64).
It does not switch off the pressure or freeze rules: a granted process is shed
last under pressure, not never. That is the line between "this run may be
big" and "this run may take the machine down". Grants expire on their own
(default 2 h) and the daemon picks up changes within one scan.

## Screen capture: `zrecover run claude`

`wrap.py` gives the program a pty and passes every byte through untouched, so
Claude renders exactly as it does bare (no tmux). The same output stream also
drives an in-memory terminal (pyte), and every 5 s the screen is written as
text to `~/.claude/zrecover/screens/<pid>.txt`. A test types a marker into the
real Claude prompt box and finds it in the file. Measured on a live session:
about 1 percent of a core and 23 MB. The `claude` alias in `~/.zshrc` routes
interactive runs through it; `command claude` is the bare binary, and scripts
are unaffected.

Limits: the capture is the rendered screen, so a draft longer than the visible
prompt box loses the scrolled-off lines. Scroll position and a pending
permission prompt are not restorable; `--resume` gives back the conversation.

## After a crash: `zrecover restore`

Every 30 s the daemon writes `sessions.json`: each interactive `claude`
process, its session id (from the IPC registry at
`~/.claude-ipc/data/ipc.sqlite`), cwd, tty, and its screen file when wrapped.
The first write after a reboot moves the previous file to `last-boot.json`.

Every 15 min it also writes the **resume bundle**,
`~/.claude/zrecover/bundles/<stamp>.md` (+ `.json`, `latest.md` symlink, kept
14 days): for every live session, the resume command, cwd, git branch and
dirty count, last prompt and last reply (read from the last 256 KB of the
transcript, never the whole file), the checkpoint it last wrote, its task
store, and the tail of its screen capture when wrapped. The cost is a few
stat calls and tail reads per session, well under a second; the 30 s
sessions.json is the cheap pointer, the bundle is the one place to resume from.

`zrecover restore` reads, in order: `--from FILE`, `last-boot.json`, the newest
bundle from a previous boot, or `--reconstruct`, which rebuilds the set from
transcripts active in the hours before the last kernel panic (interactive ones
only: those with a tty in the registry or larger than the automated sweeps),
minus sessions already live or already resumed. `--detail` adds the last
exchange; `--open` launches each in a Ghostty window (a second Ghostty
instance, which quits when its windows close); `--only 1,3` picks;
`--dry-run` prints the commands. `zrecover bundle list|show|now`,
`zrecover screen <pid|alias|latest>` and `zrecover sessions --detail` are the
browsing surface.

## The CLI

Non-interactive throughout, built to `conventions/cli-help-design.md` and
`conventions/agent-first-tools.md`: every data command takes `--json`, colour
is off when piped or under `NO_COLOR`/`TERM=dumb`, errors name the next
command, exit codes are 0 ok / 1 failed / 2 usage, `-h` on any command.

| Group | Commands |
|---|---|
| watch | `status` · `plan` (dry-run: what it would do now) · `top [-n N] [--by mem\|cpu]` · `explain <pid\|regex>` (verdict + effective limits) · `log [N] [--kind kill,demote] [--follow]` |
| steer | `allow` · `grants` · `revoke <id\|all>` · `pause [--for 1h]` · `resume` · `rules` · `protect list\|add\|rm` · `config show\|get\|set\|unset\|path\|edit` |
| recover | `run -- <cmd>` · `sessions [--detail]` · `restore [--open] [--only 1,3] [--dry-run] [--detail] [--from FILE] [--reconstruct --before T --hours H]` · `bundle list\|show\|now` · `screens` · `screen <pid\|alias\|latest>` |
| maintain | `daemon status\|start\|stop\|restart\|install\|uninstall` · `doctor` (17 checks, exit 1 on any) · `test [--no-claude]` · `examples` · `help <crash\|slow\|big\|alias>` · `version` |

`config set` validates the key and type, writes
`~/.claude/scripts/zrecover/config.json`, and says to restart; `daemon
restart` is one command. `pause --for` writes an expiry into
`~/.claude/.no-zrecover`; the daemon honours and clears it. The daemon writes a
heartbeat (`~/.claude/zrecover/daemon.json`) every tick, which is what `status`
and `doctor` read, so "alive" means ticking, not merely loaded in launchd.
Tab completion: `~/.zfunc/_zrecover` (linked by `zcmd install`).

Tests: `zrecover test` runs 17 engine, 35 CLI and 5 wrapper cases; the
wrapper cases drive a real `claude`.

## Known limits

The 2026-10-10 panic was a WindowServer watchdog with the compressor at 1
percent: memory was not the cause. zrecover covers the memory and CPU
starvation routes to that panic. A GPU or driver hang is kernel-side and no
userspace kill reaches it; on this machine Steam games are the likely source.

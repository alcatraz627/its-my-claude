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
  - features/dev-servers.md
  - features/local-models.md
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
| A demoted process still over 3 cores, load1/ncpu at least 1.0 | 10 min after demotion | kill it, after a 45 s notice |
| Machine frozen: load1/ncpu over 1.5 | held 30 s | slow what must not die, then kill the top burner if that would help, after a 45 s notice |

The freeze rule exists because of the 149 s WindowServer watchdog that panics
the kernel: a pinned CPU has to be relieved inside that window. From the moment the freeze
condition is met, a clear runaway dies in about 80 s. Load is a 1 minute average, so that
condition is met some way after the runaway starts, and the kill can land 130 to 200 s after
its onset. Whether the watchdog's clock starts at onset is not known.

Per-app rules tighten the globals; first match wins, matched on the command's
identity and its full path. Under pressure, `pressure_first` apps are shed
before the generic largest process.

### Who can be killed

What losing a process would cost decides whether it can be chosen at all; among those that
can, the top burner goes first. Every process has a class, and `zrecover explain <pid|name>` shows it.

| Class | What can happen | Examples |
|---|---|---|
| protected | Nothing | Claude sessions, Ghostty, WindowServer, system paths |
| slow-only | Priority lowered in a freeze, never killed | The Android emulator on `engineering` |
| restartable | Priority lowered, then killed | Dev servers, testing browsers, models, Chrome tabs |

CPU alone never kills the main process of an app in `/Applications` or `~/Applications`, or
anything belonging to the app in front of you, tabs included. If macOS will not say which
app is in front, the last answer keeps a countdown going for a minute but cannot finish a
kill, because you may have just switched to that app. After that, nothing is killed for CPU
and the ladder's progress towards a kill is held, and a countdown waits while the freeze
lasts. Memory rules ignore all of this and act at once,
because running out of memory is the emergency.

A freeze kill also has to be worth it. The target must use at least `freeze_min_cores` and
25% of your own processes' CPU. Kernel and other users' CPU is not visible here, so a freeze
they cause can still cost you a process of yours that fits those limits. A target already in
its countdown has a lower bar, 60% of those, so a share wobbling around the limit does not
restart it, but a freeze countdown is called off if its burn falls under half of where it began.

CPU kills are limited by count: at most one every 2 minutes and two in any 10 minutes
(`freeze-kill-limit` in the log). This is deliberately not a measure of whether a kill helped,
because on a saturated Mac neither CPU nor the lagging load average can say so reliably;
`prop-20261105-151103-b1` holds the idea of judging by load. It is a time window rather than
"per freeze" because load dipping under the line for one scan would otherwise reset the count.
The price of all this is that a third runaway waits up to 10 minutes, a second can die past
the 149 s watchdog, a freeze spread across many small processes kills nothing, and a runaway
frontmost app is left running.

A process burning at least twice as much as the one counting down takes over the countdown,
so a small process does not use up the slot. One whose kill fails is left alone for 10 minutes,
so it does not block the next target.

The notice starts again after a silence over 150 s, which means the Mac slept, and a pause
drops it, so a countdown does not finish unseen. After a shorter sleep the measured burn usually
reads too low to carry on, so the countdown is called off; nothing dies on waking.

Slowing a process in a freeze is undone when load stays under 1.25 for a minute, when the
app comes to the front, when zrecover is paused, or when the daemon stops. A daemon killed
outright gives it back when it next starts, from `zrecover/slowed.json`. While load sits
between 1.25 and the 1.5 freeze line, a slowed process stays slowed, and nothing limits how
long. The older demote-then-kill ladder still demotes for the life of the process.

Each kill, demotion, restore and countdown row in the log names the five busiest of your own
processes under `burners`, protected ones included, so `zrecover log --json` shows what was
really using the CPU.

### Is the machine really stuck?

Load counts everything waiting to run, so it can be high while the Mac feels fine. The
daemon also logs how late it wakes from its 2 s sleep: `tick-lateness` rows every 5 minutes,
and one at once for a stall of 5 s or more. These change no decision yet. Read them with
`zrecover log 500 --kind tick-lateness`; once they show a useful threshold, they can drive
the freeze rule.

The 2 s wake stays. A tick reads three kernel values in about 0.01 ms; nearly all the
daemon's cost is the 10 s scan, about 65 ms, which comes to about 0.3% of one core.

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

To keep one expensive job alive for a while, give it a class instead. Unlike
`zrecover protect add`, this ends on its own:

```
zrecover allow --match my-audit --class slow-only --for 6h
zrecover allow --pid 72489 --class protected --for 2h
```

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

Tests: `zrecover test` runs the engine, CLI and wrapper cases; the
wrapper cases drive a real `claude`.

## As a memory guard on another Mac

The reaper needs only Python's standard library and the Command Line Tools. It does not
read pm2 or any Claude setup, and `svc`'s reaper is a separate tool you can leave behind.

```
tar -czf zrecover-guard.tgz --exclude .venv --exclude __pycache__ --exclude config.json \
    -C ~/.claude/scripts zrecover            # here
tar -xzf zrecover-guard.tgz                  # on that Mac
zrecover/install-guard.sh creative           # choose a profile; installs and starts the daemon
```

If macOS shows a Background Items notice, leave it allowed.

## Profiles

A profile is a named set of caps, per-app rules and protected apps in
`scripts/zrecover/profiles/<name>.json`. `zrecover profile list`, `profile show [name]`,
`profile use <name>` and `profile clear` manage it, and `daemon restart` applies it. Settings
apply in rising order: built-in, the profile, then this Mac's `config.json`.

| Profile | For | Never killed | Goes first under pressure |
|---|---|---|---|
| `engineering` | This Mac: Chrome, testing browsers, pm2 servers, local models | Agent sessions, Claude Desktop, pm2, terminals | Testing browsers, Chrome tabs, models, servers |
| `creative` | The M5 Air: design work in active use | Claude Desktop, Affinity, TouchDesigner, Music, WhatsApp | Chrome tabs |

A profile can give caps as a share of RAM (`kill_proc_pct`, `warn_proc_pct`, `swap_warn_pct`,
`grant_max_pct`), so it fits any size of Mac. `warn_protected` sends a notice when a protected
app grows past the warn cap; nothing else happens to it. `guard_only` tells `doctor` to skip the
Claude Code extras.

With every app protected and the machine truly out of memory, the guard has nothing it may
kill, and macOS's own memory handling takes over. That is the deliberate price of never
closing open work. Chrome's main process is not protected, only less likely: pressure rules
try tabs first, and it is rarely over the 1.5 GB floor.

Tests: `/usr/bin/python3 ~/.claude/scripts/zrecover/test_profiles.py`.

## Staying on across restarts

Three separate things must agree, and the first is easy to miss. The System Settings Login
Items switch overrides launchd, so a daemon can be installed and still never come back after a
reboot; that kept this guard off from 2026-10-11 to 2026-11-05. `zrecover doctor` now checks it.

1. System Settings, General, Login Items & Extensions: `gcc-zrecover` on.
2. Loaded in launchd: `zrecover daemon start`.
3. Registered with `gcc-schedule`, which is what Switchboard lists and toggles.

## Known limits

The 2026-10-10 panic was a WindowServer watchdog with the compressor at 1
percent: memory was not the cause. zrecover covers the memory and CPU
starvation routes to that panic. A GPU or driver hang is kernel-side and no
userspace kill reaches it; on this machine Steam games are the likely source.

---
brief: Provenance for rules/no-opaque-login-items.md
related:
  - rules/no-opaque-login-items.md
tier: 3
category: rules
updated: 2026-10-10
stale_after_days: 365
---
# Provenance: no opaque Login Items

## The case, 2026-10-10

The owner opened System Settings, Login Items, and found about 25 entries named `bash`, `script.sh`, `python3` and `sh`, with no way to tell what each did or what switching it off would break. A map built that day from the plists:

| Shown as | Count | What it actually was |
|---|---|---|
| script.sh | 17 | gcc-schedule timer jobs, each running `~/.claude/scheduled/<name>/script.sh` |
| bash | 6 | atone-consolidate, log-retention, svc-watch, svc-reap, no-autolaunch, claude-startup |
| python3 | 1 | the zrecover reaper daemon |
| sh | 2 | pm2 resurrect (user and root) |

Owner ruling, verbatim: "why does login items have so many opaque random entries? We need to add a rule in gcc to forbid adding such entries; I can't even turn them off because I won't know what will it break". In the same session the owner approved collapsing the timers into one scheduler entry and asked for Switchboard visibility and on/off control of every entry.

## Why the name comes from the program

Login Items (Background Task Management) labels a LaunchAgent with the executable at ProgramArguments[0], or the script file it points at. The plist Label is not shown. So a named launcher file is the only reliable way to get a readable name.

## Enforcement

Text only for now. A PreToolUse check on writes to `~/Library/LaunchAgents/*.plist` and on `gcc-schedule add` is the natural gate; it is not built, because the owner has not asked for a hook.

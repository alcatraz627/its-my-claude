---
brief: Every LaunchAgent the gcc adds must show in macOS Login Items under a name that says what it is, and must be listed and switchable in Switchboard; never an entry named bash, sh, python3 or script.sh
triggers:
  - topic:launchagent
  - topic:launchd
  - topic:login-items
  - topic:schedule
  - tool:gcc-schedule
  - phrase:"LaunchAgent"
  - phrase:"Login Items"
  - phrase:"plist"
related:
  - rules/unprompted-infra-scope-creep.md
  - rules/scheduling-discipline.md
tier: 1
category: rules
updated: 2026-10-10
stale_after_days: 120
---
# No opaque Login Items

Login Items names each entry after the program it runs, so `bash`, `sh`, `python3` or `script.sh` entries are unreadable and the owner cannot safely switch them off (owner, 2026-10-10).

Before writing or loading any plist under `~/Library/LaunchAgents`:

1. **Name the program for the job.** The first entry of ProgramArguments, the file Login Items shows, must be named for what it does, with a `gcc-` prefix for gcc jobs (`gcc-cron`, `gcc-svc`). Never a bare interpreter or a generic `script.sh`. Use a small named launcher file if the work lives in a script.
2. **Register it.** Timed jobs go in the gcc scheduler; services are adopted with `gcc-schedule register`. That registry is what Switchboard lists, so every entry can be seen, started, stopped and switched on or off from Switchboard.
3. **Prefer the shared scheduler.** A timed job joins the single gcc scheduler entry. Only an always-on service (ipc broker, i-dream, zrecover, Switchboard) earns its own entry.
4. **Ask first.** Adding any entry still needs the owner's words (`rules/unprompted-infra-scope-creep.md`).

A halt under this rule needs a genuinely missing thing, information or authority not yet granted; holding both, act (`never-halt-on-authority-you-hold.md`).

Diagnostic: a plist whose program is bash, sh, python3 or script.sh, or that no registry lists.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/no-opaque-login-items.md`

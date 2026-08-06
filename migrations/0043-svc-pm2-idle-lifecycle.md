# 0043: svc, an idle lifecycle for pm2-managed services

**Date:** 2026-08-06
**Session:** slug-ui-7c
**Status:** scripts live and exercised. The launchd jobs are written but not
loaded; that load needs the owner (see Activation).

## What changed

A new lane, `svc`, stops pm2-managed services that nobody has used for 12 hours,
and starts them again on demand. Two new files:

- `~/.claude/scripts/dev-servers/svc.sh` is the CLI.
- `~/.claude/scripts/dev-servers/svc-sample.py` is the activity sampler.

State sits beside the port ledger. `~/.claude/dev-servers/svc-state.json` holds
the current fold. `svc-events.jsonl` is the append-only record of reap, up,
down, and crashloop events, matching the ports.sh convention.

## The contract change

Migration 0029 gave tier 3 a 24h TTL with reap and revive. Tiers 1 and 2 ran
forever. That is now uniform, but keyed on a different axis.

**pm2 is the ownership boundary, not the tier.** If pm2 runs it, svc may stop
it, at any tier. A tier-1 pinned port under pm2 is in scope, because the tier
says who owns the PORT, not who owns the PROCESS. A server started by hand in a
terminal is never touched, because svc cannot see it.

Owner's framing (2026-08-06): "if I'm running something manually in a main shell
I'll close it when I'm done, this is for the background pm2 stuff that is
intended for claude's management."

## Why "idle" is not "disconnected"

The obvious test asks whether anything is connected. It fails on the exact case
that prompted this work. Vite holds an HMR websocket open to any browser tab
left open, so a forgotten tab reads as continuous use for as long as it exists.
The owner lost a week of `speedway-fe` runtime to that shape while on vacation.

So use is measured as **peer endpoints not present at the previous sample**. A
page load opens a new ephemeral source port. A parked websocket keeps the one it
has. Both directions are proven in the battery below.

## Two traps found while building

**pm2's pid is not the listening pid.** For npm-wrapped apps, pm2 tracks the
`npm run dev` shell, and the socket belongs to a grandchild. `speedway-fe` runs
as pid 1154, while node pid 1248 holds :5101. A naive check finds no port, so
the app is never reaped. The sampler walks the whole descendant tree.

**A stopped app holds no socket**, so `svc up` cannot see the port it is about
to bind. Ports are therefore remembered across a stop, seeded from pm2's own
args and env (`--port 5100`), so the pre-start squatter check is not blind.

## Verification

Every check below was run, not inspected. Both guards were mutation-tested. Each
was made to fire, then confirmed silent when it should be.

| Check | Result |
|---|---|
| Tree walk finds npm-wrapped child ports | speedway-fe → 5101, versable-playground → 5104 |
| New connection refreshes lastseen | PASS |
| Parked connection does NOT refresh lastseen | PASS (the vacation case) |
| Second connection refreshes lastseen | PASS |
| REAP fires past the 12h window | PASS (state backdated 13h) |
| Grace suppresses REAP on a fresh start | PASS |
| Port recovered from pm2 args while stopped | walmart-fe → 5100, data-forge → 5103 |
| `svc up` refuses an occupied port | PASS, app left stopped, not churning |
| Guard silent with no squatter (negative control) | PASS |

Batteries: `/tmp/svc-test.sh`, `/tmp/svc-guard-test.sh`

## The launchd PATH trap (found on first real load)

The first `launchctl load` of svc-watch exited 0, wrote empty logs, and looked
green. It had in fact destroyed the state file, replacing 1454 bytes with `{}`.

launchd gives a job a minimal PATH. pm2's shebang is `#!/usr/bin/env node`, so
neither `pm2` nor `node` resolves, `pm2 jlist` produces nothing, and the sampler
treated an unreadable response as an estate of zero apps. Every recorded
`known_ports` was lost, which is what the pre-start squatter check reads.

Three fixes, each verified by making the failure happen:

1. Both plists now set `EnvironmentVariables.PATH` to include
   `/opt/homebrew/bin`. Verified by running the job under
   `env -i PATH=<plist value>`, which now finds all 9 apps.
2. `svc-sample.py` treats unparseable pm2 output as a failure, not an empty
   estate. It leaves state untouched and exits 3. Verified by piping `not-json`
   over a seeded state file and confirming the seed survived.
3. `cmd_watch` propagates the sampler's exit code, so a failed run shows red in
   `launchctl list` rather than a silent green zero. Verified with
   `PM2_BIN=/bin/false`, which yields rc=3 and preserved state.

The general lesson: a launchd job's exit code says the wrapper ran, not that the
work happened. Any cron touching a homebrew binary needs an explicit PATH, and
any job that overwrites state needs to distinguish "read nothing" from "read
empty".

## Activation

The launchd jobs are written but not loaded. The load was correctly denied as
unattended automation, so it is the owner's call:

```
launchctl load ~/Library/LaunchAgents/com.alcatraz.svc-watch.plist   # every 5m
launchctl load ~/Library/LaunchAgents/com.alcatraz.svc-reap.plist    # hourly
```

Both jobs are registered with gcc-schedule (`schedule.sh register`) and carry
Automations calendar companions per `rules/scheduling-discipline.md`.
`schedule.sh doctor --check-calendar` reports no drift.

**Deviation, stated.** The rule says the event recurrence mirrors the cron
schedule, and gives mappings down to every-N-days. It does not cover sub-daily
intervals. svc-watch fires every 5 minutes and svc-reap hourly, so a literal
mirror would bury the calendar and destroy the observability the rule exists to
provide ("an observability backstop, not a second scheduler"). Both companions
are therefore **daily markers that state the true cadence** in the summary and
notes. log-retention is genuinely daily at 04:15, so its event is exact.

## Known gaps, stated

**kanban's crash loop is diagnosed, not fixed.** It has 22,136 restarts from
EADDRINUSE on 5106. `server.ts:130` throws and exits, but the process survives
longer than pm2's `min_uptime`, so the restart counter resets each cycle and
`max_restarts` never engages. `svc up` guards its own path, so svc cannot
trigger it, but a direct `pm2 start` still can. This sat outside the requested
scope and is left to the owner.

**Apps that hardcode a port in source** (kanban, decision-pages) get no
pre-start squatter check. The crash-loop backstop in `svc up` covers them
instead: three or more restarts with no socket appearing means stop and report.

**An app with no listening port** anywhere in its tree is classed
`no-port(skip)` and never reaped, so a future background worker cannot be killed
by mistake. Opt out explicitly via `~/.claude/dev-servers/svc-never-reap`.

## Rollback

```
launchctl unload ~/Library/LaunchAgents/com.alcatraz.svc-{watch,reap}.plist
trash ~/Library/LaunchAgents/com.alcatraz.svc-{watch,reap}.plist
trash ~/.claude/scripts/dev-servers/svc.sh ~/.claude/scripts/dev-servers/svc-sample.py
trash ~/.claude/dev-servers/svc-state.json ~/.claude/dev-servers/svc-events.jsonl
```

Nothing else reads these files, so removal is clean. pm2 apps keep running.

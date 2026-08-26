---
brief: The checklist for any run the owner leaves unattended (overnight, a sanctioned "keep going" window); every lane names its store, row filter and authority, "do not go looking" always ships with its fallback, and each agent writes its state to disk before it stops.
triggers:
  - topic:absence-run
  - topic:overnight
  - topic:unattended
  - phrase:"while I'm away"
  - phrase:"keep going overnight"
  - tool:ward-revive.sh
related:
  - skills/wake/SKILL.md
  - scripts/session-state/session-state.sh
  - warden/ward-revive.sh
  - rules/unprompted-infra-scope-creep.md
tier: 2
category: conventions
updated: 2026-08-26
stale_after_days: 120
---

# Absence-run checklist

The owner's sanctioned absences measured 83% dead: 29 windows, 91.5 hours, 76 of
them with no agent turn at all (`assets/reports/20260826-agent-failure-consolidation`).
The shape was one terminal stop per lane, not decay, and the windows with plenty of
wakes died of EMPTY turns: check-ins that restated the goal and slept. This
checklist is the protocol that came out of that measurement. It is short because
each line is something that was missing in a real run.

## Before the owner leaves: per lane

1. **Goal armed**, in the TUI (`/goal …`) or the gcc store (`goal.sh set … --by <who>`).
   No armed goal means the warden does not see the lane at all.
2. **Store named.** The lane's task store sid8 is written into its goal file
   (`"store": "<sid8>"`) or declared once with
   `session-state.sh set working --store <sid8>`. Every wake and every revive
   payload carries it; a payload without a store is the empty-wake shape.
3. **Rows agent-ready, in order.** Open `/tasks` and check that the lane's rows are
   sequenced (`blockedBy`), tiered, and that the first one needs nobody. A queue
   whose first row is owner-gated is a queue that stops in the first hour.
4. **Authority line.** One sentence in the goal saying what the lane may decide
   alone (deploy? push a feature branch? change a shared contract?). "Do not go
   looking" is only issued TOGETHER with the fallback it implies ("…take the next
   row instead", "…write blocked and stop").
5. **One walk of the owner's path per pulse.** Before any lane reports progress, one
   member walks the product the way the owner will (upload the file, see the page, read
   what it says) and reports what they saw, not what the instrument said. The 2026-08-26
   night produced 25 commits while the owner still could not get one file through the app,
   because every row came from a finding an instrument generated and none from walking
   upload-to-run as a person. Instrument findings are infinite; the walk is the test.
6. **Second-party stages kept.** What worked in the forge-v6 run stays protocol:
   cold reads by a peer before a handback, a peer's right to refuse a claim it
   cannot reproduce, `/ui-categorical-check` on any shipped surface.

6. **The routers are the first move of every lane.** A lane's first turn on a new row runs
   `/router:intake` (model the ask before acting) and, before it calls anything done,
   `/router:validate`. Owner ruling 2026-08-27 (skills-0826 D1a): the routers are the default
   path where work starts, and their invocation counts are how the prefix is judged at two weeks.

## Before the owner leaves: the institution

- Warden beat is live (`launchctl list | rg warden`) and not paused (`warden/.paused`).
- Revive armed if wanted: `touch ~/.claude/warden/.revive-armed`. It fires only on a
  ward with an armed goal, no `finished`/`blocked` state, no tool call in 20 minutes,
  and an agent-ready row it can name. Cap 3 per ward per day, then a FINDING row.
- IPC wake rung armed if wanted: `touch ~/.claude/warden/.ipc-wake-armed` (loop runs under
  pm2 as `ipc-wake`, every 15s). A `kind=request` with `--reply-by` to a session the broker
  sees idle (no heartbeat for 5 min) gets that session a headless turn naming the ask; informs
  never wake anyone; one wake per session per hour; shares the daily revive budget.
- The usage gate stands the warden AND the revive down above 90% of either window.
  A gated night logs `revive gated`; a night with no revive lines and no gated lines
  means the beat never ran. Read `warden/beat.log` first thing.

## During: what each agent writes

- On a clean stop with rows still open: do the row. The wake payload and the revive
  payload both say this; `session-state.sh set finished` refuses while a row is open.
- On a real stop: `session-state.sh set blocked|finished --reason "<why>"`. A file on
  disk is the only thing that tells a supervisor a finish from a death.
- Never an ALIVE-only turn. A turn with no tool call counts as dead to the revive.
- Ending a turn with a question for the owner IS a stop: write `session-state.sh set
  blocked --reason "USER: <the question>"` first, or the revive reads the silence as
  death and resumes you into the row you were asking about (gcc-night, 2026-08-26 13:48Z,
  revived by its own guard while waiting on the owner's tonight-or-tomorrow answer).

## What this does NOT cover, said plainly

A lane working steadily on the wrong thing is invisible to every silence-based
watcher, including the revive. The cold read and the peer refusal are the only
defences against that, which is why they are on the list above and not optional.

## Lived example

`~/Code/Versable/versable-forge-v6/docs/plan/02-overnight-v1-manual.md` is the run this
was distilled from; its three lanes, wardens and morning report are the concrete shape.

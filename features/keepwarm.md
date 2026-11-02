---
brief: How keep-warm holds an idle session's prompt cache, when it dumps, /away holds, and the gate on messages to a cold session.
triggers:
  - topic:keep-warm
  - phrase:"keepwarm"
  - phrase:"keep-warm"
  - skill:away
related: [features/usage-speedbumps.md, features/context-retention.md]
tier: 2
category: features
updated: 2026-11-02
stale_after_days: 90
---

# Keep-warm

Keep-warm holds an idle session's prompt cache warm while the owner is away, then
leaves a `/core-dump` before it stops, so they return to either a warm session or a
checkpoint. The switch is `~/.claude/.keepwarm-on`; the code is
`~/.claude/scripts/keepwarm/keepwarm.py`.

## How a fire is decided

Each session has one recurring in-session job, firing every 20 minutes on its own
minute. `next_step()` decides each fire from plain numbers. A fire with nothing to do
is blocked before the model runs: no tokens, and about 2 lines in the terminal.

```
job fires: "[keepwarm] idle check"
        │
        ├─ switch off, finished, nothing answered yet ──► blocked
        ├─ window at 100% ──► blocked; the job recovers by itself after the reset
        ├─ hibernating ─────► blocked; usage5h.py owns the pings
        ├─ account changed ─► finished
        ▼
   next_step()
        ├─ cache older than 65 min ─────────────► finished, no ping on a cold cache
        ├─ owner gone 15+ min, window won't last
        │       ├─ 95% or more ─────────────────► /core-dump mini, finished
        │       └─ otherwise ───────────────────► full /core-dump
        ├─ /away done ──────────────────────────► full /core-dump, finished
        ├─ window at 98% or more ───────────────► blocked
        ├─ cache under 40 min old ──────────────► blocked, not due
        ├─ inside an /away hold ────────────────► warm
        ├─ first ping, task list all done ──────► full /core-dump, finished
        ├─ 6 pings already ─────────────────────► full /core-dump, finished
        └─ break-even rule says yes ► warm; no ► full /core-dump, finished
```

A finished session's dump turn deletes its job. The owner's next prompt arms a new one,
and also replaces a job about to reach its 7-day expiry. A session finished without a
turn, such as on a cold cache, keeps its job firing and blocked until then.

## Making sure the job exists

A hook cannot create a job; it can only ask the model to, and the model sometimes does
not. The ~/Movies session of 2026-11-02 spent its first turn on 300 tool calls and never
did, so it pinged nothing and left no dump. Now every Stop reads `session_crons`, the job
list Claude Code hands to Stop hooks, and falls back to a real `CronCreate` call in the
transcript. If the job is missing, it blocks the turn and asks again, up to 3 times per
instruction, then logs `arm-failed`. Until a job is confirmed the statusline shows no next
ping.

This Stop hook must stay synchronous, because Claude Code discards a block from an async
hook. `keepwarm-recurring.test.py` reads the real settings file to check that.

A ping's turn is marked with `/tmp/claude-keepwarm-wake-<sid8>`, so advice gates can skip
it through `hook_should_run` (`scripts/hooks/hook-common.sh`).

`python3 ~/.claude/scripts/keepwarm/keepwarm.py plan` prints what the next fire would do
and why.

## Is another ping worth it?

    chance of return in the next hour x (catchup cost + friction) > context size

All in cached-read tokens. A `/catchup` start measures 153k (median of 60 sessions) at
the 1 hour write price, about 3M. Friction, `KEEPWARM_FRICTION`, is what avoiding one is
worth, 3M by default. A larger session has to clear a higher bar, so it dumps sooner.

**The chance** comes from `~/.claude/scripts/keepwarm/return_model.py`: a small logistic
model of time away so far and the hour on this laptop's clock, so a timezone change
carries over. The hour is a smooth curve with no hard edge. It starts from the
Copernican rule from *Algorithms to Live By* (expect to wait about as long again as you
already have) and moves only as far as the data pushes it.

Scored on each block of time by a fit on the others, across 2,304 rows from 1,616
absences (Brier score, lower is better):

| Rule | Score |
|---|---|
| This model | 0.170 |
| Copernican alone | 0.189 |
| Flat guess | 0.210 |

It refits about weekly in the background from a Stop hook, when its file is over 7 days
old, and keeps the old model unless the new fit beats Copernican.

## When the usage window will not last

Checked at every fire once the owner has been gone 15 minutes. It always wins, because
the record comes first. A mini dump carries a line saying how to build the full one.

- The 5h window is at 95% or more: mini dump.
- The pings still needed until the reset, at 0.75 of a point each across every session
  with a job, would reach 98%: full dump.
- The window is at 85% or more and its pace so far would reach 98% by the reset: full dump.
- The usage gate is closed (either window past `ops.usage_gate_pct`): full dump.

A hard `/away` hold carries on after a full dump if the window allows.

## /away

Optional, and it never stops work. A hold only takes effect once the session goes idle,
and the owner's next message clears it.

    /away 3h | 90m | 21:30 | tonight   hold warm until about then
    /away done                         finish, dump and stop
    /away soon                         default rule

Vague phrasing becomes a soft hold with `--soft`. An agent may set one itself when it
ends a turn waiting on the owner. A soft hold never replaces the owner's. A long hold
states its price once.

## The cold-session gate

Sending to a session whose cache has lapsed rewrites its whole context. The gate asks
first, in `hook_prompt`, before any API call, so asking costs nothing. AskUserQuestion
could not do this: the model has to run to ask, and that request is the rebuild.

It fires when the last answer is 60+ minutes old and the context is 100k+. It shows the
idle time, the rewrite size and the cheaper way back. The blocked text comes back in the
input box by itself, so Enter sends it; up-arrow would replace it with an older prompt.
Sending again within 10 minutes goes through; a blocked send does not count as the owner
returning. Commands that never
reach the model, such as `/clear`, pass. Mute: `touch ~/.claude/.no-cold-gate`.

## Going back to one-shots

`touch ~/.claude/.keepwarm-oneshot` restores the earlier chain of one-shot jobs and its
fixed plan (small: warm, warm, dump; large: warm, dump). Sessions on a one-shot move to
the recurring job at their next fire when the file is absent.

## Limits worth knowing

- A window that jumps from under 95% to 100% between two fires still loses its dump.
- A session hibernating for the window does not dump here; `usage5h.py` owns it.
- The cold gate cannot see the 5-minute cache of usage overage, and it estimates by
  time, so it can occasionally ask about a cache that was still warm.
- A session that goes cold with no dump falls back to `/catchup --from` on its transcript.

Tests: `python3 ~/.claude/scripts/keepwarm/keepwarm-recurring.test.py`, `keepwarm.test.py`
(one-shot mode), and `keepwarm-live.test.py` (a real Haiku session, about 6 minutes).

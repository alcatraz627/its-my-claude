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
updated: 2026-11-27
stale_after_days: 90
---

# Keep-warm

Keep-warm holds an idle session's prompt cache warm while the owner is away, then
leaves a `/core-dump` before it stops, so they return to either a warm session or a
checkpoint. The switch is `~/.claude/.keepwarm-on`; the code is
`~/.claude/scripts/keepwarm/keepwarm.py`.

## How a session waits

When a turn ends, a background process (`hook-idle`, an `asyncRewake` Stop hook) waits and
checks at least every 5 minutes. It wakes the model only when a ping or dump is really due,
and a ping lands at 52 minutes. An idle session prints nothing between pings.

This replaced a recurring job, because a job has to fire to find out it has nothing to do,
and every way of stopping a fire prints in the terminal. Checked on Claude Code 2.1.318:
`decision: block` prints the reason and the prompt whatever `suppressOutput` says, an empty
reason prints "Blocked by hook", `continue: false` prints "Operation stopped by hook", and
exit 2 prints "No stderr output". Only exit 0 from an `asyncRewake` hook is silent. A wake
shows one "Stop hook feedback" line and the one-word reply.

A new prompt does not stop a waiting process, so each one checks a token in
`keepwarm/<session>.waiter` and leaves when a newer turn has replaced it. Interrupting a turn
with Esc starts no waiter, so that session has none until its next turn ends.

Sessions started before this change keep their job until they end, because their settings
were read at start and two things must not ping one cache. They still print a line per idle
fire. `touch ~/.claude/.keepwarm-cron` puts every new session back on the job.

## What a ping asks the agent to do

A ping used to say "reply with exactly one word: warm. Start nothing else", which kept
agents idle for hours with their own next work named and undone (behaviour audit, finding
F1). Now the ping follows what the agent said it would do if no reply came. The last line
of a reply that waits on the owner, or on a job, can read:

- `If no reply: <action>`. The next ping hands the action back once: do it if it still
  applies, and end with a fresh line. Later pings are the plain one-word kind.
- `If no reply: hold, <what only the owner can give>`. The agent chose to wait for a yes;
  pings stay one word.
- No line. The ping allows, but does not force, work the reply named that waits on nothing
  from the owner.

`keepwarm.py hook-stop` reads the line with `declared_default()` and keeps it in the session
state as `declared`; a later owner turn without one clears it. The halting gate
(`scripts/hooks/named-next-work-stop.sh`) and the goal gate (`goal-proposal-stop.sh`) read the
same line through `keepwarm.py declared`, so all three agree on what was declared. Tests:
`keepwarm-declared.test.py`.

## How a check is decided

The waiter calls `next_step()` with plain numbers. The chart shows the job's wording and its
40 minute threshold; the waiter's threshold is 52 minutes, and for it "blocked" means it
keeps waiting, silently.

```
check: is anything due?
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
        ├─ 1 ping done, context near auto-compact ► full /core-dump, finished
        ├─ 6 pings already ─────────────────────► full /core-dump, finished
        └─ break-even rule says yes ► warm; no ► full /core-dump, finished
```

A finished session's dump turn deletes its job. The owner's next prompt arms a new one,
and also replaces a job about to reach its 7-day expiry. A session finished without a
turn, such as on a cold cache or by `/clear`, keeps its job firing and blocked until then.
A blocked fire is one printed line and no API call. Only the model can delete a job, and
deleting it takes a turn, so the block is the cheap way to hold it. A job outlives `/clear`
because it belongs to the process, which is how a window with no message since a `/clear`
can keep printing "finished for this absence".

Any turn that runs `/core-dump` finishes the session, whether the owner typed it as the
whole prompt or at the end of a longer message. Their next prompt starts keep-warm again.

## Making sure the job exists

This section applies only to sessions on the job. A hook cannot create a job; it can only ask the model to, and the model sometimes does
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

A session within 10 points of `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` skips this sum: one ping, then
its dump (owner, 2026-11-04). With the setting at 70, that means 600k tokens and up.

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

Tests: `python3 ~/.claude/scripts/keepwarm/keepwarm-idle.test.py` (the waiter),
`keepwarm-recurring.test.py` (the job), `keepwarm.test.py` (one-shot mode), and `keepwarm-live.test.py` (a real Haiku session, about 6 minutes).

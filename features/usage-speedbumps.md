---
brief: Every agent and subagent slows down together as the 5-hour usage window fills; near the top each main agent closes its current unit of work and hibernates in place, keeping its cache warm with cheap pings and waking itself just after the reset to carry on.
triggers:
  - tool:usage5h.py
  - topic:usage-window
  - topic:hibernate
  - phrase:"5h window"
  - phrase:"usage limit"
related:
  - features/usage-policy.md
  - features/context-retention.md
  - scripts/keepwarm/keepwarm.py
tier: 2
category: features
updated: 2026-10-22
stale_after_days: 120
---

# 5h usage speed bumps and hibernation

No agent should reach 100% of the 5-hour window by surprise. Hitting it cuts a
turn off mid-work. Here the fleet slows down together, parks at a clean line,
and picks the same session back up once the window resets. Nothing is a wall:
every bump can be passed, and spilling a little over is fine. Design notes:
`~/.claude/assets/reports/20261021-usage-speedbumps/PLAN.md`.

## The zones

`python3 ~/.claude/scripts/usage/usage5h.py status` shows the reading and every
session that is hibernating.

| Zone | From | What each agent hears (PostToolUse) |
|---|---|---|
| amber | 80% | once: its rough share (what is left below 97, split across live agents); finish in-flight work, hold new fan-out |
| red | 90% | on entry, then every 15 tool calls: arm a wake for after the reset, close the current unit of work, run `usage5h.py plan`, defer subagent-heavy work |
| brake | 96% | every 5 tool calls: stop at the next safe point |

Subagents get their own counter and a scoped line: finish the deliverable and
return. In red, an agent's first new `Agent` dispatch is bounced once with the
reason; re-issuing it goes through. Thresholds: policy keys
`ops.usage5h_amber_pct`, `ops.usage5h_red_pct`, `ops.usage5h_brake_pct`.

## Hibernating

`usage5h.py plan --work none|some` gives the steps.

- **resume** (work is left): record a note of what resumes, including deferred
  subagent work; arm the wake (`[usage-resume]`, a one-shot cron 3 minutes after
  the reset); arm a `[usage-carry]` ping every 54 minutes until the reset is
  within the hour; end the turn with one line. A context under 150k tokens gets
  the wake but no pings, since rebuilding it cold costs less than an hour of
  pings (about 0.75 of a point each, measured 2026-10-22).
- **finish** (nothing is left): close out. A large context gets a full
  `/core-dump` first (owner grant 2026-10-21).

Why ping instead of letting the cache go cold: a ping reads the cached context
(about a tenth of its price) while a cold resume rewrites all of it at the 1-hour
cache rate this account uses (about 2 times), so on API prices pinging stays
cheaper for roughly 20 hours of waiting. Measured against the window itself
(`~/.claude/logs/statusline-ratelimit.log`, 2026-10-20 to 22): keep-warm pings
reading 300k to 800k tokens often moved the 5h percentage by 0 even with other
agents working, so one ping costs under 1 point. Pings stop when the window
passes 98%, because Claude Code would refuse them.

The wake is asked for on entering red, before the agent stops, so a session
that gets cut off without hibernating still comes back.

## What brings a session back (UserPromptSubmit)

| Prompt | Goes through when |
|---|---|
| `[usage-resume]` (own wake) | the session is hibernating, or it was cut off at the limit with no record |
| Claude Code's "usage limit has reset" | the session hibernated, or was cut off mid-turn (its last answer stopped on a tool call). Not when it had closed out on its own (its last answer ended the turn, as clanky-opus did on 2026-10-21), finished, was cancelled by the owner, or a wake already ran in the last 30 minutes |
| `[usage-carry]` ping | the session is hibernating, the window is not spent, and the signed-in organization is the one it hibernated under |

Whichever resume arrives first runs; the other is skipped. A resume also re-arms
keep-warm when it is on, so the burst that follows ends warm. While a session
hibernates, a task notification, ipc message, Claude Code's own limit notes, or
any prompt the session scheduled itself (matched by the hash guard-cron-prompt
records) gets "note it and end the turn". Only a prompt the owner typed cancels
the hibernation. Policy `ops.usage5h_reset_resume`: smart (default), always, or
never.

## Keep-warm and the wake breaker

Keep-warm skips its wakes while a session hibernates (the pings do that job),
skips wakes into a spent window, and does not mistake any of these prompts for
the owner. `wake-breaker.sh` lets the identical pings through.

The prompt cache belongs to the claude.ai organization. After an account
switch, keep-warm wakes and hibernation pings are skipped before they reach the
model, because a ping would only pay the new account to rebuild a cache nobody
uses (2026-10-22: one ping rebuilt 632k cold). A switched hibernation is
cancelled, and the owner's next prompt resumes keep-warm on the new account.

Keep-warm also stops early for a session whose task list has no pending or
in-progress task: its first idle wake writes the full `/core-dump` and the chain
ends, rather than paying for warm-only wakes while it only waits on the owner.
A session with no task list keeps the usual plan.

## Taking over by hand

`/catchup --from <alias|sid>` builds a digest of a stopped session's work for a
fresh agent (`scripts/usage/resume-from.py`, no model call). Nothing starts it
automatically; it is for the owner to choose.

## Known limits

- The reading comes from the statusline's `~/.claude/widgets/.limits.json`. If
  nothing has rendered for 30 minutes, or its reset time has passed, the zone is
  `unknown` and nothing fires. Within one window a higher cached value outranks
  a session's lower reading only while a session confirmed it in the last 20
  minutes (`src_at`), so a real drop is no longer frozen out.
- Live agents are sessions with a tool call in the last 10 minutes, plus their
  subagents seen in that time.
- PostToolUse `additionalContext` does reach the subagent that made the call:
  real subagent transcripts carry it as a `hook_additional_context` attachment
  just before their next request.
- The weekly window gets the corrected reading and the existing 80/90 hint, but
  no pacing of its own yet.
- Settings load at session start: a new matcher (the Workflow bump) reaches a
  running session only after a restart. Changes to `usage5h.py` itself apply on
  the next tool call.

Mute: `touch ~/.claude/.no-usage5h`. Events: `~/.claude/usage5h/events.jsonl`.

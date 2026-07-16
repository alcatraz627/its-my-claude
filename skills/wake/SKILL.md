---
name: wake
description: Arm an opt-in wake monitor that revives THIS session if an outage leaves it alive-but-idle. A turn killed by a transient API error stops dead and waits for a human to type "keep going" — this pokes it instead. Strictly opt-in, session-only, self-deleting. Use when starting long unattended work you don't want to find stalled.
argument-hint: "[interval] (default 15m)"
user-invokable: true
disable-model-invocation: true
---

## Brief

Arms a repeating wake on **this** session. Every N minutes, while the session sits
idle, the wake asks one question: were you cut off, or are you done? If it was cut
off, it re-orients and carries on. If it's done, it says so once and deletes itself.

The point is narrow. A turn killed mid-flight by a transient API error does not
crash — it stops, and the session sits there alive and idle until a human notices
and types "keep going". That gap has cost whole evenings of unattended work.

## When to use it

Arm it before walking away from long work. Don't arm it for a short interactive
session — you're right there, and the wake has nothing to add.

**This skill never arms itself.** `disable-model-invocation: true` is what makes
that true; the owner's requirement is "no wake for sessions that never asked", and
prose alone wouldn't hold it. Only a human typing `/wake` starts one.

## Usage

```
/wake            # every 15 minutes (default)
/wake 10m        # custom interval
/wake off        # disarm now
```

## What it does NOT cover

`/wake` fires from inside the session, so it needs the session to exist. If the
Claude **process** dies — the 5h cap ending it, a crash, a closed terminal — the
cron dies with it (CronCreate jobs are in-memory and session-only). That failure is
`claudew`'s job: its `00-auto-resume` plugin runs `on_exit` and respawns.

The two are complements, not alternatives:

| failure                    | session state | who catches it                          |
| -------------------------- | ------------- | --------------------------------------- |
| turn aborts, process lives | alive, idle   | **`/wake`** (cron fires only when idle) |
| process exits              | gone          | `claudew` `00-auto-resume`              |

Neither covers the other. Running both is reasonable; running neither is what
happened on 2026-07-16, when three aborted turns each waited on a human.

## Step 0: Load shared guidelines

Read `~/.claude/skills/GUIDELINES.md` and apply it for this run. (Most projects have
no local copy — use the global one, don't scaffold one.)

## Phase 1 — Parse and check

1. **`off` / `stop` / `disarm`** → run `CronList`, `CronDelete` any wake job, confirm
   in one line, stop.
2. Parse a leading `Nm` / `Nh`; default **15m** when absent.
3. **Confirm the session actually wants this.** If the user's work is plainly
   finished, say so and don't arm — an armed wake on a finished session is pure
   noise. Ask rather than assume when it's unclear.

## Phase 2 — Arm

Convert the interval, then `CronCreate` with `recurring: true`.

**Offset the fire marks off `:00` and `:30`.** Every scheduler on the planet fires
on the hour; `CronCreate`'s own guidance is to avoid those marks when the time is
approximate, and a wake interval always is. The 15m default uses
`7,22,37,52 * * * *`. For a custom N that divides 60, offset similarly; otherwise
`*/N * * * *` is fine.

Arm it with **exactly this payload**. Do not redesign step 2 — the halt-check is
the whole reason it is safe to leave running, and it has been fired for real.

What that claim covers, precisely, because the difference matters:

- **Step 2 (the cut-off/done triage), the idle-fire, and the self-delete are
  live-validated.** Job `584b5f20`, 2026-07-16: armed at 18:33, fired on its own at
  18:39 into an idle session, correctly classified the work as finished, reported
  one line, called `CronDelete`. Evidence is in the session transcript, not a memory
  of it.
- **Step 1 (the budget check) is NOT live-validated.** The payload that actually
  fired carried a prose gesture at the budget ("if you are blocked on the 5h usage
  cap, note it and end the loop") with no script behind it. `limits-check.sh` was
  written _after_ that test and folded in here. It has 30 tests and every guard is
  mutation-pinned, but no wake has ever run step 1 for real. Treat it as
  unit-tested, not proven. (Caught by the validation gate, 2026-07-17 — the original
  wording claimed the whole payload was validated.)

```
Wake check. Two steps, in this order. Do not skip step 1.

STEP 1 — Can you afford to be awake?

Run: bash ~/.claude/scripts/wake/limits-check.sh
It prints one line and sets the exit code. Branch on the code:

  exit 1  NEAR-FULL — the 5h window is nearly spent. STOP HERE: say so in one
          line, CronDelete this job, and do nothing else. Do not keep poking a
          closing window; leave what is left for the user's real work. Re-arming
          is their call, not yours.
  exit 0  OPEN    — there is headroom. Go to step 2.
  exit 2  UNKNOWN — no usable reading. Say so in one line, then go to step 2.
          Not knowing is not permission to burn budget, but it is not a reason
          to stall either.

STEP 2 — Were you cut off, or are you done?

  CUT OFF — the previous turn died mid-task (API error, outage). Re-orient per
    rules/api-error-recovery.md: restate the goal, verify what is actually done
    (Task list, git status, files on disk), find the in-flight step, roll back
    if it is half-done. Then continue from there.

  DONE — the work is genuinely complete. Do NOT invent work to fill the wake.
    Do NOT re-explain what was already done. Report in ONE line that the wake
    fired and the halt-check held, then CronDelete this job. The user is away;
    a wake that re-animates a finished session is worse than no wake at all.
```

**Do not execute the payload now.** `/loop` tells you to run the parsed prompt
immediately rather than wait for the first fire; here that is a trap — the payload
would reach step 2, find the session mid-conversation with the user present, and
delete the job you just armed. The first real fire is the first run.

## Phase 3 — Confirm

One short confirmation: interval, fire marks, the job id, that it is session-only
and dies when Claude exits, that recurring jobs auto-expire after 7 days, and that
`/wake off` (or `CronDelete <id>`) disarms it sooner.

## Notes

### Why a percentage and not a timer

Step 1 polls how _full_ the 5h window is rather than waiting for it to reset,
because the reset time is not knowable: Claude Code sends
`resets_at="9999999999"` when it doesn't know one — the sentinel **is** the
message. There is no clock to schedule against, so `limits-check.sh` reads
`."5h".pct` from `~/.claude/widgets/.limits.json` (written by every statusline
render; the freshness merge that keeps it honest was fixed in `dcd49a5`). It
answers OPEN / NEAR-FULL / UNKNOWN, and keeps UNKNOWN separate from OPEN on purpose
— a missing reading is not evidence of headroom.

### No calendar companion, on purpose

`rules/scheduling-discipline.md` requires a companion `Automations` calendar event
for recurring jobs, `CronCreate` included, and says skipping it needs a stated
reason. This is the reason.

That rule exists because launchd and cron fail silently, and a calendar event is the
cheapest human-facing sign that an automation exists at all. Neither half applies
here. The user armed this by hand seconds ago, so nobody has forgotten it. And the
job cannot outlive the session — a calendar event mirroring it would still be there
next Tuesday, describing a job that died when the terminal closed, which is exactly
the stale-automation confusion the rule was written to prevent. A companion here
would make observability worse, not better.

If `/wake` ever grows a durable form (a launchd agent, a `/schedule` cloud
routine), that form needs a companion and this reasoning does not transfer.

### Built vs deferred

- **Built and live-fired**: the halt-check (step 2), the idle-fire, the
  self-delete. Job `584b5f20` did all of it unattended.
- **Built but never fired**: the budget backoff, step 1. `limits-check.sh` has 30
  tests and all six of its guards are individually mutation-pinned (revert any one
  and the suite goes red), but that is bench evidence. No real wake has hit a
  near-full window yet. The first one that does is the actual test.
- **Built**: opt-in, enforced by `disable-model-invocation: true` rather than prose.
- **Deferred**: _resuming_ automatically once the 5h window reopens. The spec
  (`prop-20260716-095912-38`) asks for "resume only when the condition clears", and
  that cannot be built as written — there is no reset time to wait for. `/wake`
  backs off and stops; re-arming is a human act. Closing this needs Claude Code to
  send a real `resets_at`, or a poller outside the session.
- **Not covered**: process death. See the table above.

## See also

- `rules/api-error-recovery.md` — the re-orientation ritual step 2 invokes
- `rules/scheduling-discipline.md` — the companion rule, and why it's waived here
- `features/claudew.md` — the other half: process death, not turn abort
- `scripts/wake/limits-check.sh` — the budget reading, with its own test beside it

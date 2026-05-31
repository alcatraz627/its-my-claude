---
brief: Every recurring scheduled job (launchd plist, crontab line, or harness CronCreate) MUST get a companion recurring macOS Calendar event so the human can SEE the automation exists and notice when it silently stops firing. Retiring a cron means removing its event too.
triggers:
  - topic:cron
  - topic:launchd
  - topic:scheduled-job
  - phrase:"cron"
  - phrase:"schedule a job"
  - phrase:"StartCalendarInterval"
  - phrase:"crontab"
  - tool:CronCreate
related:
  - rules/git.md
  - features/wal.md
tier: 2
category: rules
updated: 2026-05-27
stale_after_days: 365
---

# Every cron gets a companion calendar event

When creating ANY recurring scheduled job — a launchd `LaunchAgent` plist
(`StartCalendarInterval` / `StartInterval`), a `crontab` line, or a harness
`CronCreate` — **also create a recurring event in the user's macOS Calendar**
that mirrors the schedule. This is a hard step, not a nicety: the job is not
"done" until its calendar companion exists.

## Why this is a rule (the silent-failure that motivated it)

On 2026-05-27 the user discovered `com.alcatraz.philosophy-prompt-tuesday` had
**never fired once** — and they had forgotten it existed at all. A cron with no
human-facing surface is invisible twice over: you don't remember it's there, and
you can't tell when it stops working. launchd and cron fail silently by design
(a bad exit, a moved script, a login-session gap — no notification). A recurring
calendar event with an alert is the cheapest human-facing signal: it shows the
automation exists, and a missed/stale alert reveals non-firing.

The calendar event is an **observability backstop**, not a second scheduler. The
cron still does the work. The event exists so a human notices.

## What counts as "a cron" (all three need a companion)

| Mechanism | How it's created | Recognise it by |
|-----------|------------------|-----------------|
| launchd LaunchAgent | plist in `~/Library/LaunchAgents/` | `StartCalendarInterval` / `StartInterval` key |
| crontab | `crontab -e` / `crontab -` | a `* * * * * cmd` line |
| harness cron | `CronCreate` tool | the tool call itself |

## How to create the companion event

Use a dedicated calendar named `Automations` (create it once if missing) so
these events stay grouped and easy to audit. The event recurrence must mirror
the cron schedule; the notes must carry enough to find and kill the job later.

```bash
# Adds (or finds) the "Automations" calendar and a recurring event mirroring the
# cron. Adjust FREQ/INTERVAL/title/notes per job. Runs in the USER's session
# (Calendar.app needs the login GUI session + Automation permission).
osascript <<'APPLESCRIPT'
tell application "Calendar"
  if not (exists calendar "Automations") then make new calendar with properties {name:"Automations"}
  tell calendar "Automations"
    set startDate to (current date)
    set hours of startDate to 9
    set minutes of startDate to 0
    make new event with properties {
      summary:"[cron] atone-consolidate (Mon/Wed/Fri 09:00)",
      start date:startDate,
      end date:(startDate + 5 * minutes),
      description:"label: com.alcatraz.atone-consolidate" & return & ¬
        "runs: ~/.claude/scripts/atone-consolidate.sh" & return & ¬
        "plist: ~/Library/LaunchAgents/com.alcatraz.atone-consolidate.plist" & return & ¬
        "log: <path>",
      recurrence:"FREQ=WEEKLY;BYDAY=MO,WE,FR"
    }
  end tell
end tell
APPLESCRIPT
```

Map the cron schedule to the `recurrence` RRULE: daily → `FREQ=DAILY`; weekly on
a day → `FREQ=WEEKLY;BYDAY=xx`; every-N-days `StartInterval` → `FREQ=DAILY;INTERVAL=N`.
Set a calendar alert on the event if the job's firing is important to observe.

## The event notes MUST contain (so a future agent can retire it)

- the launchd **label** (or "crontab" / "CronCreate id")
- the **command/script** it runs
- the **plist path** (launchd) or the crontab line
- the **log path** if the job writes one

This mirrors the retire script (`~/mac-migration/retire-old-mac-daemons.sh`):
retiring a cron is a two-step delete — the job AND its calendar event. A
companion event with no notes is nearly as opaque as no event at all.

## Symmetry: retire the event when you retire the cron

Removing/bootout-ing a scheduled job leaves an orphan calendar event lying about
an automation that no longer runs — worse than no event, because it's actively
misleading. When you remove a cron, delete its `Automations` event in the same
change.

## What this rule does NOT require

- One-shot / `at`-style single-fire jobs don't need a recurring event (a single
  reminder is fine if the user wants it, but it's not mandatory).
- Ephemeral background tasks within a session (a `run_in_background` Bash call)
  are not crons — they die with the session and need no calendar entry.

## Diagnostic signal

You just wrote a `StartCalendarInterval` plist, a crontab line, or called
`CronCreate`, and you have NOT created an `Automations` calendar event. Stop —
the job isn't done.

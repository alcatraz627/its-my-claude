---
brief: Scheduling contract, read BEFORE creating or retiring ANY scheduled job. Every recurring cron (launchd plist / crontab / CronCreate) ALSO gets an `Automations` calendar event with label+command+plist in the notes, and retiring a cron deletes its event in the same change. Always pass --description, keep secrets out of commands, and prefer gcc-schedule for "fire shell command X at time Y".
triggers:
  - topic:scheduling
  - topic:cron
  - topic:launchd
  - topic:scheduled-job
  - phrase:schedule this
  - phrase:set up a cron
  - phrase:fire at
  - phrase:"StartCalendarInterval"
  - phrase:"crontab"
  - tool:CronCreate
  - tool:gcc-schedule
related:
  - scripts/schedule/INSTRUCTIONS.md
  - rules/never-modify-anthropic-credentials.md
paths:
  # autoload opt-out (2026-07-09 demotion pass): disclosed on demand, not always-on.
  # Only fires when creating/retiring a scheduled job, a small minority of sessions;
  # a missed calendar companion is caught later by `gcc-schedule doctor`/`inventory`.
  # The agent Reads this from rules/00-index.md when scheduling comes up. Sentinel
  # below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-07-09
stale_after_days: 365
---

# Scheduling discipline

This is the cross-tool practice for any scheduled job on this machine. It applies to `gcc-schedule`, hand-built launchd plists, `crontab`, and the harness `CronCreate` tool. The calendar-companion contract (formerly its own rule, `cron-calendar-companion.md`) lives in this file too. `scripts/schedule/INSTRUCTIONS.md` remains the gcc-schedule-specific operational contract.

## Choose the right scheduler

Three scheduling surfaces are reachable from this account, plus legacy crontab. Pick by the kind of work and not by familiarity:

| Surface | When to use | Mechanism |
|---|---|---|
| **`gcc-schedule`** (this tool) | Local shell commands that fire on a date or time and need a Calendar companion plus clean rm, inspect and audit | launchd LaunchAgent + Calendar event + registry |
| **Hand-built launchd plist** | Background services that need `KeepAlive`, `RunAtLoad=true`, restart-on-exit, or non-trivial config gcc-schedule doesn't expose | `~/Library/LaunchAgents/com.alcatraz.*.plist` directly |
| **Harness `CronCreate` / `/schedule`** | Fire a Claude prompt remotely on a schedule: agentic work, and no local commands | Anthropic-side scheduler |
| **`crontab`** | Don't, unless porting a legacy script. macOS prefers launchd, and the user crontab is empty for a reason | `crontab -e` |

If you find yourself reaching for crontab or hand-writing a plist when the job is "fire shell command X at time Y", you are in `gcc-schedule` territory.

## Harness `CronCreate` jobs are PROCESS-scoped, and duties need names

Two facts about the harness scheduler that checkpoints keep getting wrong
(provenance: duplicate warden check-ins at :23 on 2026-08-21, after a resume
re-armed a cron whose process had survived the `/clear`):

1. **Lifetime.** A `CronCreate` job lives in the harness process's memory. It
   survives `/clear` and `/compact`, dies with the PROCESS (5h cap, crash,
   closed terminal), and auto-expires after 7 days. A checkpoint can only say
   what was armed at dump time, and only an in-session `CronList` can say what is
   armed now. Never re-arm from a checkpoint claim alone: run `CronList` first,
   then re-arm only what is absent.
2. **Identity.** Job ids are per-arming and not per-duty. A recurring duty (a
   check-in, a watch, a poll) needs a stable slug so a resume or a sibling can
   ask "is this already armed?" instead of arming a duplicate.

The duty ledger `~/.claude/scripts/cron/cron-duty.sh` serves both:
`record <slug> --job <id> --schedule "<expr>"` after every recurring
`CronCreate`, `clear <slug>` alongside `CronDelete`, and `check <slug>` or
`list` for the liveness verdict (recorded harness pid plus start time; DEAD
means definitely unarmed and safe to re-arm). In-session, `CronList` stays the
ground truth, and the ledger is what other sessions and post-`/clear` resumes can
read.

## Always include `--description`

Every schedule that fires more than a few hours out (daily, weekly, one-shot N days from now) must carry a description. The description lands in the Calendar event notes and the registry's `meta.json`. Future-you, and any agent picking up the schedule via `show` or `inventory`, needs the context. Sample shapes:

- "Daily 09:00 digest of i-dream insights to ~/Documents/digests/"
- "One-shot fire to resume statusline-fix session and inspect debug log"
- "Weekly Friday 17:00: open review template; runs even on holidays"

If you are tempted to skip `--description` "because it's obvious", remember that it won't be obvious in 3 weeks when you see `[cron-once] mystery-cron: fires …` in Calendar.

## Every cron gets a companion calendar event (MANDATORY)

When creating ANY recurring scheduled job, **also create a recurring event in the user's macOS Calendar** that mirrors the schedule. This is a hard step and no courtesy: the job is not "done" until its calendar companion exists. (`gcc-schedule` does this automatically, and **passing `--no-calendar` requires a reason in the description**. Acceptable reasons are test schedules cleaned up within minutes, or a schedule whose Calendar event would itself be load-bearing. The second is rare, and it usually means the item should be a manual Reminder instead. "It's just a small thing" and "I'll add the event later" are not reasons.)

Why: on 2026-05-27 the user discovered `com.alcatraz.philosophy-prompt-tuesday` had **never fired once**, and they had forgotten it existed. launchd and cron fail silently by design, and a recurring calendar event with an alert is the cheapest human-facing signal that the automation exists and is (or isn't) firing. The event is an **observability backstop** and is no second scheduler.

All three mechanisms need a companion:

| Mechanism | Recognise it by |
|-----------|-----------------|
| launchd LaunchAgent in `~/Library/LaunchAgents/` | `StartCalendarInterval` / `StartInterval` key |
| crontab | a `* * * * * cmd` line |
| harness cron | the `CronCreate` tool call itself |

How: use a dedicated calendar named `Automations` (create it once if missing). The event recurrence mirrors the cron schedule (daily → `FREQ=DAILY`; weekly on a day → `FREQ=WEEKLY;BYDAY=xx`; every-N-days `StartInterval` → `FREQ=DAILY;INTERVAL=N`). Set an alert if the job's firing is important to observe.

```bash
# Runs in the USER's session (Calendar.app needs the login GUI session + Automation permission).
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

The event notes MUST contain the launchd **label** (or "crontab" / "CronCreate id"), the **command or script**, the **plist path** (or crontab line), and the **log path** if any, so a future agent can retire it. Retiring a cron is a two-step delete: the job AND its calendar event, in the same change. An orphan event lying about a dead automation is worse than no event.

Not required for one-shot or `at`-style single-fire jobs (a single reminder is fine but optional), or for ephemeral `run_in_background` tasks within a session (these are not crons).

## Naming

- **Kebab-case**, descriptive, no datestamps (the registry tracks creation date). Write `weekly-review` and not `weekly_review_2026`.
- **Verb-noun or noun-noun** shape preferred: `backup-pull`, `digest-morning`, `resume-statusline-fix`. Avoid bare nouns (`backup`) that don't say what direction.
- **Avoid generic suffixes.** `-job`, `-task` and `-cron` are noise, because being managed by `gcc-schedule` already implies a schedule.
- **No collisions with existing labels** in `com.alcatraz.*`. Check `gcc-schedule inventory` first if uncertain.

## Retire-after-fire (one-shots)

A one-shot schedule whose command has fired and whose plist self-unloaded is **stale** in the registry until you `rm` it. Discipline:

- After a one-shot fires, the next time you interact with `gcc-schedule`, run `gcc-schedule doctor` and clean up any reported drift via `rm`.
- If you scheduled the one-shot for "in a few days", set a follow-up reminder to retire it (a Calendar entry for the next day, or just trust the doctor habit).
- Adopted entries (via `register`) leave the external script around when you `rm`, so clean those manually if the external script is dead.

## No secrets in `--command`

The plist's `ProgramArguments` is plaintext on disk and visible via `launchctl print` to any process with the right permissions. **Never** put an API key, password or token inline:

```bash
# WRONG
gcc-schedule add --name pull --command 'curl -H "Auth: sk-abc123" …'

# RIGHT: read from keychain wrapper at fire time
gcc-schedule add --name pull --command '~/bin/pull-with-auth.sh' \
  --env AUTH_KEY_NAME=anthropic-pull-token
```

Or use `--env KEY=VAL` (also plaintext in the plist, but at least the visibility is intentional and the value lives in one place). For Anthropic credentials specifically, **never** touch them in a plist. The `guard-anthropic-credentials.sh` hook blocks the obvious writes, but plists are an untracked surface. See `rules/never-modify-anthropic-credentials.md`.

## Confirm-before-commit for ambiguous human intent

When the human says something schedulable but the spec is ambiguous (timezone unclear, day-of-week vs date unclear, "every week" vs "weekly"), use `gcc-schedule add --dry-run` to print the `PLANNED:` block, show it to the human, confirm, then re-invoke without `--dry-run`. Don't ask "do you want me to confirm?" and just dry-run.

When the spec is obviously clear ("at 3pm tomorrow" with full context), the PLANNED block prints anyway (default-on), and the user can interject if anything is off. No formal confirmation is needed.

## Test fires before relying on a schedule

For any non-trivial command that is scheduled to fire days out:

```bash
gcc-schedule run <name>   # test-fire the command immediately, no date guard, no self-unload
```

Verify it produces the intended output or side effect, then trust the schedule. This matters most when the command involves Ghostty launching, Calendar manipulation, or anything visible to other applications.

## Audit on cadence

Twice a month (or after any drift you notice):

```bash
gcc-schedule inventory          # see ALL launchd plists + crontab, classified
gcc-schedule doctor              # drift detector across registry/fs/launchd
gcc-schedule list --all          # see managed + any unmanaged com.alcatraz.*
```

If `doctor` reports drift, fix it before scheduling new work. Stale registry entries don't fire, but they pollute `show` output and clutter the picker.

## Pause vs rm

- **Pause** (`gcc-schedule pause <name>`) when you want the schedule to stop firing temporarily, for example for a vacation, a deploy freeze or debugging. It preserves the plist and script on disk, and you restore with `resume`.
- **Rm** when the schedule is done: past one-shot, retired recurring job, fired and no longer needed.
- **Don't** edit the registry JSON or the plist by hand. Go through the tool.

## When in doubt, halt and ask

If the human's intent is ambiguous in any of these ways, ask before scheduling:

- **Time or timezone** is ambiguous ("3pm": IST? UTC? wherever this machine is?)
- **Recurrence pattern** doesn't fit the three modes (`--at`, `--daily-at`, `--weekly`). Flag the gap, and offer to add a focused flag rather than reach for a complex spec.
- **Command runs as root or affects shared state.** Confirm the scope.
- **Schedule replaces an existing one** with `--force`. Confirm the intent and check whether `disable` plus `add new` is cleaner.

## Diagnostic signal

You just wrote a `StartCalendarInterval` plist, a crontab line, or called `CronCreate`, and you have NOT created an `Automations` calendar event, or you are retiring a cron without deleting its event. Stop, because the job isn't done.

## See also

- `scripts/schedule/INSTRUCTIONS.md`: the gcc-schedule operational contract (the tool-specific how-to)
- `rules/never-modify-anthropic-credentials.md`: credential hygiene
- `NAMESPACE.md` § `std::claude::schedule`: the cluster's namespace

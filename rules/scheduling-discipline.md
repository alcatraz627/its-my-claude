---
brief: Cross-tool scheduling practice — discipline that applies whether you use gcc-schedule, hand-built launchd plists, or other schedulers. Naming, retire-after-fire, secrets, calendar companion, when-to-use-which-scheduler. Distinct from INSTRUCTIONS.md which is gcc-schedule-tool-specific.
triggers:
  - topic:scheduling
  - topic:cron
  - topic:launchd
  - phrase:schedule this
  - phrase:set up a cron
  - phrase:fire at
  - tool:CronCreate
  - tool:gcc-schedule
related:
  - features/cron-calendar-companion.md
  - scripts/schedule/INSTRUCTIONS.md
tier: 1
category: rules
updated: 2026-06-01
stale_after_days: 365
---

# Scheduling discipline

Cross-tool practice for any scheduled job on this machine — applies to `gcc-schedule`, hand-built launchd plists, `crontab`, and the harness `CronCreate` tool. Pairs with `rules/cron-calendar-companion.md` (which is specifically about Calendar event companions) and `scripts/schedule/INSTRUCTIONS.md` (which is gcc-schedule-specific operational contract).

## Choose the right scheduler

Three scheduling surfaces are reachable from this account. Pick by the kind of work, not by familiarity:

| Surface | When to use | Mechanism |
|---|---|---|
| **`gcc-schedule`** (this tool) | Local shell commands that fire on a date/time and need a Calendar companion + clean rm/inspect/audit | launchd LaunchAgent + Calendar event + registry |
| **Hand-built launchd plist** | Background services that need `KeepAlive`, `RunAtLoad=true`, restart-on-exit, or non-trivial config gcc-schedule doesn't expose | `~/Library/LaunchAgents/com.alcatraz.*.plist` directly |
| **Harness `CronCreate` / `/schedule`** | Fire a Claude prompt remotely on a schedule — agentic work, not local commands | Anthropic-side scheduler |
| **`crontab`** | Don't, unless porting a legacy script. macOS prefers launchd; user crontab is empty for a reason | `crontab -e` |

If you find yourself reaching for crontab or hand-writing a plist when the job is "fire shell command X at time Y", you're in `gcc-schedule` territory.

## Always include `--description`

Every schedule that fires more than a few hours out — daily, weekly, one-shot N days from now — must carry a description. The description lands in the Calendar event notes and the registry's `meta.json`. Future-you (and any agent picking up the schedule via `show` or `inventory`) needs the context. Sample shapes:

- "Daily 09:00 digest of i-dream insights to ~/Documents/digests/"
- "One-shot fire to resume statusline-fix session and inspect debug log"
- "Weekly Friday 17:00 — open review template; runs even on holidays"

If you're tempted to skip `--description` "because it's obvious", remember: it won't be obvious in 3 weeks when you see `[cron-once] mystery-cron — fires …` in Calendar.

## Calendar companion is the default

Per `rules/cron-calendar-companion.md`, every recurring or delayed cron gets an `Automations` calendar event. The discipline rule reinforces it from the scheduler side: **passing `--no-calendar` requires a reason in the description**. Acceptable reasons:

- Test schedules being cleaned up within minutes
- Schedules whose Calendar event would itself be load-bearing (rare; usually means the schedule should be a manual Reminder instead)

Unacceptable reasons:

- "It's just a small thing"
- "I'll set up the Calendar event later"

If you can't articulate why `--no-calendar` is correct, don't pass it.

## Naming

- **Kebab-case**, descriptive, no datestamps (the registry tracks creation date). `weekly-review` not `weekly_review_2026`.
- **Verb-noun or noun-noun** shape preferred. `backup-pull`, `digest-morning`, `resume-statusline-fix`. Avoid bare nouns (`backup`) that don't say what direction.
- **Avoid generic suffixes**: `-job`, `-task`, `-cron` are noise. The fact that it's a schedule is implied by being managed by `gcc-schedule`.
- **No collisions with existing labels** in `com.alcatraz.*`. Check `gcc-schedule inventory` first if uncertain.

## Retire-after-fire (one-shots)

A one-shot schedule whose command has fired and whose plist self-unloaded is **stale** in the registry until you `rm` it. Discipline:

- After a one-shot fires, the next time you interact with `gcc-schedule`, run `gcc-schedule doctor` and clean up any reported drift via `rm`.
- If you scheduled the one-shot for "in a few days", set a follow-up reminder to retire it (a Calendar entry for the next day, or just trust the doctor habit).
- Adopted entries (via `register`) leave the external script around when you `rm` — clean those manually if the external script is dead.

## No secrets in `--command`

The plist's `ProgramArguments` is plaintext on disk and visible via `launchctl print` to any process with the right permissions. **Never** put an API key, password, or token inline:

```bash
# WRONG
gcc-schedule add --name pull --command 'curl -H "Auth: sk-abc123" …'

# RIGHT — read from keychain wrapper at fire time
gcc-schedule add --name pull --command '~/bin/pull-with-auth.sh' \
  --env AUTH_KEY_NAME=anthropic-pull-token
```

Or use `--env KEY=VAL` (also plaintext in the plist, but at least the visibility is intentional and the value lives in one place). For Anthropic credentials specifically, **never** touch them in a plist — the `guard-anthropic-credentials.sh` hook blocks the obvious writes but plists are an untracked surface. See `rules/never-modify-anthropic-credentials.md`.

## Confirm-before-commit for ambiguous human intent

When the human says something schedulable but the spec is ambiguous (timezone unclear, day-of-week vs date unclear, "every week" vs "weekly"), use `gcc-schedule add --dry-run` to print the `PLANNED:` block, show it to the human, confirm, then re-invoke without `--dry-run`. Don't ask "do you want me to confirm?" — just dry-run.

When the spec is obviously clear ("at 3pm tomorrow" with full context), the PLANNED block prints anyway (default-on); the user can interject if anything's off. No formal confirmation needed.

## Test fires before relying on a schedule

For any non-trivial command that's scheduled to fire days out:

```bash
gcc-schedule run <name>   # test-fire the command immediately, no date guard, no self-unload
```

Verify it produces the intended output / side effect. Then trust the schedule. Especially important when the command involves Ghostty launching, Calendar manipulation, or anything visible to other applications.

## Audit on cadence

Twice a month (or after any drift you notice):

```bash
gcc-schedule inventory          # see ALL launchd plists + crontab, classified
gcc-schedule doctor              # drift detector across registry/fs/launchd
gcc-schedule list --all          # see managed + any unmanaged com.alcatraz.*
```

If `doctor` reports drift, fix it before scheduling new work. Stale registry entries don't fire — but they pollute `show` output and clutter the picker.

## Pause vs rm

- **Pause** (`gcc-schedule pause <name>`) when you want the schedule to stop firing temporarily — vacation, deploy freeze, debugging. Preserves the plist + script on disk; restore with `resume`.
- **Rm** when the schedule is done. Past one-shot, retired recurring job, fired-and-no-longer-needed.
- **Don't** edit the registry JSON or the plist by hand. Go through the tool.

## When in doubt, halt and ask

If the human's intent is ambiguous in any of these ways, ask before scheduling:

- **Time / timezone** ambiguous ("3pm" — IST? UTC? wherever this machine is?)
- **Recurrence pattern** doesn't fit the three modes (`--at`, `--daily-at`, `--weekly`) — flag the gap; offer to add a focused flag rather than reach for a complex spec
- **Command runs as root or affects shared state** — confirm the scope
- **Schedule replaces an existing one** with `--force` — confirm the intent and check if `disable` + `add new` is cleaner

## See also

- `rules/cron-calendar-companion.md` — every cron gets a Calendar event (the mechanical companion rule)
- `scripts/schedule/INSTRUCTIONS.md` — gcc-schedule operational contract (the tool-specific how-to)
- `rules/never-modify-anthropic-credentials.md` — credential hygiene
- `NAMESPACE.md` § `std::claude::schedule` — the cluster's namespace

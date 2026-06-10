# gcc-schedule — usage contract for Claude

> Read this before invoking `~/.claude/scripts/schedule/schedule.sh` (alias: `gcc-schedule`). The CLI is the entrypoint; this file is the contract that makes it safe to use without trial and error.

## When to use this tool

Use `gcc-schedule` to **schedule local commands on this Mac** via launchd LaunchAgents — one-shot reminders, recurring jobs, automation. Examples:

- "Open Ghostty and resume a claude session at 3pm tomorrow"
- "Run a digest script every morning at 9"
- "Pull a backup every Sunday at 02:30"
- "Fire a Calendar alert + run a sync at the same time"

**Don't use it for:**
- Background daemons that should restart on exit (`KeepAlive`-style) — different mental model; use a hand-built plist.
- Remote scheduling (Claude API agents on a schedule) — use the `/schedule` skill / `CronCreate` harness tool instead.
- Triggering Claude prompts on a schedule — also `/schedule`, not this.

## The three scheduling modes (and why `--cron` doesn't exist)

The tool supports exactly three modes. **Pick one — they're mutually exclusive.**

| Flag | Meaning | Example |
|---|---|---|
| `--at <YYYY-MM-DDTHH:MM>` | One-shot: fire once at this local datetime, then self-unload | `--at 2026-06-02T15:00` |
| `--daily-at <HH:MM>` | Recurring: fire every day at this local time | `--daily-at 09:00` |
| `--weekly <dow> <HH:MM>` | Recurring: fire every <dow> at this local time | `--weekly fri 17:00` |

`dow` is one of `mon|tue|wed|thu|fri|sat|sun` (case-insensitive).

**Why no `--cron`?** Cron's syntax (`*/5`, `1-5`, `0 9 * * 1-5`) doesn't map cleanly to launchd's `StartCalendarInterval` (point-events) without a substantial translator. The three focused flags above cover virtually all real use cases. If you need a pattern that doesn't fit (weekdays-only, every-N-minutes, specific day-of-month), tell the human — adding a focused flag (`--weekdays-at`, `--every`, `--monthly`) is preferred over a general cron parser. `--cron` will be **rejected with a helpful error** so you can't accidentally use it.

## The PLANNED block — self-check before committing

Every `add` prints a `PLANNED:` block **before** any file is created. Read it. If anything looks wrong, abort with Ctrl-C or pass `--dry-run`.

```
PLANNED:
  name:        morning-digest
  label:       com.alcatraz.morning-digest
  kind:        daily
  fires:       DAILY at 09:00 local time (recurring; does not self-unload)
  fire_at:     daily@09:00
  workdir:     /Users/me/Documents
  env:         1 var(s):
    LOG_LEVEL=info
  calendar:    yes, recurrence: FREQ=DAILY, alert 10m before
  bootstrap:   yes (will be loaded into gui/501)
  command:    
    i-dream digest >> ~/Documents/digests/$(date +%F).md
```

If you're uncertain about how the human's intent will be parsed (timezone, DOW, env shape), **invoke with `--dry-run` first**, show the PLANNED block to the human, get confirmation, then re-invoke without `--dry-run`.

## Subcommand reference

| Subcommand | Purpose |
|---|---|
| `add` | Create a new schedule (script + plist + Calendar event + bootstrap, all atomic). |
| `list [--all]` | Show gcc-managed schedules. `--all` also shows other `com.alcatraz.*` LaunchAgents read-only. |
| `inventory` | Survey ALL launchd plists + user crontab, classified as managed/adopted/unmanaged/other. Use for audit. |
| `show <name>` | Pretty-print one schedule's full details, state, next-fire countdown. |
| `run <name>` | Test-fire the user command immediately (no date guard, no self-unload). Refuses on adopted entries (no command to run). |
| `logs <name> [--lines N] [--no-follow]` | Tail out + err logs. Default: follow with 50 prior lines. |
| `enable <name>` (alias: `resume`, `on`) | Bootstrap a plist that's been bootout'd. Idempotent. |
| `disable <name>` (alias: `pause`, `off`) | Bootout the launchd agent. Keeps files. Idempotent. |
| `duplicate <src> <new> [overrides]` (alias: `dup`, `copy`) | Copy an existing schedule with optional overrides (any `add` flag). |
| `register <plist-path>` (alias: `adopt`) | Adopt an existing user LaunchAgent (com.alcatraz.* namespace, lints clean) into the registry. |
| `rm <name>` (alias: `remove`, `retire`) | Retire fully: bootout, delete plist, delete sched_dir, delete Calendar event, unregister. Logs `removed cause=user`. For adopted entries: warns about external scripts we don't delete. |
| `history [--name N] [--outcome ...] [--ev ...] [--limit N]` | Read the append-only ledger (`history.jsonl`). Filter by name / outcome / event kind. |
| `status` | One-glance: live schedule count + all-time fire outcome tallies + recent fires. |
| `reconcile` | Sweep one-shots whose `fire_at` has passed with no run record (machine was off / launchd gap) — log `outcome=missed` and retire them. Also runs inside `doctor`. |

## Add flags (full)

```
--name <slug>            label = com.alcatraz.<slug> (required, kebab-case)
--command <shell>        the command to run, via bash -c (required)
--at | --daily-at | --weekly  pick exactly one scheduling mode (required)
--description <text>     Calendar event notes suffix
--alert <minutes>        Calendar alarm minutes before (default 10; 0 = none)
--env KEY=VAL            EnvironmentVariables plist key (repeatable)
--working-dir <abs>      WorkingDirectory plist key
--no-calendar            skip Calendar event (against cron-calendar-companion rule)
--no-bootstrap           write files but don't launchctl bootstrap
--force                  overwrite existing schedule
--dry-run                print PLANNED block + exit, NO state created
```

## Common patterns

**Open a Ghostty window + claude --resume at a specific time:**
```bash
gcc-schedule add --name resume-session-x --at 2026-06-02T15:00 \
  --command '~/.claude/scripts/schedule/launch-claude-resume.sh UUID "First-turn prompt here"' \
  --description "Resume session X to check log"
```

> **Always route a scheduled `claude --resume` through `launch-claude-resume.sh`** —
> do NOT inline `open -na Ghostty.app --args -e zsh -lc "... claude ..."`. Under
> launchd the PATH is bare and a login shell skips `~/.zshrc` (the only place
> `~/.local/bin`, where the `claude` binary lives, is added to PATH), so the
> window dies with `command not found: claude`. The helper sources the path env
> and execs claude by absolute path with permissions pre-skipped. Args:
> `launch-claude-resume.sh <session-uuid> [first-turn-prompt] [workdir]`
> (`DRYRUN=1` prints the composed command instead of opening a window).

**Daily morning digest:**
```bash
gcc-schedule add --name morning-digest --daily-at 09:00 \
  --command 'i-dream digest >> ~/Documents/digests/$(date +%F).md' \
  --env LOG_LEVEL=info --working-dir /Users/me/Documents
```

**Weekly review on Friday:**
```bash
gcc-schedule add --name weekly-review --weekly fri 17:00 \
  --command 'open ~/Documents/Reviews/template.md'
```

**Duplicate an existing schedule with a different time:**
```bash
gcc-schedule duplicate morning-digest evening-digest --daily-at 18:00
```

**Audit what's running:**
```bash
gcc-schedule inventory   # all launchd plists + crontab, classified
```

**Pause without losing the schedule (e.g., during vacation):**
```bash
gcc-schedule pause morning-digest
# ... later ...
gcc-schedule resume morning-digest
```

## What NOT to do

| Mistake | Why it's wrong | Do instead |
|---|---|---|
| Pass `--cron "0 9 * * 1-5"` | Intentionally rejected | Use `--weekly` once per day, or ask the human about adding a `--weekdays-at` flag |
| Skip `--description` for crons that fire weeks/months later | Future-you won't remember what it was for; Calendar event notes are searchable | Always include `--description` for delayed/recurring schedules |
| Use `--no-calendar` without a good reason | Breaks the `rules/cron-calendar-companion.md` rule that every cron gets a companion Calendar event for visibility | Only pass `--no-calendar` for transient test schedules |
| Edit the registry JSON directly | Bypasses gcc-schedule's atomicity — can leave plist/sched_dir/registry out of sync | Always go through `add` / `rm` / `register` |
| Run `add` to "fix" an existing schedule | `add` refuses if name exists (unless `--force`); even with `--force` you lose the Calendar event UID linkage | Use `rm` + `add`, or `disable` + edit script directly + `enable` |

## When to halt and ask the human

- **Schedule mode is ambiguous** ("schedule X every week") — clarify which day, what time.
- **Command contains secrets** (API keys, tokens) — those go via `--env` or via a wrapper script that reads from keychain; never inline in `--command`. Also note: the `guard-anthropic-credentials.sh` hook blocks Anthropic-key writes to settings.json/shell-profiles but not to plists, so you must be vigilant.
- **Schedule replaces an existing one** — confirm name + intent; `--force` is destructive.
- **Working directory doesn't exist** — gcc-schedule warns but allows; clarify whether the human wants the directory created or the schedule pointed elsewhere.

## History ledger & cleanup

The live registry holds **only active schedules** — a one-shot that fires (or a
schedule you `rm`) leaves it, so `list` never shows dead entries. Everything that
ever happened is preserved in an append-only ledger, `~/.claude/scheduled/history.jsonl`
(plain JSONL — `rg`/`jq`/Read it directly; it's never pruned).

**Two small enums + open metadata** (the shape of every ledger line):

- `ev` ∈ `added | modified | removed | run` — what the record is.
- `outcome` ∈ `ok | failed | unknown | missed` — on `run` records only — how the fire went.
- metadata (free-form, never an enum): `reason` (e.g. `claude_missing`, `ghostty_missing`, `cmd_error`, `post_handoff`, `machine_off_or_stale`), `stage` (`preflight|open|cmd|handoff`), `exit`, `detail`, `cause` (`fired-complete|user|missed-sweep`).

A new failure cause is a new `reason` **string**, not a schema change — so don't add outcome states for edge cases; add a reason.

**What counts as success vs failure** (the scheduler can only log what it observes):

- `ok` — the task launched and the launch is confirmed (headless command exited 0).
- `failed` — the scheduler tried but the launch failed: Ghostty/claude missing, bad path, command exited non-zero. This is the scheduler's fault to surface.
- `unknown` — fired and handed off (a Ghostty window opened) but the outcome past `exec` isn't observable (claude may boot, crash, or be closed). Honest, not a failure.
- `missed` — never ran at all (machine off/asleep, launchd gap). The script never executed, so it can't self-report — only `reconcile`/`doctor` detect it by the absence of a `run` line past `fire_at`.

Anything that happens *inside* the launched task (Anthropic down, subscription over, you closing the window) is **not** a schedule error — the fire already succeeded.

**Cleanup of one-time tasks** is automatic on the happy path: a fired one-shot records its `run` outcome, then self-retires (bootout + plist + sched_dir + registry key + Calendar). A **failed** one-shot is *also* retired — the failure is preserved in history as `outcome=failed`, so it leaves `list` but `status`/`history` still surface it. The only class that can't self-clean is `missed` (its script never ran); `gcc-schedule reconcile` (and every `doctor`) sweeps those. Commands a window launcher (e.g. `launch-claude-resume.sh`) can refine their own outcome by writing `key=value` lines to `$GCC_SCHED_META`.

## Where things live

```
~/.claude/scripts/schedule/schedule.sh         the tool
~/.claude/scripts/schedule/INSTRUCTIONS.md     this file
~/.claude/scheduled/registry.json              source of truth (active only)
~/.claude/scheduled/history.jsonl              append-only ledger (all events, forever)
~/.claude/scheduled/<name>/script.sh           per-schedule script
~/.claude/scheduled/<name>/meta.json           per-schedule metadata
~/Library/LaunchAgents/com.alcatraz.<name>.plist  launchd entry
~/.claude/logs/launchd/<name>.{out,err}.log    runtime output
Calendar.app "Automations" calendar            companion events
```

## See also

- `rules/cron-calendar-companion.md` — every cron gets a Calendar event
- `LOOKUP.md` § Hook Scripts — schedule.sh entry with use-case triggers
- `NAMESPACE.md` § std::claude::scripts — conceptual home

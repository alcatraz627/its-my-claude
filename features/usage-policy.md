---
brief: One reader for every usage window (policy.sh: fable, codex, general with the owner's 80/90 thresholds, advisory only), the owner-approved expiring snooze (hook-snooze.sh, scoped, reasoned, listed in the brief), and the lifecycle header the tune-able dozen carry so hook-health can say whether a hook still earns its fire.
triggers:
  - tool:policy.sh
  - tool:hook-snooze.sh
  - topic:usage-window
  - topic:snooze
  - topic:hook-lifecycle
  - phrase:"snooze this hook"
  - phrase:"quota"
related:
  - rules/model-tier-routing.md
  - features/hook-design.md
  - scripts/ledger/hook-health.sh
tier: 2
category: features
updated: 2026-09-18
stale_after_days: 120
---

# Usage policy, snooze, and hook lifecycle

Three primitives that replace the machine-wide sentinel files for the hooks
whose value depends on a judgment that can drift. Plan and evidence:
`~/Code/Claude/i-dream/.claude/output/20260918-3wk-review/hook-lifecycle-plan.md`.
Mechanical guards (chain guard, safe-delete, secret reads, credentials) use
none of this; they stay dumb by owner ruling.

## policy.sh: the thresholds, in one place

`bash ~/.claude/scripts/policy.sh fable|codex|general [--json]` prints
`TIER<TAB>detail`; exit 0 OK or UNKNOWN, 1 WARN, 2 STRONG.

| lane | above 80% | above 90% | who reads it |
|---|---|---|---|
| fable | WARN: say in the Model Plan what fable buys | STRONG: prefer not; ask the owner in one line if worth it | guard-model-tier on any fable dispatch |
| codex | WARN: weigh whether this review is worth the quota | (cron gate stands down at 75 used, unchanged) | codex-gcc at seat start |
| general | WARN: estimate big actions in one line | STRONG: name the cost, get a go; snoozable per session only | hinters/25-weekly-usage |

Every tier is advisory. The owner's words: "can still run, just advisory,
making the agent not just skip it but actually consider if there is value to
be had." A spent fable or codex quota is fine if it helped; the general window
above 90 is the pinchy one.

## hook-snooze.sh: expiring, scoped, reasoned, owner-approved

```
hook-snooze.sh add <hook|group> --for 3d --scope global|project|session --reason "…" --approved-by owner
hook-snooze.sh check <hook>      hook-snooze.sh list      hook-snooze.sh lift <id>
```

Groups: `reviews`, `fable`, `atone`, `prose`. Ledger `~/.claude/hooks/snooze.jsonl`.

**The agent never writes a snooze on its own.** It asks with AskUserQuestion,
and the option text carries all three fields, in this shape:

> Snooze `prose` (prose-smell, reply-lede, dense-shapes) for **this session**,
> **4 hours**, because you are dictating a spec in your own register and every
> reply trips the gate?  a) yes  b) global instead  c) no

On a yes it runs `add … --approved-by owner --by <sid8>`. The general-window
STRONG tier is snoozable at session scope only. A snoozed hook says so once
per session (`hook_snoozed` in hook-common.sh); the SessionStart brief lists
live snoozes with who, until and why.

## Lifecycle headers: the tune-able dozen

persona-suggest, prefer-tmp-py-over-inline, prefer-ripgrep, skill-lint-nudge,
no-task-nudge, guard-env-access, guard-speculative-export, prose-smell,
reply-lede, dense-briefing-shapes, declared-ready, guard-duplicate-symbol,
weekly-usage. Each carries:

```
# instrument: heed-writeback <check> | self (<what>) | dry-run | none-yet
# review-by: 2026-10-16
# retire-if: heed-rate < 10% over 200 fires
```

`hook-health.sh` prints them beside fires and heed rate, flags a hook past its
review-by, and marks `none-yet` as UNMEASURED. Nothing retires itself; the
owner reads the table.

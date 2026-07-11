---
brief: Never add CI workflows, git hooks, cron jobs, or other automation infrastructure the user did not explicitly request in this task — a feasibility question is not a build order
triggers:
  - topic:ci
  - topic:hooks
  - topic:automation
  - topic:cron
  - phrase:"add a workflow"
  - phrase:"git hook"
  - phrase:"pre-commit"
  - phrase:"set up CI"
related:
  - rules/communication.md
  - rules/speculative-abstractions-without-a-load-bearing-caller.md
tier: 2
category: rules
updated: 2026-07-12
stale_after_days: 120
---

# Unprompted infra scope creep — don't build automation nobody asked for

Before creating a CI workflow, git hook, cron job, LaunchAgent, pm2 service, or
registering a new tool/binary, name the user's words that requested it. If you
can't, don't build it. This is the high-cost sub-type of scope-as-ceiling
(`rules/communication.md`): ordinary scope creep wastes a diff review, but
uninvited *automation* keeps acting after the session ends — CI runs on every
push visible to collaborators, hooks fire machine-wide, registered tools become
surface the next agent extends.

## The rule

1. **A feasibility question is not a build order.** "Could we convert csv to
   xlsx?" authorizes an answer, not a registered converter. Answer first; offer
   to build second; build only on a yes.
2. **Automation gets its own approval, even mid-task.** Authorization for a code
   change does not extend to the workflow/hook/cron that would "complete" it.
   Ask in one line before wiring anything that runs unattended.
3. **Side-effects of unrequested infra count as unrequested too.** The 2026-07-10
   incident: unprompted test generation triggered an unconfirmed 24 GB download
   of a model the user had deliberately removed. The blast radius of uninvited
   automation is unbounded because nobody scoped it.

## What this rule does NOT mean

- Infra the user asked for — build it, that's the task.
- *Proposing* infra is fine and encouraged: a one-line offer, or file it via
  `bash ~/.claude/scripts/propose.sh` for the backlog. The line is between
  proposing and provisioning.
- Repo-required scaffolding named by the task (a migration the schema change
  needs) is in scope; a "while I'm here" pre-commit hook is not.

## Diagnostic signal

You are about to Write into `.github/workflows/`, `.git/hooks/`, a crontab /
LaunchAgent / pm2 config, or register a binary on PATH — and the user's request
in this task named none of these. Stop and ask.

## Provenance

Graduated from atone slug `unprompted-infra-scope-creep` (3 events, S2→S3,
trend ↑ worsening at graduation): 2026-05-15 (CI/hooks/automation added
uninvited), 2026-06-25 (csv2xlsx built + registered from a feasibility enquiry,
scope-confirm gate skipped), 2026-07-10 (unprompted test-gen triggered an
unconfirmed 24 GB model download). Weekly audit 2026-07-12, proposal #14.

## Related

- `rules/communication.md` § Scope Control — the general scope-as-ceiling principle
- `rules/speculative-abstractions-without-a-load-bearing-caller.md` — the
  in-code sibling: building for a caller that doesn't exist yet
- Atone lineage: `bash ~/.claude/scripts/atone.sh search unprompted-infra-scope-creep`

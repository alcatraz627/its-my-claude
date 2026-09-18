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
updated: 2026-09-18
stale_after_days: 120
---
# Never build automation nobody asked for

Before creating a CI workflow, git hook, cron, LaunchAgent, pm2 service, or registering a binary on PATH: name the owner's words that requested it. If you cannot, do not build it.

1. A feasibility question is not a build order. Answer first, offer second, build on a yes.
2. Automation gets its own approval, even mid-task; authorization for a code change does not extend to the workflow that would "complete" it.
3. Side effects of unrequested infra are unrequested too (a generated test once pulled a 24 GB model download).

Proposing is fine (one line, or `propose.sh`). When the deferred infra is the ENFORCEMENT of a ban you are recording, say so in the same reply: "recorded, advisory-only until the gate is built; want the gate now?" Repo-required scaffolding named by the task is in scope.

Diagnostic: about to write into `.github/workflows/`, `.git/hooks/`, a crontab, LaunchAgent or pm2 config, and the task named none of them.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/unprompted-infra-scope-creep.md`

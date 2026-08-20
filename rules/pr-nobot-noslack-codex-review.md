---
brief: Every PR the agent raises carries [nobot] [noslack] in its title to silence the pr-claude bot and the Slack mirror; review the branch locally with a cheap codex seat before opening it, and paste that verdict as the PR's agent comment
triggers:
  - phrase:"open a PR"
  - phrase:"pull request"
  - phrase:"gh pr create"
  - topic:pr
  - topic:code-review
  - tool:gh
related:
  - rules/read-the-comments-on-a-pr-you-raised.md
  - rules/git.md
tier: 2
category: rules
updated: 2026-08-20
stale_after_days: 180
---

# Agent-raised PRs: [nobot] [noslack] in the title, codex review locally

Owner ruling 2026-08-20, durable: bot and Slack noise from agent-raised PRs
costs real money and attention (the pr workflow burned 628 Actions minutes in
August 2026 and the org hit its spending cap), and an agent can buy the same
review locally for near nothing.

## The rule

1. **Every `gh pr create` the agent runs puts `[nobot] [noslack]` in the
   title.** No exceptions for "important" PRs; the owner strips the tags
   themselves when they want the machinery.
2. **Before opening the PR, run a cheap local review** with a codex seat (the
   `codex:codex-rescue` agent type, or the local `codex` CLI over the branch
   diff). The seat reads the full diff against the base and returns findings
   with file:line.
3. **Act on the findings first**, then open the PR and post the verdict as an
   agent comment (the ci-kit `agent-comment.cjs` shape where the repo has it,
   a plain comment elsewhere), so the review is on the record where the bot's
   would have been.
4. `read-the-comments-on-a-pr-you-raised.md` still binds for comments humans
   or bots leave anyway; the tags remove the default noise, not the duty to
   answer what lands.

## Diagnostic signal

You are typing `gh pr create` and the title has no `[nobot]`, or no local
review ran on the branch. Stop; review, tag, then open.

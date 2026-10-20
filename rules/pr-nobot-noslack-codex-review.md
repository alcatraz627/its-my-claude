---
brief: The [nobot] [noslack] PR title tags are a per-repo call (a repo's own rule wins; otherwise [noslack] on working PRs, [nobot] when a bot review would not help); review the branch locally with a cheap codex seat before opening it, and paste that verdict as the PR's agent comment
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
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; binds at `gh pr create`; a creation-moment nudge hook is proposed in the backlog.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-10-21
stale_after_days: 180
---

# Agent-raised PRs: [nobot] [noslack] in the title, codex review locally

Owner ruling 2026-08-20, durable: bot and Slack noise from agent-raised PRs
costs real money and attention (the pr workflow burned 628 Actions minutes in
August 2026 and the org hit its spending cap), and an agent can buy the same
review locally for near nothing.

## The rule

1. **The tags are a per-repo call** (owner, 2026-10-21). A repo whose own
   rules name the tags follows them: slack-automation's PRs carry both, because
   its volume would crowd out the PRs elsewhere that need the rich review. In
   a repo with no stated rule, `[noslack]` goes on an agent's working PR, and
   `[nobot]` goes on when the PR would not gain from a bot review (a mechanical
   change, a docs tidy, a chain of small PRs). A PR that would gain from one
   goes without `[nobot]`. The owner strips or adds tags when they disagree.
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

You are typing `gh pr create` without having checked the repo's own tag rule,
or no local review ran on the branch. Stop; review, decide the tags, then open.

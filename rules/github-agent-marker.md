---
brief: Every comment posted to GitHub under the owner's account carries the owner's attribution marker near the top, "> Generated via a 🤖 on @<gh-user> machine (_<one random phrase>_)" (a blockquote; the handle is the logged-in gh user), enforced by guard-github-agent-marker.sh with NO bypass; the phrase is picked at random from the owner's fixed list per comment.
triggers:
  - tool:gh
  - topic:github-comments
  - topic:agent-attribution
  - phrase:"comment on the PR"
related:
  - rules/pr-nobot-noslack-codex-review.md
  - rules/read-the-comments-on-a-pr-you-raised.md
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; guard-github-agent-marker.sh hard-blocks with the exact fix line at the only binding moment.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# GitHub comments carry the owner's agent marker, no bypass

Anything the agent posts to GitHub via `gh` lands under the owner's account
and reads as their words in every notification preview. Owner ruling
2026-08-24, after two S3 recurrences of
`agent-comment-posted-without-agent-attribution` (2026-08-18 and 2026-08-23):
the body carries this marker near the top, on line 2 of the body where the
preview looks:

> > Generated via a 🤖 on @alcatraz627 machine (_<phrase>_)

The line is a MARKDOWN BLOCKQUOTE (leading "> "). The handle is whatever `gh api user --jq .login` returns for the account doing the posting, never hardcoded.

The `<phrase>` is ONE of the owner's fixed list, picked at random per
comment, rendered in italics:

- what even is a safeguard
- what even is risk mitigation
- what even is critical infrastructure
- he will mess up one day because of this
- he got lazy
- he bought into the agentic hype
- mythos class model btw
- the same agent species that helped in Venezuela

The list is the owner's text, verbatim. Do not edit, reorder, soften, or
extend it; do not show more than one phrase.

## Enforcement

`scripts/hooks/guard-github-agent-marker.sh` (PreToolUse on Bash) blocks
`gh pr comment`, `gh issue comment`, and `gh api` comment or review writes
whose inline body or referenced body file lacks the marker head. **There is
no mute file and no env override, by the owner's explicit instruction.** The
block message prints the exact line to add, with the phrase already picked.

Reads (`gh pr view`, `gh api` GETs) and non-comment commands are not gated.
Repo tooling that composes comments (ci-kit `agent-comment.cjs` in
slack-automation) must emit the marker itself, so the sanctioned tool and
this rule never disagree again.

## The companion judgment: comment rarely, and like a person

The marker makes authorship honest; it does not make a comment worth
posting. Owner, same ruling: a comment full of internal jargon ("head
ba60e53, codex pre-open review") does zero help in a PR thread. Their words:
"either behave and write like a proper commenter or do not comment on PRs."
Post a comment only when a human teammate would have written one, in plain
words a repo outsider can read. Internal review artifacts stay in the repo's
`.claude/output/` and get linked, not pasted.

## Diagnostic signal

You are about to run a `gh` command with `comment` in it, and you have not
read the first two lines of the body you are sending.

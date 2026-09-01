---
brief: A PR you opened is not done when it is pushed. Poll its comments at 5s then 30s, and for every review finding either fix it or argue it with `/claude-bot ask (via 🤖claude)`. Loop until the bot concedes or you can show it is wrong, and file a GitHub issue against the PR when it is. Never report done over open findings.
triggers:
  - topic:pull-request
  - topic:pr-review
  - phrase:"opened a PR"
  - phrase:"raised a PR"
  - phrase:"PR is up"
  - phrase:"ready for review"
  - phrase:"PR is done"
  - tool:gh
related:
  - rules/git.md
  - rules/exercise-based-verification.md
  - rules/structural-claim-without-reading-code.md
  - rules/pushback-and-self-criticism.md
tier: 1
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Read the comments on a PR you raised, and answer every one

Opening a PR is not the end of the task. In every repo joined to `pr-claude`, a
review bot reads the diff and posts findings within a few minutes, and a human
may comment at any time after. Nothing interrupts you when either lands. A PR
reported as done over unanswered findings is the failure this rule exists to
stop, and it happens because the agent stopped looking, not because it
disagreed.

## The loop

Every PR you raise, without exception:

1. **Poll at 5 seconds, then at 30 seconds.** The first catches the status
   comment the bot claims immediately, the second catches a fast review. A full
   review usually takes minutes, so keep checking until the run settles rather
   than stopping after two polls.

   ```bash
   gh pr view <n> --json comments --jq '.comments[] | "=== \(.author.login) @ \(.createdAt)\n\(.body)"'
   gh pr checks <n>
   ```

2. **Parse every comment added so far**, not only the newest. The review posts
   into one sticky comment and rewrites it, so an earlier round can be gone
   while a human reply to it remains. Read the humans' comments too.

3. **For each finding, do exactly one of two things.**
   - **Fix the code**, push, and let the next round judge it.
   - **Argue it**, in the PR, using the ask verb so the exchange is on the
     record:

     ```
     /claude-bot ask (via 🤖claude) <your case>
     ```

     The `(via 🤖claude)` marker is not decoration. `gh` authenticates as the
     human's account, so without it your words read as theirs. On a command
     comment the marker goes on line 2 or below, never line 1, because
     pr-board parses the command from the first line only.

4. **Loop until one of these is true.**
   - The bot concedes, or its next round comes back clean.
   - You can *show* it is wrong. Not believe: show. Name the file and line that
     disproves the finding, the way you would have to if a person had raised it.

5. **When it is genuinely wrong, file a GitHub issue and link the PR.** A wrong
   finding is a defect in the reviewer, and an argument that ends in the PR
   thread teaches it nothing. Use `/file-gh-issue`, which is dry-run by default
   and gated on your approval before it files.

## Confidence decays across rounds, and the check before "ready" is mechanical

A finding you argued away that comes back in the next round is evidence your argument
missed, not evidence the reviewer is stubborn. Arguing the same finding across rounds
without NEW evidence is the PR-thread costume of [[literal-request-over-intent]] shape
7 (a repeated ask means the last answer missed). Second round: find what you did not
show. Third round on the same finding: fix it or file the issue; do not argue again.

And the runnable check, from RCA `mist-20260826-083406-6f` (this rule existed and did
not bind): before telling the owner a PR is ready, done, or theirs to merge, run
`gh pr view <n> --repo <repo> --json comments --jq '.comments[].body'` and read it. If
any review finding is unanswered, the PR is not ready and the sentence you were about
to write is false.

## Never do this

- Report a PR as done, ask for a merge, or move to the next task while a finding
  sits unanswered. This is the specific failure: a session raised a PR on
  2026-08-18 and called it done while the bot was still calling out issues.
- Answer by silence. A finding nobody read is worth less than no review, because
  the review's cost was paid and its value was not.
- Push a fix and walk away. Pushing re-triggers the review, and the new round is
  computed against the new head, so the old findings may be replaced by
  different ones.
- Argue without evidence. "I think this is fine" is not a case. The bot argues
  from files and lines and you are held to the same bar.

## What this is not

Not a bot-chase on a PR the bot will never review: under a `[nobot] [noslack]`
title (`rules/pr-nobot-noslack-codex-review.md`, every agent-raised PR) the
review bot is silenced, so the loop covers human comments and the local codex
verdict, and "until the bot concedes" is vacuous there. Not a poll loop that blocks your session. Check when the run has plausibly
finished, and again after each push. Not a mandate to obey every finding
either: a wrong finding gets a sentence saying why, which is itself the answer,
and then an issue so it gets fixed at the source.

## Provenance

Owner, 2026-08-18, on PR #25 in `slack-automation`: "Check comments on PR #25,
add to your rules to always do that for every PR you raise." The bot had posted
three findings hours earlier, two of them documentation this same PR had made
wrong, and the session that opened the PR never looked.

Extended by the owner, 2026-08-19, after a session raised a PR and called it
done while the review was calling out issues: poll at 5s then 30s, argue via
`/claude-bot ask (via 🤖claude)` or fix, loop until it concedes, and file a
GitHub issue when it is really wrong.

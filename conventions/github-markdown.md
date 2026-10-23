---
brief: GitHub rendering and Actions behaviours that cost real rounds - callouts in details, branch links, reference links, conflicting PRs, stacked squash merges, edited events
triggers:
  - topic:github-markdown
  - topic:github-actions
  - topic:pr-description
  - phrase:"does not render"
related:
  - conventions/html-output.md
  - rules/git.md
tier: 2
category: conventions
updated: 2026-10-24
stale_after_days: 180
---

# GitHub markdown and Actions: what actually happens

Six behaviours measured on versable-git/slack-automation #267 (2026-09-28/29). Each one cost a round before anyone knew it.

| What happens | How it showed | What to do |
|---|---|---|
| A GFM callout (`> [!NOTE]`) inside `<details>` renders as a plain quote | The callout box vanished in a collapsed section | Inside `<details>`, use a bold line and a list instead of a callout |
| A link to a file on the PR branch that targets `main` 404s until merge | Reviewers clicked dead links in the PR body | Link to the head sha (`/blob/<sha>/path`) for files the PR adds or moves |
| A long table with inline links balloons the body | A 50-row table was 39k characters | Define reference links once at the foot (`[r1]: url`); the same table fell to 24k |
| GitHub runs no `pull_request` workflows while a PR is conflicting | A push into a conflicting PR produced no runs at all, not even failures | Resolve the conflict first; silence on a conflicting PR is not a pass |
| A squash merge orphans a branch stacked on the merged one | The stacked PR showed the base's commits again and would not merge cleanly | Rebuild the stacked branch from `main` and cherry-pick its own commits |
| The `edited` event fires when a bot edits the description, and a push cancels an in-flight Claude-action run | A workflow re-fired on its sibling bot's write; a review run was cancelled mid-way by a fixup push | Filter `edited` by actor or changed field; let a review run finish before pushing |

---
name: pr-description
description: >
  Write a PR description that briefs the reviewer in the author's voice:
  content-model-first. Extracts the behavioral inventory from the ACTUAL diff
  (never commit subjects), presents it for a pick, and only then drafts,
  leading every section with what a user can now do or what stops going
  wrong. Carries the deploy-visible effects no hunk shows, the one design
  decision a reviewer must ratify, and an honest verification boundary.
  Output is a file the human pastes; never runs gh pr create or gh pr edit.
  Use for "write the PR description", "PR body", "describe this PR".
user-invokable: true
argument-hint: "[PR number | base..head | branch]"
allowed-tools: Read, Glob, Grep, Bash, Write
---

## Brief

A PR description is the author's briefing to their reviewer, published under
the USER's name. The diff is evidence, never the headline; the description's
whole value is what the diff cannot say: behavior changes, the design
tradeoff, deploy effects that live in data rather than hunks, and what was
NOT verified. The skill's law, graduated from a six-draft failure
(adversarial verdict, enhancement-product 2026-08-13): extract and present
the content BEFORE writing prose, and A SECOND REJECTION BUYS A QUESTION,
NOT A DRAFT.

## Usage

```
/pr-description 274            # a PR number
/pr-description main..feature  # an explicit range
/pr-description                # current branch vs the default base
```

## Step 0: Load Shared Guidelines and Runtime Context

Read the shared guidelines: `<project>/.claude/skills/GUIDELINES.md` if the
project has one, otherwise the global default `~/.claude/skills/GUIDELINES.md`
(most projects have no local copy; use the global one and say so in one line,
never skip the rules). Apply forbidden paths, retry logic, tool preferences,
verbosity, timeouts, post-run insights, and the file lock protocol for the
whole run. Also read `.claude/skills/runtime-notes.md` for past run history.

## Phase 1: Evidence (read, never trust)

1. **Resolve refs.** PR number: `gh pr view <N> --json
title,baseRefName,headRefName,changedFiles,additions,deletions,body,url`.
   Fetch both refs; the diff is always three-dot
   (`git diff origin/<base>...origin/<head>`, merge-base not two-dot).
2. **Calibrate on the accepted corpus FIRST.** Read the descriptions of 2-3
   MERGED PRs from this repo (`gh pr list --state merged --limit 5`). Their
   voice, density, and structure are the target. This corpus outranks every
   linter: on the incident that produced this skill, a draft the user
   rejected scored 0.20 on prose-lint while the repo's own merged PR scored
   6.05. Prose-lint is advisory here; never chase its score.
3. **Read the ACTUAL diff, not commit subjects.** Subjects lie in catalogued
   ways (reverts that read as regressions, "removed" gates that actually
   moved, vague subjects hiding user-facing features): anything above ~40
   changed lines or with an ambiguous subject gets its hunks read.
4. **Hunt the diff-invisible content deliberately.** This is the highest
   value in the document:
   - Data-dependent deploy effects: behavior that changes because of what is
     IN production tables (a repricing that lives in a config row, a default
     that flips for teams with partial data). Where an enumeration query can
     find who is affected, capture the query.
   - The design decision: the one call a reviewer must ratify, with its
     tradeoff and the alternative not taken.
   - The verification boundary: what ran, what cannot run, which bug was
     live vs latent.

## Phase 2: The inventory gate (present, then STOP)

Extract the behavioral inventory, grouped by feature domain (never by file
or commit): what a user can now do, what stops going wrong, what changes for
existing customers on deploy, the design decision, the verification state.

**Present it as a numbered list and STOP for the pick.** Drafting is
contingent on the pick; skipping this gate is the root failure the skill
exists to prevent. If the inventory is empty, say exactly that and stop:
"no behavioral effect found" is a complete, correct answer.

Two shapes the plain list mishandles (both from the first validation run,
a 44-file PR that produced 19 items across 7 domains):

- **Large inventories get triage, not a dump.** Past ~8 items, rank by the
  axis the PR itself weights (billing, user impact, deploy risk) and mark a
  suggested default set, so the pick is a confirm-or-amend rather than an
  N-way sort the user must do.
- **Split before the pick: describe / fix-first / drop.** Some items are
  defects, not content. A claim in the PR's own docs or comments that is
  false as written belongs in a commit, never in the body in any form.
  Route those to a fix-first list presented beside the inventory, so the
  call is a step in the skill, not a judgment left to whoever notices.

## Phase 3: Draft (only after the pick)

Voice: the author briefing their reviewer, at the accepted corpus's density.
Scale to the PR: a two-file fix gets a few paragraphs, never ceremony.

Sections, kept only when they have content:

- **Lead:** the problem in behavior terms, then what changes. No throat-
  clearing.
- **The design decision:** the tradeoff paragraph a reviewer must ratify,
  with the alternative not taken and what the choice costs.
- **Before merging, please read:** deploy-visible changes for existing
  customers (pricing, defaults, migrations, data-dependent effects). State
  facts; never assign the author homework in their own document (decision
  menus like "someone should choose between X, Y, Z" belong in chat, to the
  user). An enumeration query goes in the test plan as a run-against-prod
  item, not in prose.
- **Fixed along the way:** secondary fixes, each in behavior terms.
- **Test plan:** concrete behavioral checks a reviewer can perform.
- **Verification:** honest prose stating what ran AND what did not.
  Repo-fact caveats STAY ("these seven tests cannot load under vitest, a
  pre-existing blocker"): they serve any reviewer. Agent-process caveats GO
  TO CHAT ("I did not check production"): in the document they spend the
  user's credibility. This distinction, not "caveats out".

Hard bans: no fabricated specifics (dev-database rows are not production
customers); no em-dashes (owner budget zero, the prose gate blocks them);
no Claude or harness trailers; UX-justification essays for form controls
stay out of billing PRs.

**Output:** write to
`<repo>/.claude/output/<YYYYMMDD>-pr-description/pr-<N>.md` and hand the
absolute path to the user. NEVER run `gh pr create` or `gh pr edit`; the
human pastes.

## Phase 4: The revision law

1. **Before ANY revision, re-read the founding request and the picked
   inventory.** Every redraft is checked against that reference, not only
   the latest objection: feedback on the last error with no reference signal
   oscillates, and six drafts proved it.
2. **A second rejection buys a question, not a draft.** On rejection #2,
   stop and ask one precise question about the gap (offer 2-3 readings if
   that helps). No third draft before the answer.
3. **Deletion is not a fix.** When a sentence is called wrong, fix the
   claim. Cutting it is how load-bearing content (the design decision, a
   repo-fact caveat) leaks out across drafts.

## Completion

Close with the GUIDELINES 🏁 done box: the output file as a `▸` ref, the
arrow line carrying what the user does next (read the inventory pick, or
paste the body). Then post-run insights per GUIDELINES §7, especially any
new commit-subject trap or diff-invisible content class discovered.

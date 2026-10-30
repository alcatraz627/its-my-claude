---
name: pr-description
description: Writes a PR description from the actual diff. Presents a behavioral inventory for the user to pick from before any prose, then drafts the body to paste. Not for commit messages or code review.
---

# PR description

A PR description is the author's briefing to their reviewer, published under
the user's name. The diff is evidence, never the headline. The description's
value is what the diff cannot say: behavior changes, the design tradeoff,
deploy effects that live in data rather than code, and what was not verified.

Two rules carry the skill. Extract and present the content before writing any
prose. And a second rejection buys a question, not another draft.

## 1. Gather evidence

**Get the diff.** Pasted, uploaded, or fetched through a GitHub connector by
PR number or branch. The diff is base to head from the merge base. If the user
pastes `git log` output only, ask for the diff, because commit subjects lie in
known ways: a revert that reads as a regression, a gate described as removed
that moved, a vague subject hiding a user-facing feature. Read the hunks for
anything over about 40 lines or with an unclear subject.

**Calibrate on merged PRs.** With a connector, read the bodies of two or three
merged PRs from the same repo. Otherwise ask the user to paste one. Their
voice, density and structure are the target, and they outrank any style rule
here.

**Let the counts come from the source.** File counts, line totals and file
lists come from the PR metadata or a command run on the diff in the sandbox,
not from your reading. Every fact you assert by hand is one you can get wrong.

**Hunt what the diff cannot show.**

- **Deploy effects that live in data.** Behavior that changes because of what
  is in production: a price held in a config row, a default that flips for
  accounts with partial data. Where a query could list who is affected, write
  it down.
- **The design decision.** The one call a reviewer must ratify, with its
  tradeoff and the alternative not taken.
- **The verification boundary.** What ran, what could not run, which bug was
  live and which was latent.
- **Contradictions across files.** Read the docs, tests and comments the PR
  touches against its code. A doc describing different behavior than the code
  it ships with, or a passing test that exercises a helper the code no longer
  calls, is a real finding no single hunk shows.

## 2. The inventory, then stop

Extract the behavioral inventory, grouped by feature area, never by file or
commit: what a user can now do, what stops going wrong, what changes for
existing users on deploy, the design decision, the verification state.

Present it as a numbered list and stop for the user's pick. Drafting waits on
the pick. Skipping this step is the failure the skill exists to prevent.

- **Past about eight items, triage.** Rank by what the PR itself weights
  (billing, user impact, deploy risk) and mark a suggested default set, so the
  pick is confirm or amend.
- **Split before the pick: describe, fix first, drop.** A claim in the PR's own
  docs or comments that is false as written belongs in a commit, never in the
  body. List those beside the inventory as fix-first items.

Three answers are valid, and each has a path:

1. **A pick**, or a confirm of the default set. Draft.
2. **An empty inventory.** Say "no behavioral effect found" and stop. That is
   a complete answer.
3. **Right content, wrong wording.** Content is now frozen. Reword the
   inventory without adding, dropping or merging any item, then present it
   again for an explicit pick. If rewording surfaces a content problem, say so
   rather than fixing it quietly.

## 3. Draft

Voice: the author briefing the reviewer, at the merged corpus's density. A
two-file fix gets a few paragraphs, never ceremony.

Four kinds of PR change the reader, so they change the shape:

- **Release.** The reader decides whether to ship. Lead with scope, group
  user-visible effects by product area, and let deploy risk outrank the rest.
- **Hotfix.** The symptom stopped, the blast radius, the shortcut taken and
  what the proper fix would be. Brief.
- **Merge or conflict resolution.** One lead and one behavior sentence is
  often the whole body. Name the files where the resolution made a choice.
- **Revert.** What behavior returns, why, and what regression returns with it.

Judge the kind from the title, the base branch and the diff together. Never
derive behavior from a branch name.

Sections, kept only when they have content:

- **Lead:** the problem in behavior terms, then what changes.
- **Design decision:** the tradeoff, the alternative not taken, its cost.
- **Before merging:** deploy-visible effects for existing users: pricing,
  defaults, migrations, data-dependent changes. State facts. Decision menus
  ("someone should choose X or Y") go to the user in chat, not into the body.
- **Fixed along the way:** secondary fixes in behavior terms.
- **Test plan:** checks a reviewer can perform. An affected-users query goes
  here as an item to run against production.
- **Verification:** what ran and what did not. Facts about the repo stay
  ("these seven tests cannot load under vitest, a known blocker"). Notes about
  your own process ("I did not check production") go in chat, because in the
  body they spend the user's credibility.

**Blocking rules.** No invented specifics: a number you did not compute does
not appear, and test data is not production customers. No em-dashes. No
assistant or tool trailers. No homework for the author in their own document.

**Advisory.** Density, section balance, register. These improve a draft and
never discard one. The merged corpus outranks any of them.

Hand the body over in a single fenced markdown block, ready to paste. Never
create or edit the PR through a connector unless the user asks for that in so
many words.

## 4. Revising

1. Before any revision, re-read the original request and the picked
   inventory. Check the redraft against both, not only the latest objection.
   Feedback on the last error with no fixed reference oscillates.
2. A second rejection buys one precise question about the gap, with two or
   three readings if that helps. No third draft before the answer.
3. Deletion is not a fix. When a sentence is wrong, fix the claim. Cutting is
   how the design decision and the repo caveats leak out across drafts.
4. Keep the previous draft in the conversation, labeled, so a later revision
   can recover what an earlier one got right.
5. Wording rejections count separately from content rejections, on the same
   rule: the second one buys a question.

When the body or the inventory needs a plain-language pass, `plain-writing`
covers that.

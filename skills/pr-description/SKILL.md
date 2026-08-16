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

The gate takes three answers, not one: a pick, an empty inventory, or
accepted-on-substance-rejected-on-register. The third routes through an
optional register branch (Phase 2) and comes back for an explicit pick. Prose
rules run in two tiers, and no linter may ever discard a draft.

CI variant: `slack-automation/ci-kit/skills/pr-body/SKILL.md` adapts this
skill for unattended runs (self-picked inventory default set, owner decision
2026-08-14; lint stays advisory there too). It cites this file's rulings;
change either spec only after checking the other.

**The register branch does NOT transfer to CI** (checked 2026-08-15). It is
triggered by a human rejecting an inventory's wording, and the CI run has no
human at draft time, so the branch would have nobody to fire it. The traffic
went the other way instead: the two-tier prose rules, kept-previous, the
archetypes, cross-artifact contradiction hunting, and the machine-owns-the-facts
split below were all learned FROM the CI variant and its operator. What this
file keeps that CI cannot have is the human pick, which their operator called
"the single most valuable thing you have; we amputated it out of necessity, not
preference".

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
   - **Cross-artifact contradiction.** Read the docs, tests, and comments
     the PR touches AGAINST its code. A doc that describes different
     behavior than the code it ships with, a comment the code contradicts,
     a still-passing test that exercises a helper the write path no longer
     calls: each is a real finding no hunk shows on its own. Two live
     catches from the CI reviewer (2026-08-14): a cron authenticating
     against a different secret than its own new doc, and exactly that
     stale-test case. Route a false claim to fix-first (Phase 2), never
     into the body.
5. **Let the machine own every fact it can.** Counts, file lists, commit
   classification, size, and the changed-file census come from commands, not
   from your reading of the diff. Compose those first and treat them as a
   ledger you do not restate or contradict. Then write only what a command
   cannot produce: behavior, tradeoff, risk. This split is why the CI variant
   fabricates little, and the reason generalizes: every fact you assert by
   hand is a fact you can get wrong.

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

### The three responses this gate must handle

A pick is not the only valid answer. Model all three, because an unmodeled
response gets improvised, and the likeliest improvisation is to read it as a
pick and draft anyway, which is the exact failure this gate exists to prevent.

1. **A pick** (including a confirm of the suggested default set). Go to Phase 3.
2. **An empty inventory.** Say "no behavioral effect found" and stop. Complete
   and correct.
3. **Accepted on substance, rejected on register.** The content is right and
   the WORDING is not: "this diff read is good, just simplify the language".
   Take the register branch below, then come back here for an explicit pick.

Response 3 is a real observed case, not a hypothetical (PR #274, 2026-08-14,
owner rejecting an inventory's register with content explicitly frozen).

### The register branch

**Content is frozen.** This branch changes wording only. It may not add, drop,
merge, or re-scope a single inventory item. If a register pass surfaces a
content problem, stop and say so; do not fix it silently under cover of a
wording pass.

Two independent optional components. The user may take either, both, or
neither, because they solve different problems:

| Component | What it does | Why it exists |
|---|---|---|
| **feedback** | a mechanical register pass, `/ste-writing` flavored mode | fixes wording, density, sentence shape |
| **reviewer** | a fresh reader that did not write the text (sub-agent, or `personas/doc-writer.md`) | `rules/audience-aware-writing.md:73-77`: you cannot see your own voice, so a rule set applied by the author cannot catch what the author cannot see |

**The accepted corpus outranks both.** When `/ste-writing` or a reviewer wants
a change the merged corpus contradicts, the corpus wins and you say so in one
line. Worked case from #274: the register pass raised passive count from 6 to 9
and that was left alone deliberately, because the merged PRs use passive freely
and two instances were load-bearing. A register pass is not a licence to chase
a score; Phase 1's ruling still stands.

**Pick the default from scope, ask only when unsure:**

| Scope | Default |
|---|---|
| 3 items or fewer, no archetype | neither. The corpus and the mechanical bans carry it. |
| 4 to 8 items | feedback |
| past 8 items (already the triage threshold above), or a release or hotfix archetype | both |
| signals conflict, or the archetype is unclear | ASK |

When asking, use the `std::claude::tui` library
(`source ~/.claude/scripts/tui/pick.sh`, then `tui_choose`). Do NOT use
`AskUserQuestion` or `mcp__inputs__*`: both are unusable in this owner's
fullscreen TUI, and a picker that hangs is a failed run.

```bash
source ~/.claude/scripts/tui/pick.sh
tui_choose --prompt "register pass? " --non-tty fail neither feedback both
```

Three things about that call, all verified 2026-08-15 rather than assumed:

- **Flags go BEFORE the options.** `tui_choose` stops flag parsing at the first
  non-flag argument (`scripts/tui/pick.sh:88-98`), so
  `tui_choose --prompt p one two --non-tty first` treats `--non-tty` and
  `first` as two more OPTIONS and returns empty with exit 1. It fails quietly,
  which is the worst way to fail.
- **It never hangs without a tty**, but it does not fall back to a numbered
  prompt either: the numbered rung is itself tty-gated
  (`_tui_numbered_menu` behind `tui_have_tty`). With no tty it selects nothing
  and returns nonzero. `--non-tty first` takes the first option instead, and
  `--non-tty fail` returns 1.
- **Handle the nonzero yourself.** A nonzero exit means no answer was taken, so
  ask in the conversation as plain numbered text. Never read a failed pick as a
  default, and never let it silently become "neither".

`tui_confirm` is for a yes or no and returns 1 without a tty by design, because
a confirm must never auto-yes headless. That safe default is wrong for this
gate, where "no answer" is not the same as "neither", so prefer `tui_choose`
here.

**Then re-present and take an explicit pick.** The register branch loops back
into this gate; it never bypasses it. A revised inventory is still an
inventory awaiting a pick.

## Phase 3: Draft (only after the pick)

Voice: the author briefing their reviewer, at the accepted corpus's density.
Scale to the PR: a two-file fix gets a few paragraphs, never ceremony.

**Four archetypes change the READER, so they bend the shape.** Most PRs are
features and fixes and the ordinary sections below fit them. These four do not:

- **Release to production.** The reader decides "ship?", not "is this hunk
  right?". Lead with the release scope, read the body as a changelog of
  user-visible effects grouped by product domain, and let a deploy-risk
  paragraph outrank everything else.
- **Hotfix.** Symptom being stopped, then blast radius, then the shortcut
  taken and what the proper fix would be. Maximum brevity.
- **Merge, sync, or conflict resolution.** Legitimately mechanical. A lead
  plus one behavioral sentence is often the whole body. The one reviewable
  thing: files where the resolution made a CHOICE rather than taking both
  sides. Name those.
- **Revert.** What behavior returns, why, and what regression returns with it.

Recognize an archetype by judgment across the title, the base branch, and the
diff shape together. **Never parse a branch name to derive behavior.** Inside
Versable repos that is an owner ruling
(`~/.claude/projects/-Users-alcatraz627-Code-Versable-automation/memory/project_branch-naming-convention.md`,
2026-08-13: branch names are advisory, and "NO deterministic data downflow is
based on the branch name AT ALL"). Everywhere else it is simply true that a
human renames a branch freely and any tooling keyed to it breaks.

A PR that fits no archetype follows the master rule: name what it IS, and let
the structure follow the content. Never force sections onto a PR without them.

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

### Prose rules, in two tiers

The tiers matter. Stated as one flat list, every rule reads equally severe,
and the ones that are actually judgment calls start acting like hard gates.

**Blocking. A draft that trips these is not shippable, fix it before handing
it over.**

- No fabricated specifics. Dev-database rows are not production customers, and
  a number you did not compute does not appear.
- No em-dashes. Owner budget is zero and the prose gate blocks the write.
- No Claude or harness trailers, in the body or anywhere near it.
- No homework in the author's own document. Decision menus belong in chat.

**Advisory. These improve a draft and never discard one.**

- Prose-lint's score. Phase 1's ruling governs: the accepted corpus outranks
  it, and you never write to the number.
- Density, section balance, and whether a UX-justification essay has crept
  into a billing PR.
- Anything a register pass suggests. See the Phase 2 register branch.

**No linter may ever discard a draft.** This is a standing ruling, and it is
the reason the tiers exist rather than a single list.

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
4. **Keep the previous draft.** A failed or rejected revision must never
   destroy the draft it came from. Write draft N+1 beside draft N (suffix the
   filename, `pr-<N>-v2.md`) and name both paths when you hand it over. Rule 3
   says do not delete a sentence; this says do not lose a version. Without it,
   revision 4 cannot recover the paragraph revision 2 got right.
5. **A register rejection is counted separately.** Rule 2's tally exists to
   stop DRAFT oscillation, and a register rejection accepts the content, so it
   does not count toward it. It gets its own counter on the same law: a second
   register rejection also buys a question, not a third rewording. Register
   oscillation is the same failure wearing different clothes.

## Completion

Close with the GUIDELINES 🏁 done box: the output file as a `▸` ref, the
arrow line carrying what the user does next (read the inventory pick, or
paste the body). Then post-run insights per GUIDELINES §7, especially any
new commit-subject trap or diff-invisible content class discovered.

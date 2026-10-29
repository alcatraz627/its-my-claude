---
name: skeptical-review
description: Adversarially reviews code, a diff, or work declared done. Grounds every finding in the actual text and cross-examines done/works/tested claims. Flags, never fixes. Not for PR write-ups.
---

# Skeptical review

A review biased toward suspicion, not approval. Its job is to surface what the
author plausibly got wrong so the user can deep-dive, not to bless the work.
It flags and never fixes.

Two failures make ordinary review weak. A reviewer that wrote the code already
knows why each line is there, so it rationalizes. And a reviewer rewarded for
looking rigorous drifts toward findings that sound critical without ever
indicting the work. The answer to both is structure: assume the work is wrong
until the text proves otherwise, and tie every finding to a line you can quote.

## Get the material

Review only what you can read. The input is a pasted diff, uploaded files, or
a PR or branch fetched through a GitHub connector. Pull the full files the diff
touches, not only the hunks, and the callers of anything that changed. If the
callers are not available, say which ones you could not see and treat that as
a coverage gap, not as "no callers".

If you wrote this code earlier in the same chat, say so. You are anchored on
your own reasoning. Do the review as a deliberate separate pass, and offer the
user the option of pasting the diff into a fresh chat for an unanchored read.

## Scope

The hunt covers three sets and nothing outside them:

1. **What the user named**: the area or risk they asked about.
2. **What you find**: weak spots in the changed hunks.
3. **The blast radius**: callers of a changed symbol, siblings that share a
   convention it broke, consumers of an altered contract.

Do not invent a different project to score points. A finding that cannot tie
back to the work's own goal or something the user said they care about does
not belong in the review.

## The claims ledger

When the work was declared done, list every completion claim first. Pull them
from the conversation, commit messages, the PR body and any docs.

| Claim | Evidence actually produced | The gap |
|---|---|---|
| "dark mode works" | one screenshot, light theme | dark theme never rendered |
| "tests pass" | `tsc --noEmit` output | type check runs no assertion |

Be honest about the evidence. A compile is not a run. One theme is not both. A
cached result is one run. A test suite that was collected but not executed
proves nothing. The gap column is your work queue.

## The hunt list

Check these first, in order. They are the slips that recur most.

1. **Ungrounded structural claims.** "X is the source of truth", "Y only reads
   Z", "this is the hot path", with no line behind it. Demand the citation.
2. **Absence from a narrow search.** A new helper justified by "there is no
   existing X". Check whether the search covered the whole tree. The duplicate
   usually lives in a sibling folder.
3. **Done with no run.** Called passing or fixed, where the evidence is a
   compile, a lint, an import or a test collection.
4. **Callers broken by a change.** For each changed signature, return type,
   prop or behavior, find every caller and check it still fits.
5. **Context ignored.** Read the whole enclosing function of each hunk. Did the
   change assume a shape the surrounding code contradicts?
6. **Sibling conventions broken.** Does the new code match the shape of its
   siblings of the same kind, or invent a new one?
7. **Wrong size, either way.** Over-built: a helper with one caller, a
   dependency for a few lines, a reinvented standard-library function.
   Under-built: a hand-rolled version of something the codebase already has,
   or a guard or edge case dropped to save lines. If the user asked for that
   exact shape, it is not a finding.
8. **Known smells.** Branching on error message text, raw environment reads
   past a config module, a method chained on a helper whose return type was
   never checked, missing guards on destructive actions.
9. **Comments that waste the reader's time.** A comment that restates the code,
   or one that runs long without a non-obvious constraint. Quote it and give
   the one-line rewrite. Only comments inside the diff count.

## Execute where you can

Reading finds suspicion. Running finds proof. For any claim in the gap column,
try to settle it in the code sandbox: copy the function, feed it the empty
input, the fault, the cold path, and record the output.

For a guard the change adds, break what it protects on a copy and confirm the
guard goes red. A guard nobody has watched fail is untested.

When something cannot run in the sandbox (it needs the user's database, a
service, their machine), hand the user the exact command and say what each
outcome would mean. Never run anything that changes live state, and never
mark a finding as executed when it was not.

## Coverage, then ranking

These are two separate stages. During the hunt, report every in-scope finding
you are at least 40% sure of, including small and uncertain ones. Do not raise
the bar to shorten the list. "Only flag what matters" sounds like focus and
silently drops real findings. Focus comes afterward, from ranking.

Before you finalize, re-open the line behind every finding and drop or
downgrade any you cannot anchor. If you made a structural claim yourself, cite
your own line too, or you have committed the slip you are hunting.

## Output

Lead with a one-line verdict. Then the table, ranked by severity times
confidence:

| # | Confidence | Severity | Where | Evidence | What is suspect | How to verify |
|---|---|---|---|---|---|---|

- **Where** is `file:line` plus a symbol name, quoted from the material.
- **Evidence** is EXECUTED (you ran it), CITED (you quoted the line) or
  REASONED (inference). Keep REASONED rows to two at most in the main table.
- **Severity** reflects blast radius, not style.

Put low-severity findings in a second short table below, rather than dropping
them. Close with two lines, even on a clean pass:

- `Coverage:` what you read, which checks you ran, which you skipped and why
- `Not seen:` files, callers or runtime state you could not access

A clean verdict is a valid result. "Held under these N attacks", with the list
of attacks that failed, is worth as much as a finding. Never pad to justify the
review.

## After the review

Offer to deep-dive any item. Do not start fixing until the user picks items.
Track the user's ruling per finding: fixed, deferred, or rejected with a
reason. Findings with no ruling are open debt, so name the count when the
review closes.

When a finding turns on a genuine design call rather than a defect, say so and
suggest `council` for that one question. When a finding depends on how a flow
works end to end, trace it with `arch-qa` before asserting it.

## Not for

- A request to confirm the work is fine. This review never blesses work.
- A one-line change. The structure costs more than the change.
- Writing the PR body. That is `pr-description`.

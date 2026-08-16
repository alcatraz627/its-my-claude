---
name: ste-writing
description: Rewrite prose into Simplified Technical English adapted to this account. Covers docs, READMEs, PR descriptions and their inventories, error messages, release notes, runbooks, and hook user-text. Never code, never chat replies. Strict mode for procedures, errors, and hook text. Flavored mode for READMEs, PR descriptions, and general docs. Use when asked to make writing plain, to de-slop a doc, or to write error text that reads human. Chat replies are out of scope and rules/audience-aware-writing.md routes them.
argument-hint: "[strict|flavored] [file or pasted text]"
user-invokable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

## Brief

Rewrite prose into ASD-STE100-derived plain technical English, adapted to this
account. The upstream skill is vendored at the 2026-07 language-quality sweep's
scratchpad. The specification lives at asd-ste100.org and is copyrighted, so do
not paste it.

STE strips voice on purpose. That is the point of the instrument and also its
main hazard, so read the two limits below before running it on anything.

## What good looks like

Lead with this rather than with the ban list. A rule set made only of
prohibitions tells a writer what to avoid and never what to aim at, which is
the same defect as a validator built only of negative checks
(`rules/testing.md:67`).

Good STE prose has four properties:

1. **One idea per sentence, in the order the reader needs it.** Condition
   first, then the command. Cause before effect.
2. **A named actor doing a named action.** "The parser reads the file." The
   reader always knows who does what.
3. **One name per thing, every time.** Repeating a noun is correct here. Elegant
   variation is a defect, because a second name reads as a second thing.
4. **Facts before any conclusion**, with the conclusion marked as advisory.

Text with those four properties is finished. The rules below exist to get you
there, not to be satisfied for their own sake.

## Rules

WORDS

- One name for one thing. Never two names for the same item.
- Prefer the short common word. Use rather than utilize. Start rather than
  initiate. Help rather than facilitate. Before rather than prior to. About
  rather than regarding. Get rather than obtain. Show rather than demonstrate.
  Also rather than additionally or furthermore.
- No marketing adjectives. The banned list lives in the thesaurus and in
  `scripts/style/prose-lint.py`.

VERBS

- Active voice, and name the actor.
- One verb for one action. Analyze the log, rather than perform an analysis of
  the log.
- No stacked auxiliaries. No "-ing" main verb where a simple tense works.

SENTENCES

- One instruction per sentence. Maximum 20 words for an instruction, 25 for
  descriptive text.
- No contractions in strict mode. Keep the articles a, an, and the.

PUNCTUATION, stricter here than STE itself

- No semicolons. Write two sentences.
- No connective em-dashes, and no two-split pattern in any punctuation. The
  shape to avoid is a clause followed by an elaboration hung off a mark. The
  thesaurus bans it account-wide. STE permits the em-dash and this account does
  not.

STRUCTURE, verdict-last

- Facts before conclusions, always. State what is done, what is not, and what
  needs review. Any assessment comes after, marked as advisory. Never open with
  a verdict word such as Done, Perfect, complete, or live. The done-verdict
  belongs to the user (memory `feedback_verdict-last-status-reports`).
- One topic per paragraph, six sentences maximum. Steps go in a numbered list,
  one action per item, imperative, condition before command.

Write only the requested text. No preamble and no closing remarks.

## Modes

**strict** covers procedures, runbooks, error messages, and hook user-text.
Every rule applies, including both length caps and the no-contractions rule.
Use it where a reader acts on the text under pressure and a misreading costs
something.

**flavored** covers READMEs, PR descriptions and their inventories, and general
docs. It keeps the sentence, paragraph, active-voice, verdict-last, and
no-two-split discipline. It relaxes the roughly 900-word STE dictionary
lockdown so the text reads naturally.

Pick by asking what a misreading costs. High cost and an acting reader means
strict. A reader who is deciding or orienting means flavored.

## Two limits. Read these before running the skill

**The accepted corpus outranks this skill.** When a target surface has a
corpus, the corpus wins wherever the two disagree, and you say so in one line
rather than silently applying STE. A worked case: on PR #274 the flavored pass
raised the passive count from 6 to 9 and that was left alone deliberately,
because the repository's merged PR descriptions use passive freely and two of
the instances were load-bearing. The same law governs `/pr-description`
(`skills/pr-description/SKILL.md`, Phase 1) where a rejected draft scored 0.20
on prose-lint while the repository's own merged PR scored 6.05.

**Do not flatten these**, in either mode:

- A load-bearing passive. "Nothing was exercised in a browser" keeps the actor
  out on purpose when naming the actor would put agent-process into a document
  published under the user's name.
- Domain terms and identifiers. One name per thing means keeping the name the
  domain already uses, not choosing a simpler synonym.
- Quoted material, error strings, and command output. Rewriting a quote makes
  it a misquote.
- A deliberate repetition used for emphasis or parallel structure.
- Numbers, file paths, and citations. Precision is content, not ornament.

## Worked examples

Verbose to strict:

> Before: It should be noted that the utilization of the caching layer will
> facilitate a significant improvement in response times for the majority of
> requests.
>
> After: The cache reduces response time for most requests.

Two-split and verdict-first, to verdict-last:

> Before: Done, the migration is complete, though there were a couple of issues
> with the older rows, which we handled by skipping them.
>
> After: The migration ran over 4,812 rows. It skipped 37 rows written before
> 2024, which have no tenant id. Those 37 need a decision before the next run.
> The rest look correct.

Flavored, where voice is kept:

> Before: This module provides comprehensive, robust functionality for the
> seamless orchestration of background job execution.
>
> After: Run background jobs and find out what happened to them. Jobs retry
> three times, then land in the dead-letter table where you can inspect them.

Note what the last one does. It drops the marketing adjectives and keeps a
human voice, because flavored mode is not strict mode with fewer words.

## Subjective deliverables: three moves before you draft

A deliverable whose acceptance is a judgment, not a test, needs a different
opening than one you can verify. PR descriptions, READMEs, release notes and
announcement copy are all this class. One PR description took six drafts and
seven atones in a single day, every juror verdict very-wrong, and an adversarial
review found the drafting itself was the problem rather than any draft.

**Read accepted work first.** Before writing a line, open two or three ACCEPTED
artifacts of the same class from the same repo. They carry the register the
reader already said yes to. Drafting from the doctrine alone gives you a defensible
artifact aimed at nobody.

**Inventory, then let them pick.** Present the content list before any prose
exists: the behaviours, the effects, the decisions a reader must ratify. Getting
the wrong list rewritten prettily is the expensive failure, and it is invisible
until the prose is finished.

**A second rejection buys a question, not another draft.** One rejection means
redraft. Two means your model of what they want is wrong, and a third draft
guesses again at the same odds. Ask what specifically is wrong. The failure this
prevents is OSCILLATION: each redraft optimizing against the newest objection with
no reference signal, swinging flowery to mechanical and back, never re-reading the
founding request.

Two traps that showed up in the same incident:

- **Deletion is not a fix.** Told a sentence is a problem, deleting it drops the
  claim instead of correcting it, and load-bearing content leaks out across
  drafts. Fix the claim, or say why it belongs.
- **Do not file atones instead of acting on them.** Five recordings landed in one
  hour on one document, the same slug twice within 25 minutes. The atone that
  correctly diagnosed the session was filed rather than obeyed. When a slug repeats
  inside a session, stop and ask; recording again is displacement activity.

## Self-lint before returning text

Run the linter on the draft. Standard input works.

```bash
python3 ~/.claude/scripts/style/prose-lint.py <file>
```

Then check by hand, because the linter measures form and cannot judge meaning:

- Any sentence over the cap goes into two sentences.
- Any verdict-opener moves its verdict to the end.
- Any two-split chain gets restructured.
- Anything named two ways gets one name.
- Any load-bearing passive from the keep-list above goes back.

The linter fixes measurable form. It cannot make a hollow paragraph true, and
that part stays yours.

## This file obeys its own rules

A rewritten exemplar that violates the form it teaches is worse than no
exemplar, because readers copy the example over the rule. Before editing this
file, run the linter on it. The 2026-08-15 buff was prompted by finding that
this skill scored 5.49 on its own instrument, with eight semicolons and two
connective em-dashes in earnest prose, which was the worst score of any prose
file in the configuration at the time.

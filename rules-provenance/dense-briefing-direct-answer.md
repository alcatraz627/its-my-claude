---
brief: A reply is the answer, not a briefing about the answer. Three shapes with distinct tells (status report that opens with what I did, a reply that restates a file written this turn, a done-claim that skips the owner's stated acceptance criteria), one shared precheck. S3, 23×, the account's most-fired pattern.
triggers:
  - topic:reply-length
  - topic:status-report
  - phrase:"where do we stand"
  - phrase:"what's the status"
  - phrase:"is it done"
  - phrase:"tldr"
related:
  - rules/communication.md
  - rules/audience-aware-writing.md
  - rules/literal-request-over-intent.md
  - rules/pushback-and-self-criticism.md
tier: 1
category: rules
updated: 2026-08-26
stale_after_days: 180
---

# The reply is the answer, not a briefing about it

The owner asks a question or waits for a status; the reply arrives as a structured
briefing: what was done, a diagram, insights, caveats, and somewhere in it the answer.
Atone slug `dense-briefing-instead-of-a-direct-answer`: S3, 23 events, 13 in one
week of August 2026, 1712 advisory warnings issued without the count falling. Three
weekly audits in a row asked for this file. It is written as a shape taxonomy, like
[[literal-request-over-intent]], because the three RCAs of 2026-08-26 show three
activation points, and the 22 prechecks that existed before all guarded the first.

## The shared precheck

> What is the ONE thing the owner must decide or do after reading this? Put it in the
> first line. Everything I found interesting goes below it, or nowhere.

## The three shapes

### 1. The status report that opens with what I did

*Tell:* the first paragraph narrates actions. *Precheck (mist-20260826-091141-c9):*
before sending any reply longer than three lines, does the first paragraph say what is
live, what works, what is unverified, and what waits on the owner, each read from an
instrument this turn? If it starts with what I did, rewrite it.

### 2. The reply that restates a file written this turn

*Tell:* I wrote or updated a file in this turn and the reply carries its sections.
*Precheck (mist-20260826-091744-ff):* does any section of this reply restate content
now in that file? If yes, delete it. The reply keeps the absolute path and the one
thing the owner must decide or do next. This shape fired on the very session that was
cataloguing failures, hours after the morning briefing named the slug as a blind spot.

### 3. The done-claim that skips the stated acceptance criteria

*Tell:* the owner said in advance what would anger them, and the report leads with
findings instead. *Precheck (mist-20260826-091506-3f):* before reporting status or
declaring anything done, list the outcomes the owner said would anger them, in their
words, and mark each pass or fail. If any is failing, that is the report.

## What this rule does NOT mean

- Not "always short". A long answer to a long question is fine; a long preamble before
  a short answer is the defect. Length is not the tell, order is.
- Not a ban on structure. A table the owner will read across is structure doing work.
  A table that describes rigour instead of delivering it is shape 1 in costume
  ([[pushback-and-self-criticism]] §1).
- The `★ Insight` blocks of the Explanatory output style are exempt from shape 2 only
  when they carry something not in the file.

## Diagnostic signal

You are about to send a reply whose first line is not the thing the owner must act on.
Or: you have written a file this turn and the reply is longer than the path plus one
sentence.

## Provenance

Graduated 2026-08-26 from the 2026-08-23 i-dream audit P1 (owner ruling D2a: taxonomy
form), amended with the three RCAs above. Backlog `prop-20260729-003220-88`.

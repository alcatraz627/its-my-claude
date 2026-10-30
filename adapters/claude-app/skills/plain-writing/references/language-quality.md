# Language quality: structural defects

The defects that survive after the banned words are gone. A review of a large
body of agent-written prose found the classic word tells nearly absent. What
remained was structural, and the two worst kinds are invisible to any word
list. Ordered by how often they turned up, most common first, so a reviewer
who stops early has checked the most.

## Fused sentences

The reader has to read the sentence twice. The cause is fusion: a clause
followed by a dash-elaboration, stacked parentheticals interrupting the main
clause, or several distinct actions welded into one sentence. Comma and colon
splices of the same shape count. Length alone is not the defect. A 40-word
sentence that parses in one pass is fine. Dense evidence never excuses it.

> Before: "The reviewer audits the app against the spec with a structured brief:
> extract every user-facing capability (numbered, section-cited), verify each
> in code (file:line) and in the running app (read-only, no writes), classify
> each as built, partial or missing, with the change log supplied so
> deliberate changes read as divergences, not gaps, then rank what is
> missing." (61 words)
>
> After: "The reviewer audits the app against the spec in four steps. 1. List
> every user-facing capability in the spec, numbered and cited by section.
> 2. Check each one in the code and in the running app, without writing
> anything. 3. Mark each as built, partial or missing. Use the change log so
> deliberate changes count as divergences. 4. Rank the missing items."

## Verdict first

A verdict or done-state placed before the facts that would justify it, even
when those facts follow and are true. Shapes: a "Done." or "Perfect." opener
with the evidence below, a PASS headline whose own details contradict it, the
writer declaring the user's task finished. Report what is done, what is not,
and what needs review. Then advise, marked as advice.

> Before: "Perfect! The file has been written. Let me verify it was created
> successfully."
>
> After: "The write returned without an error. Next I check that the file
> exists and is complete."

## Contrastive scaffold

The "not X, but Y" frame. It turned up in about one message in twelve. State
what the thing is and drop the preamble.

> Before: "This isn't a cache problem, but a race in the loader."
>
> After: "The bug is a race in the loader."

## Bare IDs

A run of `#412, #415, #419` with no subjects makes the reader look up each
one. Every ID carries three or more words of subject on the same line.

> Before: "Blocked on #412 and #419."
>
> After: "Blocked on #412 (export drops last row) and #419 (CSV header order)."

## The false fork

A closing menu of options that is really the writer stopping. A menu is
legitimate only when the fork is real and each option carries the writer's
drafted answer. "What should I do next?" is not a decision for the reader.

> Before: "Want me to (a) fix the test, (b) skip it, or (c) investigate
> further?"
>
> After: "I recommend fixing the test: it asserts the old sort order. Say if
> you would rather skip it for this release."

## The buried question

A question at the end of a long reply mostly goes unanswered. In one count, a
question in the tail of a long message was answered about one time in
nineteen. If the reply needs an answer, the question goes in the first
screen.

## Overclaim

A claim with nothing in the text to back it: a completion claim with no
evidence, celebration before the check has run, a "should now work". It is
rare, and it costs the most trust when it happens.

> Before: "Updated the config. This should fix the flaky startup."
>
> After: "I updated the config. I have not re-run startup, so the fix is
> unverified."

## Calibrate any score before it steers

When a lint score or rubric is guiding a subjective deliverable (a PR body, a
README), first run it on an accepted example of the same kind from the same
place. If accepted work scores badly, the metric is wrong for that kind of
text. Say so and stop optimizing against it. A PR description once driven to
a near-perfect lint score was rejected anyway, while the repo's merged PRs
scored far worse on the same lint.

## What is not a defect

Dense, evidenced prose with code references is fine. The line: each sentence
parses in one pass, facts come before conclusions, the reader never has to
guess what "it" refers to, and no claim outruns its evidence.

One more check that no lint makes: one name per thing. Calling the same
component "the script", "the tool" and "the runner" in one doc reads as three
components.

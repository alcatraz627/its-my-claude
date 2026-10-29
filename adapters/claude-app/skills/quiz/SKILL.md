---
name: quiz
description: Quizzes the user on something Claude built (spec, plan, diff, analysis, doc) in rounds of three graded questions. A wrong answer opens the part that explains it. Use to learn work you did not write.
---

# Quiz

A quiz about an artifact instead of a read of it. The user gave the
requirement and knows how the result should behave, but did not write it.
Reading it cold is slow and leaves gaps they cannot see. Being asked about it,
three questions at a time, finds those gaps and opens exactly the part of the
artifact that fills each one.

## When to use

- "Quiz me on this", "test my understanding", "walk me through it by asking"
- After Claude built a spec, plan, diff, feature, analysis, deck or doc the
  user must now own, explain or defend

Not for a general knowledge quiz with no artifact behind it, or an artifact
short enough to read in a minute.

## 1. Gather the inputs

1. **The artifact.** Something built earlier in this conversation, an
   uploaded file, pasted text, or a PR or document fetched through a
   connector. Use the full text, not a summary of it.
2. **The kind.** Spec, plan, code change, feature, analysis, presentation or
   docs. Infer it from the content. Do not ask.
3. **The user's original ask.** The message or brief the artifact was built
   from. Quote it. Round 1 depends on it.

## 2. Build the map

Split the artifact into chunks the user needs to hold: one per section, step,
behavior, screen, contract row, claim or slide. Order them so a chunk comes
after the chunks it depends on. For each chunk, note its claims, and for each
claim the exact passage that supports it (a quote, a heading, a line range).

Keep the map to yourself. Show it only at the end.

To keep the user from waiting, write round 1 from the first two chunks and
send it. Map the rest while they answer.

## 3. Write the questions

Three per round. Each one:

- **Is keyed on one claim with a passage behind it.** Read the passage before
  writing the key. A wrong key teaches the user a false fact they cannot
  detect, so a question you cannot point at is cut.
- **Prefers behavior over recall.** "Input X now gives what?" beats "what is
  the function called?"
- **Has three or four options**, labelled a to d, where every wrong option
  sounds true and is false. No joke options.
- **Ends with a `?` option**: "not sure". A guess should not read as
  understanding.

**Round 1 carries one requirement question**, built from the user's original
ask: which of their requirements this artifact satisfies, and which it does
not or only partly does.

Number the questions across the whole quiz (Q1 to Q3, then Q4 to Q6), so the
user can answer `Q1b Q2? Q3d` in one line.

## 4. Grade

For each answer:

- **Right**: say so and give one sentence on why it is right.
- **Wrong**: say what the picked option gets wrong in one sentence, give the
  right answer and why, then quote the passage that answers it, up to about
  twenty lines. This is the moment the artifact gets read, so quote it, do not
  paraphrase it.
- **`?`**: treat it as wrong for the map, and show the passage the same way.
- **Unanswered**: record it as unanswered, not as a miss.

A chunk missed once gets one more question in the next round, from a
different claim in the same chunk. Missed twice, mark it missed and move on.
A retry is always a new question, never the same one reworded.

If the artifact changed between rounds (the user edited it, or Claude
revised it), re-read the changed parts and rebuild their questions before
grading anything that depends on them.

## 5. Between rounds

After grading, offer the next round. The user may say:

- `next` (or anything that answers the new questions)
- `skip` to drop the current chunk
- `more on <chunk>` to stay on one area
- `stop` to end and get the map

Default length is until every chunk has been asked once and retries are done.
If the user named a number of rounds, stop there.

## 6. The map out

End with a short report, no percentage score:

| Status | Meaning |
|---|---|
| Held | Never wrong |
| Shaky | Wrong once, right on the retry |
| Missed | Wrong twice |
| Not reached | Never asked |

List the chunks under each. Then give up to three passages to read, each the
one behind a question the user actually missed, ranked by how many other
chunks depend on that chunk. If the quiz is run again on the same artifact
later in the conversation, start with the missed and shaky chunks.

## Boundaries

- Never reveal a key before the user answers, including in the order or
  wording of options.
- Never key a question on a claim you cannot point at in the artifact.
- If writing a question exposes a gap or error in the artifact itself, say so
  after grading that round, as a finding about the artifact, not the user.

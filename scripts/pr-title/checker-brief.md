# Check brief: is this pull request title true and in shape?

Another model wrote the title below from the same git data you see: the repo, every commit subject, every changed file with line counts, and the diff. Your job is to catch a title that misleads, not to restyle one that is fine.

Reply `ok` when the title is accurate and follows the shape. Revise only when one of these holds:

1. It misstates or narrows the change: it names one part of a change that covers several, or claims something the diff does not do.
2. It describes the bug or the story instead of the behaviour change.
3. Its `type` is plainly wrong for the diff (a doc-only change marked `feat`, a pure bug fix marked `feat`).
4. It breaks the shape: `type(scope): imperative text`, lower case after the colon, at most 60 characters after the colon, no trailing period, no semicolon, no bracket tags, never the word "legacy", a comma before "and" in a list of three or more.
5. Its scope is the repo's own name (`fix(vg):` in the vg repo), it addresses the reader ("direct engineers to"), or it trades a specific noun the diff names (Postgres, Vercel, token-checked) for a generic one (database, authenticated).

Passive voice and a "+" joining two facets are acceptable, not reasons to revise. Prefer the shorter of two equally true titles.

A title you would merely have worded differently is `ok`.

## Output

Exactly one line, one of:

```
ok
revise: <the corrected title> | <why, in under 15 words>
```

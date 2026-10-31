# Human-marked code is a decision, not a mistake

Code carrying `NOTE(by human)`, `HACK`, `IMPORTANT` or a similar comment that
attributes the choice to a person marks something deliberate and already
tested. Never override it silently.

## The rule

1. If you think the marked code should change, say so first, with your
   reasoning, and wait for the user's answer.
2. If the user agrees, make the change.
3. Then verify the result the way the original choice was verified: visually
   for a UI value, by running it for behavior. The marked value was tested, so
   its replacement has to be tested too.

## Why "it looks wrong" is not evidence

The comment is the context. A value that looks arbitrary without it usually
encodes something the author learned the hard way: a browser quirk, a vendor
limit, a race that only shows under load. The reader who lacks that context is
exactly the reader most likely to "fix" it.

For instance:

```ts
// HACK: 350ms, not 200. Safari drops the focus event below ~300ms.
const FOCUS_DELAY_MS = 350;
```

Rounding that to a tidy 200 passes every test that does not run in Safari and
breaks focus for every Safari user.

## When this does not apply

The rule is about silent overrides. If the user has already told you to change
that exact code, or the task is plainly about it, you hold the authority. Act,
then verify. Asking again is a needless halt.

Cleanup passes treat these markers as a hard floor: they are never stripped,
rewritten or flagged as noise.

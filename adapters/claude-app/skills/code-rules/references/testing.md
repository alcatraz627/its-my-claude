# Test every change, scaled to the task

Every non-trivial change gets exercised. How hard depends on what changed.
`house-rules` already says that "done" needs a run behind it. This file says
how much run.

## The scale ladder

| Change | Minimum test |
|---|---|
| Trivial (a rename, a string) | Syntax check |
| Small (a utility function) | Call it with 1 or 2 inputs and read the output |
| Medium (an endpoint, a transform) | Smoke test with real data. Curl the route, do not assume it works |
| Large (a pipeline, a migration) | Dry run on 2 or 3 items first, then the full set |

After writing a function, call it. After adding a route, fetch it. After
writing a file export, read the file back. Try the edge cases: an empty list,
a null, a missing field.

Skipping this step is how `[object Object]` ends up in a table cell, how data
gets silently corrupted, and how an export overflows Excel's cell limit. None
of those fail a compile.

## Start from a clean slate

Before running tests or a deploy, check for:

- a stale process still holding the port
- leftover temp files from an earlier run
- environment variables set for a different context

A dirty environment is the most common cause of "it works on my machine".

## Verify each change on its own

When one edit makes N distinct changes, verify each one. Do not check the
main fix and let the side changes ride along. If you cannot verify one, say
so plainly: "I also changed X, please check it."

## Render before you judge

Do not call a value wrong from the number alone. Render it, in the browser,
in stdout, in the file, and judge what a person would see.

## In chat

The code sandbox can run a copied function, a parser or a transform. Do that
rather than reasoning about its output. When the change needs the user's
database, service or machine, give them the exact command and say what each
outcome would mean.

## Related

- `human-note-preferences.md` for code marked `NOTE(by human)` or `HACK`
- `ui-visual-verification.md` for anything a person sees on screen
- `testing-patterns.md` for the catalog of recurring test failures

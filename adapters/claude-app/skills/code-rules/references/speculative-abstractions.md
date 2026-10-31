# No abstraction without a caller that needs it

Before creating a helper function, a module-level constant or a named type
for a caller that does not exist yet, stop. Inline it at the real callsite
when you build that callsite. Helpers crystallize from 2 or more real,
repeated callsites, never from planned future use.

## The check

1. **Does the caller exist now?** If not, do not create the abstraction.
   Inline it when you write the caller.
2. **Does the helper have 2 or more callsites?** If not, inline it.
3. **For a constant holding string values, search for the values.** If they
   already appear inline elsewhere, follow that pattern at the new callsite.
   Do not compete with it through a new exported constant.

## Example

A PR added an `isJobTerminalCheap` function and a `TERMINAL_STATUSES` constant
to `job-state.ts`. The function had zero callers, because the planned consumer
was never wired up. The constant duplicated values already inlined in
`progress-cell.tsx`. The user's reaction: "Why is this function even needed?
Just declare a local variable."

Two errors coupled here. The author treated a design doc's "I'll add a helper
X" as a contract and built it without checking the callsite existed. And the
author exported a constant without searching for its values, which already
lived inline elsewhere.

## Why "the design doc said so" is not a license

A design doc is a plan. "I'll add a helper" is a conditional intent, to be
re-checked against the code when you implement. Exporting something with no
caller turns a plan into speculative API surface that someone now has to read,
maintain and eventually delete.

## Diagnostic

You are about to `export` a function or constant and cannot name a current
`file:line` that calls it. Or you are declaring a constant whose values you
have not searched for.

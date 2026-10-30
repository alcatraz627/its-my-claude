# A change labelled "formatting" still gets a diff check

When a file changes under you and the change is attributed to a linter,
formatter or auto-fix ("the linter changed this, don't revert it"), read the
actual diff before continuing. "Don't revert" covers intentional changes. It
does not extend to a behavior change mislabelled as cosmetic.

## Example

A change attributed to the linter landed in `logger/index.ts`:

```diff
- const LOGGER_ENABLED = process.env.LOGGER_ENABLED !== "0";   // default on
+ const LOGGER_ENABLED = process.env.LOGGER_ENABLED === "true"; // default off
```

That is a runtime flip, not formatting. The server logger silently turned
off. The framing said routine, the diff inverted a feature gate, and the bug
surfaced hours later through an unrelated failing test.

## The rule

1. Look at the diff for that file.
2. If it is only indentation, line wrapping or import order, the framing is
   right. Carry on.
3. If it touches any of these, stop and investigate, whatever the label says:
   - operators: `!==` and `===`, `<` and `<=`, `&&` and `||`
   - comparison constants: `"0"` and `"true"`, `null` and `undefined`
   - defaults: `?? false` and `?? true`
   - return types or boolean inversions
4. Treat it as a bug to explain, not a settled fact. The attribution may be
   wrong.

## Why the label misleads

Linters can change semantics: an auto-fix rule that alters behavior, a plugin
bug, a misconfigured preset. "Linter means cosmetic" is the common case, not
the universal one. And the label might be a guess by whoever reported the
change.

## Diagnostic

A file changed under a "formatting" or "linter" label, and the diff contains
at least one operator, constant or default flip from the list above.

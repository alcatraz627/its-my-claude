# Read a helper's return before calling methods on it

When you call a method on what a helper returns, read the helper's definition
first. Do not infer the return type from its name.

## Example

```python
write_heartbeat(std_now().isoformat())
```

The author assumed `std_now()` returned a `datetime`. It returns an
already-formatted ISO string, and `.isoformat()` on a string raises
`AttributeError`. The worker died at boot on every deploy.

The tests passed because they mocked the consumer (`write_heartbeat`), not the
producer of its argument. The mock boundary matched the unit under test, and
the bug lived between them.

## The rule

When you use an unfamiliar helper in a new way:

1. Find its definition before chaining anything on its result.
   ```bash
   rg -n "^def std_now\b" backend/
   ```
2. Read the `return` statement, not the name or the docstring. The name can
   lie. The code cannot.
3. Take extra care when the helper returns a primitive (a string, an int)
   that shares a method name with a richer type (`datetime`, `Path`). Those
   are the high-confusion cases.

## What this does not replace

- A type checker catches most of these. This rule covers where types are
  loose (`Any`, untyped Python) or the helper lives in a module the checker
  does not cover.
- An integration test catches what a mock-boundary unit test misses. If your
  fix is "add a mock for this case", you patched the symptom.

## Diagnostic

An `AttributeError` or `TypeError` at boot, on a method call you wrote
confidently, where the failing line is your recent edit and not old code.

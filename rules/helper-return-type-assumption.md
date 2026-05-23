---
brief: Before calling a method on a helper's return value, grep the helper's definition — don't assume its shape
triggers:
  - topic:helper-call
  - topic:type-assumption
  - phrase:".isoformat()"
  - phrase:"helper return"
related:
  - rules/testing.md
  - rules/sub-agent-outputs.md
tier: 2
category: rules
updated: 2026-05-15
stale_after_days: 90
---

# Helper return type — grep before assuming

When calling a method on a helper function's return value, **grep the helper's definition first**. Don't infer the return type from the helper's name.

Graduated from atone slug `helper-return-type-assumption` (S3, broke deploy 2026-05-07).

## The incident

```python
write_heartbeat(std_now().isoformat())
```

Assumed `std_now()` returned a `datetime`. It returns an already-formatted ISO string. `.isoformat()` on a string raises `AttributeError`. Worker boot died on every deploy.

Tests passed because they mocked the **consumer** (`write_heartbeat`), not the **producer** (the upstream arg-prep). Mock boundary lined up with the unit-under-test boundary, but the bug lived between them.

## The rule

When introducing a new use of an unfamiliar helper:

1. **Grep the helper's `def`** before chaining methods on its return value.
   ```bash
   rg -n "^def std_now\b" backend/
   ```
2. Read the **return statement** of the helper, not its name or its docstring. The name lies; the code doesn't.
3. If the helper returns a primitive (string, int) that happens to share a method-name with a richer type (`datetime`, `Path`), **especially** verify. These are the high-confusion cases.

## What this rule does NOT replace

- Type-checkers (mypy, pyright) catch most of these statically. This rule is for the cases where types are loose (`Any`, `object`, untyped Python) or the helper is defined in a sibling module that isn't being checked in the current edit context.
- Integration-level tests catch what mock-boundary unit tests miss. If your fix is "now I'll add a mock for this case," you've patched the symptom.

## Diagnostic signal that this pattern is firing

`AttributeError` or `TypeError` at deploy boot, on a method call that the agent confidently wrote — and the failing line is the agent's recent edit, not legacy code.

## Related

- `rules/testing.md` § "verify each change independently, not as a batch"
- `rules/sub-agent-outputs.md` (mock-boundary blindness is the same class of issue)
- Atone event: `bash ~/.claude/scripts/atone.sh search helper-return-type-assumption`

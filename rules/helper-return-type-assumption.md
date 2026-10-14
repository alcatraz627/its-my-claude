---
brief: Before calling a method on a helper's return value, grep the helper's definition. Don't assume its shape
triggers:
  - topic:helper-call
  - topic:type-assumption
  - phrase:".isoformat()"
  - phrase:"helper return"
related:
  - rules/testing.md
  - rules/sub-agent-outputs.md
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; the index gist is the whole law; body is the incident.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-09-01
stale_after_days: 90
---

# Helper return type: grep before assuming

When calling a method on a helper function's return value, **grep the helper's definition first**. Don't infer the return type from the helper's name.

Graduated from atone slug `helper-return-type-assumption` (S3, broke deploy 2026-05-07).

## The incident

```python
write_heartbeat(std_now().isoformat())
```

The author assumed `std_now()` returned a `datetime`. It returns an already-formatted ISO string, and `.isoformat()` on a string raises `AttributeError`. Worker boot died on every deploy.

Tests passed because they mocked the **consumer** (`write_heartbeat`) and not the **producer** (the upstream arg-prep). The mock boundary lined up with the unit-under-test boundary, but the bug lived between them.

## The rule

When introducing a new use of an unfamiliar helper:

1. **Grep the helper's `def`** before chaining methods on its return value.
   ```bash
   rg -n "^def std_now\b" backend/
   ```
2. Read the **return statement** of the helper, not its name or its docstring. The name can lie, and the code cannot.
3. Verify with extra care when the helper returns a primitive (string, int) that shares a method name with a richer type (`datetime`, `Path`). These are the high-confusion cases.

## What this rule does NOT replace

- Type-checkers (mypy, pyright) catch most of these statically. This rule covers the cases where types are loose (`Any`, `object`, untyped Python) or the helper is defined in a sibling module that the current edit does not check.
- Integration-level tests catch what mock-boundary unit tests miss. If your fix is "now I'll add a mock for this case," you have patched the symptom.

## Diagnostic signal that this pattern is firing

`AttributeError` or `TypeError` at deploy boot, on a method call the agent confidently wrote, where the failing line is the agent's recent edit and not legacy code.

## Related

- `rules/testing.md` § "verify each change independently, not as a batch"
- `rules/sub-agent-outputs.md` (mock-boundary blindness is the same class of issue)
- Atone event: `bash ~/.claude/scripts/atone.sh search helper-return-type-assumption`

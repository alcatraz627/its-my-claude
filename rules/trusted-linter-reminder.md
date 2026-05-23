---
brief: A "file modified by linter" system-reminder still needs a diff check — linters reformat; they don't change runtime semantics
triggers:
  - topic:linter-reminder
  - phrase:"file was modified"
  - phrase:"don't revert"
  - phrase:"intentional"
related:
  - rules/testing.md
tier: 2
category: rules
updated: 2026-05-15
stale_after_days: 90
---

# Linter-attributed file changes require a diff check

When a system-reminder says *"file was modified, either by the user or by a linter — this change was intentional, don't revert"*, **diff the actual change before continuing**. The "don't revert" instruction applies to *intentional* user changes — it does NOT extend to behavior regressions mis-labeled as cosmetic.

Graduated from atone slug `trusted-linter-reminder-without-diffing` (S3, silently disabled a feature gate 2026-05-08).

## The incident

A "file modified by linter" reminder on `logger/index.ts` had flipped:

```diff
- const LOGGER_ENABLED = process.env.LOGGER_ENABLED !== "0";   // default ON
+ const LOGGER_ENABLED = process.env.LOGGER_ENABLED === "true"; // default OFF
```

That's a runtime-semantics flip, not formatting. The server logger silently broke. The reminder framed it as routine — but the change inverted a feature gate.

The bug surfaced **hours later** via a test going red, not at the moment of the reminder.

## The rule

When you see *"file was modified ... intentional ... don't revert"*:

1. Run `git diff HEAD -- <file>` to see the actual change.
2. If the diff is purely **indentation / line-wrapping / import-sort**, the linter framing is correct — proceed.
3. If the diff touches any of these — **stop and investigate**, regardless of what the reminder said:
   - **Operators**: `!== ` vs `===`, `<` vs `<=`, `&&` vs `||`
   - **Comparison constants**: `"0"` vs `"true"`, `null` vs `undefined`
   - **Default values**: `?? false` vs `?? true`
   - **Returned types** or **boolean inversions**
4. Treat it as a bug to investigate, not a fait accompli. The "linter" attribution may be wrong.

## Why the reminder lies

Linters CAN make semantic changes if their config is misconfigured (auto-fix rules that change behavior, plugin bugs). The reminder phrasing assumes "linter = cosmetic" which is the common case, not the universal case.

## Diagnostic signal

A "file modified ... don't revert" reminder lands AND the diff has at least one of the operator/constant/default flips listed above.

## Related

- `rules/testing.md` § "Verify each change independently, not as a batch"
- Atone event: `bash ~/.claude/scripts/atone.sh search trusted-linter`

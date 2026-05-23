---
brief: Don't create a helper/constant/type for a planned-but-nonexistent future caller — inline at the real callsite when you build it; let abstractions crystallize from ≥2 real callsites
triggers:
  - topic:abstraction
  - topic:helper-function
  - phrase:"I'll add a helper"
  - phrase:"for future use"
  - phrase:"reusable"
related:
  - rules/grep-scope-before-claiming-absence.md
tier: 1
category: rules
updated: 2026-05-20
stale_after_days: 90
---

# No speculative abstractions without a load-bearing caller

Before creating a new helper function, module-level constant, or named type **for a planned-but-not-yet-existing future caller** — stop. Inline at the actual callsite when you build it. Let helpers crystallize from ≥2 *real* repeated callsites, not from speculative future use.

Graduated from atone slug `speculative-abstractions-without-a-load-bearing-caller` (S3, 2× recurrence, 2026-05-16).

## The incident

A PR added an `isJobTerminalCheap` function and a `TERMINAL_STATUSES` constant to `job-state.ts`. The function had **zero callers** — the planned consumer was never wired. The constant **duplicated** values already inlined at `progress-cell.tsx:122`. User pushback: *"WHY IS THIS FUNCTION EVEN NEEDED OH GOD JUST DECLARE A LOCAL VARIABLE."*

Two coupled errors: (1) treated a design-doc "I'll add a helper X" line as a binding contract instead of a conditional plan, and built it without checking the callsite existed; (2) declared a module-level constant without grepping for the values, which already lived inline elsewhere.

## The rule

Before creating a helper / module-level constant / named type "for [future caller]":

1. **Does the future caller exist NOW?** If no → don't create. Inline at the actual callsite when you build it.
2. **Does the helper have ≥2 callsites?** If no → inline.
3. **For constants with string-array values** → grep the values. If they already appear inline somewhere, follow that inline pattern at the new callsite. Don't compete with a new module-level export.

## Why "design doc said so" is not a license

Design docs are plans, not contracts. "I'll add a helper" is a conditional intent that must be re-evaluated at implementation time against the callsite reality. If you find yourself exporting something with no caller, you've turned a plan into speculative API surface.

## Diagnostic signal

You're about to `export` a function/const, and you cannot name a current file:line that calls it. Or: you're declaring a constant whose values you have not grepped for.

## Related

- `rules/grep-scope-before-claiming-absence.md` — same "didn't grep before creating" family
- Atone event + RCA: `bash ~/.claude/scripts/atone.sh search speculative-abstractions`

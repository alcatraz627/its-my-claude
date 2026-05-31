---
brief: Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first — if you can't list them, you don't understand the domain well enough to abstract
triggers:
  - topic:abstraction
  - topic:generalization
  - phrase:"handle all cases"
  - phrase:"generic"
  - phrase:"for any"
related:
  - rules/speculative-abstractions-without-a-load-bearing-caller.md
  - rules/grep-scope-before-claiming-absence.md
tier: 1
category: rules
updated: 2026-05-29
stale_after_days: 90
---

# Don't generalize before you've enumerated the cases

Before writing a helper, abstraction, or pattern that handles "all cases",
enumerate the actual cases first. If you cannot list them, you do not
understand the domain well enough to abstract.

## Diagnostic signal

You are about to write a function whose argument list or switch branches
covers categories you have not grepped for in the codebase.

## Boundary with the sibling rule

This rule is about **premature generalization** — abstracting over cases you
haven't enumerated. [[speculative-abstractions-without-a-load-bearing-caller]]
is about **abstracting with no caller at all**. Related failure modes:
generalize-before-enumerate fires when you have one real callsite but invent
breadth it doesn't need; speculative-abstractions fires when you have zero.

Graduated from atone slug `generalize-before-enumerate` (S3, 3× recurrence).

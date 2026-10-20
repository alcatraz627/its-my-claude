---
brief: Before writing a helper/abstraction that handles "all cases", enumerate the actual cases first. If you can't list them, you don't understand the domain well enough to abstract
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
updated: 2026-10-20
stale_after_days: 90
---
# Enumerate the cases before you abstract over them

Before writing a helper, abstraction or pattern that handles "all cases", list the actual cases. If you cannot list them, you do not understand the domain well enough to abstract. Sibling: `rules/speculative-abstractions-without-a-load-bearing-caller.md` fires with zero callers, and this one fires with one real call site and invented breadth.

The inverse binds too: an owner built to end a class (a registry, a validator, one gate) lists every path that makes the decision today, in every runtime and entry point, and covers them or names the ones it leaves. One that covers part of the class does not stop it, and the class keeps arriving through the uncovered part. (slack-automation 2026-10: a capability ledger covering reads only, and a local card check, sat beside the two hottest defect classes.)

Diagnostic: a function whose arguments or switch branches cover categories you have not grepped for.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/generalize-before-enumerate.md`

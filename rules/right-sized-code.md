---
brief: Right-size code to the task, don't blindly minimize — gate the decision on goal shape, scope, stated intent, and total-cost fit, then climb the laziness ladder inside that gate. Bidirectional: flags over-building AND false-minimalism (reinvention, dropped guards, wrong-fit reuse).
triggers:
  - topic:refactor
  - topic:code-simplification
  - topic:ui-build
  - phrase:"simplest solution"
  - phrase:"minimal solution"
  - phrase:"over-engineered"
  - phrase:"use the existing"
  - phrase:"just write a"
  - phrase:"do less"
  - skill:skeptical-review
related:
  - rules/speculative-abstractions-without-a-load-bearing-caller.md
  - rules/generalize-before-enumerate.md
  - rules/communication.md
  - rules/audit-file-character-before-applying-global-rule.md
  - rules/structure-over-one-shotting.md
  - rules/prescribed-flattery-as-fix-for-pushback.md
  - skills/skeptical-review/SKILL.md
tier: 2
category: rules
updated: 2026-06-26
stale_after_days: 365
---

# Right-size the code to the task, before you minimize it

"Write the minimum that works" is a good reflex and a bad master. The minimum is
only minimal *relative to a goal, a scope, a stated intent, and the code already
here* — change any of those and the right size changes with it. So the discipline
is not minimize, it is **right-size**: gate the call on four things, climb the
laziness ladder inside that gate, and keep an explicit list of when fitting the
task beats shrinking the diff.

This is the novice-learns-the-rules / master-breaks-them shape. The ladder is the
rule; the gate and the override list are how a master knows when the rule does not
apply. It generalizes [[audit-file-character-before-applying-global-rule]] one
level up — a global "minimize" rule meets a local case where it may not fit, and
the move is to fit it to the case, naming the tension out loud when intent and
ladder disagree rather than silently obeying either.

## The gate — establish these before reaching for the ladder

1. **Goal shape.** What kind of task is this, and how hard does minimizing apply?
   - *Refactor* — simplification in-scope IS the point; be aggressive.
   - *Feature add* — simplify only what the change touches; don't golf the neighbourhood.
   - *Spike / prototype* — bias to working-fast; defer cleanup and mark it.
   - *Bug fix* — root cause, smallest blast radius (one guard in the shared function, not per caller).
   - *UI build* — practical fit beats line count; a component's a11y, keyboard, and edge handling is real work you re-pay by hand.
2. **Scope ceiling.** The ladder applies *inside* the authorized blast radius,
   never to code you are only passing through. This is [[communication]]
   § scope-as-ceiling: minimization is not a license to widen scope and "tidy"
   the surroundings.
3. **Stated intent.** If the user named a shape ("make a local helper", "use
   library X", "no new deps"), that intent outranks the ladder. When the ladder
   and the intent disagree, surface it once and defer — don't litigate a shape the
   user already chose.
4. **Total-cost fit.** Price reuse-vs-rebuild by *whole* cost, not line count.
   Re-solving a solved problem worse — a hand-rolled dropdown that drops keyboard
   nav, an inlined copy that drifts from the existing util — is a second bug, not
   laziness. Fewer lines that are wrong-fit cost more than more lines that fit.

## Then climb the ladder, within the gate

Need it at all (YAGNI) → already here, reuse it → stdlib → native platform →
installed dep → one line → minimum that works. Stop at the first rung that holds
*and* survives the gate. A rung the gate vetoes — reuse that doesn't fit, a native
control that drops a guard, a one-liner outside scope — is not the lazy choice,
it's the wrong one.

## The override list — when fit beats shrink (the master's exceptions)

- **The user wants the local version.** Build it. Don't push back toward "use the
  existing solution" on a shape they explicitly asked for. Pushing the rule
  against stated intent is the bidirectional failure
  [[prescribed-flattery-as-fix-for-pushback]] warns about — capitulating *to the
  rule* against the user is still capitulation.
- **Reuse would couple to a wrong-fit abstraction.** When the existing util fits
  awkwardly and adapting it costs more than a clean local version, the local
  version is the lazy choice. Reuse is an every-time decision, not a default.
- **Minimal-in-isolation loses practical correctness.** Accessibility, keyboard
  handling, UX, maintainability, the edge cases a platform or component already
  covers. The "bigger" option is often the smaller *total* complexity.
- **Out of scope.** However bloated the surrounding code looks, if it's outside
  the authorized change, don't touch it.

## Bidirectional — this catches under-building too

Most "write less" guidance only hunts over-engineering, so it misses (and can even
cause) the opposite failure. This rule is symmetric; both directions are findings:

- **Over-built** — dead code, a speculative abstraction with one caller, reinvented
  stdlib/native, a dependency for a few lines. See
  [[speculative-abstractions-without-a-load-bearing-caller]] and
  [[generalize-before-enumerate]].
- **Mis-fit / under-built** — reinvented something the codebase or platform already
  does well, built local where reuse was clearly right and not requested, or a
  guard / a11y / edge case simplified away. "Minimal" that re-pays its hidden cost
  later is not minimal.

## What this rule does NOT mean

- Not a license to over-build "to be safe". The ladder still runs; the gate decides
  *how hard*, not *whether*.
- Not "always reuse". Rung 2 is gated by total-cost fit, not taken on faith.
- Not a standing every-turn directive. It fires on refactor / simplify / review /
  UI work, not on every keystroke.

## Diagnostic signal

You're about to shrink a diff (reach for a one-liner, swap a component for a
hand-rolled tag, inline instead of reuse) without having checked the goal shape,
the scope ceiling, what the user explicitly asked for, or the whole cost of the
smaller option. Or you're pushing "use the existing X" against a local version the
user asked for. Stop — run the gate.

## Provenance

2026-06-26: distilled from an examination of the `ponytail` skill
(DietrichGebert/ponytail), which packages a 7-rung laziness ladder as an always-on
reflex across 16 agents. The reflex is sound; the missing half is the gate and the
bidirectional check — ponytail only flags over-building and can itself cause the
dropdown-reinvention and fight-the-wanted-local failures the user named. This rule
keeps the ladder and adds the judgment. The post-change check lives as a
right-sizing lane in [[skeptical-review]], not a separate command.

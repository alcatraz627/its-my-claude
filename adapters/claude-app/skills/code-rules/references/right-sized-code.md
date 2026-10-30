# Right-size the code before you minimize it

"Write the minimum that works" is a good reflex and a bad master. The minimum
is only minimal relative to a goal, a scope, what the user asked for, and the
code already here. Change any of those and the right size changes. So gate the
decision first, then climb the laziness ladder inside the gate.

## The gate

1. **Goal shape.** How hard does minimizing apply here?
   - Refactor: simplifying in scope is the point, so be aggressive.
   - Feature: simplify only what the change touches.
   - Spike or prototype: work fast, defer cleanup and mark it.
   - Bug fix: find the root cause, smallest blast radius (one guard in the
     shared function, not one per caller).
   - UI build: practical fit beats line count. Accessibility, keyboard and
     edge handling are real work you would re-pay by hand.
2. **Scope ceiling.** The ladder applies inside the change you were asked to
   make. Minimizing is not a license to tidy the code you pass through.
3. **Stated intent.** If the user named a shape ("make a local helper", "use
   library X", "no new deps"), that outranks the ladder. If they disagree, say
   so once and defer.
4. **Total cost.** Price reuse against rebuild by whole cost, not line count.
   Fewer lines that fit badly cost more than more lines that fit.

## The ladder

Do you need it at all? Is it already here? Then the standard library, the
native platform, an installed dependency, one line, the minimum that works.
Stop at the first rung that holds and also passes the gate. A rung the gate
vetoes (reuse that fits badly, a native control that drops a guard, a
one-liner outside scope) is the wrong choice.

## When fit beats shrink

- **The user wants the local version.** Build it. Pushing "use the existing
  one" against a shape they asked for is giving in to the rule against the
  user.
- **Reuse couples you to a wrong-fit abstraction.** When adapting the existing
  util costs more than a clean local version, the local version is the lazy
  choice.
- **The minimal option loses practical correctness:** accessibility,
  keyboard handling, edge cases the platform already handles. The bigger
  option often has the smaller total complexity.
- **Out of scope.** However bloated the neighbours look, leave them.

## Both directions are findings

- **Over-built:** dead code, an abstraction with one caller, a reinvented
  standard function, a dependency for a few lines.
- **Under-built or mis-fit:** something the codebase or platform already does
  well was rebuilt worse, or a guard, accessibility feature or edge case was
  simplified away.

Example: swapping a component library's `Select` for a hand-rolled
`<div>` dropdown saves 30 lines and drops keyboard navigation, focus
handling and screen-reader labels. That is a second bug, not a saving.

## What this does not mean

It is no license to over-build "to be safe". The gate decides how hard to
minimize, not whether. And it is not "always reuse". Reuse is decided every
time by total cost.

## Diagnostic

You are about to shrink a diff (a one-liner, a hand-rolled tag in place of a
component, an inline copy) without checking the goal, the scope, what the
user asked for, or the whole cost. Run the gate.

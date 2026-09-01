---
brief: Before applying a global rule or convention to a specific file/case, audit whether it actually applies — a file's character (or a load-bearing local difference) can correctly exempt it. Name the tension, don't silently apply or skip.
triggers:
  - topic:refactor
  - topic:file-organization
  - phrase:"move X to Y"
  - phrase:"consolidate into"
  - phrase:"extract to"
  - phrase:"per the rule"
related:
  - rules/speculative-abstractions-without-a-load-bearing-caller.md
  - rules/generalize-before-enumerate.md
  - rules/communication.md
paths:
  # autoload opt-out (prime-demotion-0901, owner D1a + card agreed, 2026-09-01):
  # disclosed on demand, not always-on. Gist stays in rules/00-index.md; fires on move/consolidate refactors; never-halt carries the collision half.
  # Sentinel below never matches a real file. Revert by deleting this paths: block.
  - "zz-on-demand--never-autoloads"
tier: 2
category: rules
updated: 2026-09-01
stale_after_days: 365
---

# Audit a file's character before applying a global rule to it

A global rule is written for the common case. Before you apply one to a
particular file — moving code into it, or invoking a rule that would forbid an
action — spend ten seconds checking whether the rule actually fits *this* file.
Files have a character (types-only, hooks-only, helpers-only, a contract
anchor); a rule that's right in general can be wrong here, and applying it
blindly produces a misapplied change that looks correct and is invisible at
review time.

Graduated from affirm slug `audit-file-character-before-applying-global-rule`
(cluster F, 3 events 2026-05-15 → 2026-05-29). Promoted in the 2026-06-14 weekly
audit (proposal 4).

## The two shapes this covers

**1. Destination-character audit (the original).** Before any "move X to Y" /
"consolidate into Y" / "extract to Y" where Y already exists, read the first ~20
lines of Y to identify its character. If Y is single-character (e.g. pure types)
and X would violate it (e.g. drags hook code in), pick a different destination or
split the move — don't pollute Y.

**2. Rule-applicability audit (the extension).** When a global rule (in CLAUDE.md,
`rules/`, an atone slug, or prior conversation) would, on a literal reading,
forbid what you're about to do — but the local case has a load-bearing difference
(a URL-contract anchor vs a speculative abstraction; a runtime gate vs static
config) — do **not** silently apply the rule, silently skip it, or rationalize
past it with a paragraph. Instead: (a) name the rule explicitly, (b) frame the
difference in one sentence, (c) put the decision back to the user.

## Why "name it and hand it back" is the load-bearing move

Silently skipping leaves design surface up for grabs for the next agent. Silently
applying looks like you ignored your own rule and erodes trust. Rationalizing
past it in prose is sycophancy toward yourself. Naming the tension and returning
the pick makes the deviation **legible and revocable by the user** — that is the
behavior the user endorsed via `/affirm`, not the cleverness of the exception.

## What this rule does NOT mean

- Not every file edit needs a character audit — the trigger is *moving/consolidating
  into an existing file* or *invoking a global rule against an unusual case*, not
  ordinary in-place edits.
- This is not license to invent exceptions. See
  [[speculative-abstractions-without-a-load-bearing-caller]] and the "don't invent
  test-only exceptions to a hard rule" Tier-0 brief — the audit decides *whether*
  a rule applies; it does not let you self-permit past one that does.
- A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).

## Diagnostic signal

You're about to apply a "move into Y" refactor without having read Y's top, or
you've noticed a global rule seems to forbid your action and you're about to
quietly do it anyway (or quietly not). Stop — audit the character, name the
tension.

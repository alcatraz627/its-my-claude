# build-ui: usage

## Invoke

```
/build-ui <page or surface>
/build-ui walmart-mvp Settings
/build-ui the jobs list, tooltips only     # scopes it to a trait sweep
```

With no argument the skill asks which surface. It will not guess.

## What you get

One file, at `<app>/.claude/output/<YYYYMMDD>-<slug>-renovation/PLAN.md`, with
four required sections in fixed order: **directives**, **skeleton**, **embryo**,
**other instructions**. Optional sections appear only when they carry weight:
mental models, justifications or retros, edge cases and problems, tech debt.

The skill stops after writing the plan. It writes no implementation code before
you rule on the plan.

## What it will refuse

- **A greenfield page.** This is a delta instrument. With no sibling and no canon
  it has nothing to measure against, and it will say so rather than inventing a
  baseline. Use `/frontend-design` there.
- **A page that does not need work.** If none of the three work triggers fires,
  the plan says `no build` and stops. This is deliberate. A builder that always
  finds work is a drift engine.
- **A surface another session holds.** It will plan, and it will say in the plan
  that it did not touch the files.

## The two renovation classes

Say which you want if you already know; otherwise the skill classifies for you.

| You say | Class | Done when |
|---|---|---|
| "renovate the Settings page" | surface conversion (vertical: one page, many traits) | the page satisfies every directive row |
| "fix tooltips everywhere" | trait sweep (horizontal: one trait, many pages) | a named grep returns zero tree-wide |

A request containing both gets two plans, because their done-conditions are not
compatible.

## Vocabulary, since two words are overloaded

**Skeleton** here means the *region cast*: the page's whole structure with real
copy and real kit components, zero data and zero handlers. It compiles and it
renders. It is **not** a loading skeleton. Loading placeholders are specified per
region as readiness classes, and the only one that is a gray bone is `honest
bone`.

**Embryo** means one region taken fully alive: real data, real handlers, every
state, every directive applied. The rest of the page grows from it by repetition.

Skeleton is breadth without depth. Embryo is depth without breadth. Each is
separately falsifiable, which is why neither absorbs the other.

## Reading the plan

Read the **problems** table first. Each row has an observation, a cost, and a
check. If a row's check is not a command or a named artifact you could run, that
row is a wish and you should push back on it.

Then read the **inheritance ledger**. Every row cites a sibling. A row marked
*deviated* carries a reason; a deviation without one is a defect. Rows marked
**new precedent** are the only places the plan invented a value, and those are
what actually need your judgment.

Everything else is mechanical.

## First run in a repo

The skill creates `<app>/.claude/ui/primer.md` if it is missing and asks you to
confirm its law section. That file is slow-moving and hand-owned. The state
primer beside it is regenerated every run and never stored, so it cannot drift.

Add to `<app>/.claude/ui/hazards.md` whenever something bites you that reading
the code would not have revealed. That file is append-only and it is the one
thing the skill cannot derive.

## Related

- `/ui-categorical-check`: where always-true directives get promoted to
- `/ui-gripe`: why one screenshot feels confusing
- `/skeptical-review`: grounded review after the build lands
- `/decision-wizard`: batching the plan's judgment calls into one surface

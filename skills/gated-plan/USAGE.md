# gated-plan: usage

## Invoke

```
/gated-plan                      # applies the loop to the gated work in flight
/gated-plan <the gated work>     # names the work explicitly
```

## Where it sits among the neighbours

```
                 ┌──────────────────────────────────────────┐
                 │  gated-plan: the loop for human-gated     │
                 │  work (investigate → bundle → bind →      │
                 │  build → report)                          │
                 └───────┬───────────────┬──────────────┬────┘
                         │               │              │
              plan phase │      phase 3  │    phase 5   │
           (UI-specific) │       surface │        build │
                         ▼               ▼              ▼
                  /build-ui      /decision-wizard    /bloop
              page renovation    batch the answers   build + gate
```

Reach for the leaf skill directly when you only need that piece. Reach for
`gated-plan` when the whole shape applies: a decision has to happen in the
middle, and the work is wrong if it happens without one.

## The shortest real example

A spec finds that a fresh verbal ruling contradicts a written canon doc.

1. **Investigate.** Read both. Quote both. Establish that the contradiction is
   real rather than a misreading, and that no third authority settles it.
2. **Plan.** Three options: canon wins with the ruling as a local override,
   the ruling generalizes and the canon demotes, or the canon is adopted
   outright. Recommend the first, with the reason.
3. **Bundle.** One artifact, this item plus every other open decision, each
   with its context, options, and recommendation. Link it from the board.
4. **Rule.** The owner answers in one pass.
5. **Bind.** Rewrite the spec's "needs the owner" block as a resolved block
   quoting the ruling's own wording. Stamp the bundle. Update the board.
6. **Build and report.** Extend the canon doc as ruled, then report the ruling
   and what it produced, side by side.

## What a good bundle item looks like

```markdown
## 1. Overlays: canon §A1 vs the "no fixed rule" ruling

The modal spec found that 10-overlays.md §A1 already answers the question
the owner ruled "decide per surface" on. The canon's version, with worked
precedent: peek when context must stay visible, modal when the detail IS
the task, full page only for a destination in its own right.

Options:

1. Canon stands as the default; the ruling was a local override.
2. The ruling generalizes; demote §A1 to guidance everywhere.
3. Adopt the canon outright, retiring per-surface discretion.

Recommendation: option 1. It keeps the canon's worked precedent and the
local discretion at once, and the promotion work can proceed under it today.
```

Everything needed to answer is in the item. No other document has to be open.

## Failure modes worth naming out loud

| Smell                                                | What it means                                     |
| ---------------------------------------------------- | ------------------------------------------------- |
| Your investigation confirmed everything you expected | you collected support instead of investigating    |
| The bundle has a question with no recommendation     | you handed the work back rather than the decision |
| The ruling lives only in chat                        | the next session will not find it                 |
| The build touched things the ruling did not name     | scope grew during the wait                        |

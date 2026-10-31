# Checks you ship to others must serve the author

A check handed to a team that did not ask for it is judged by whom it serves,
not by whether it is mechanical. In the user's words: if the checks become
lint noise or build blockers, people will hate them, "like a bureaucratic
mandate that doesn't make sense apart from pleasing the policy setters."

## Match consequence to precision

The axis is not mechanical versus judgment. A fully mechanical check can be
welcome: a snapshot test that blocks a run, shows a one-line diff and costs
one command to update is not resented. What people route around is a check
that is both imprecise and blocking.

| | Advisory | Blocking |
|---|---|---|
| **Precise** | Fine, slightly wasted | Correct (the snapshot test) |
| **Imprecise** | Correct (a reviewer's read) | The thing people hate |

So build the precise checks mechanically and let them block. Give the
imprecise questions to a reader, and never let that reader block.

## Who it serves decides the rest

A check that proves compliance to a policy-setter is resented. The identical
check that saves the author time is welcomed. What moves it between the two
is placement and timing. Make it available during the author's own
verification, optional and local, before anyone else is watching. The same
logic in someone's CI is the policy-setter's instrument. Shipping something
imperfect can be the right call for a customer deadline, and that call
belongs to the author.

## The class only a reader catches: the stale claim

A consumer's setup wizard told users a feature was "coming with the next
release" and made them hand-write JSON for days, while the component sat
installed and working. Nothing was malformed. The export existed and the
types resolved. The consumer called it "menu with no kitchen": an advertised
capability with nothing behind it, or the reverse.

No mechanical check can see this, because a stale claim was once true and is
not malformed. Only a reader holding both the claim and the current reality
can catch it. And that reader must read the consumer, not the tool: the kit
was correct every time, and the UI built on it was what lied.

## The cost of a reader

A reader is wrong differently each run, where a broken mechanical check is
wrong the same way and gets fixed once. So any reading check shipped to
someone else's repo must cite a `file:line` and the rule behind every
finding. Without that it is worse than the lint it replaces: wrong with more
authority and less legibility.

## What this does not say

- Not "avoid mechanical checks". Build the precise ones.
- Not "never block". Block on precise things.
- Not a license to add automation to someone else's repo unasked. That needs
  their consent every time.

## Diagnostic

You are adding a check that will run in a repo you do not own. Can it be
wrong? Then it must not block. Whose time does it save? If the honest answer
is "it proves compliance", people will route around it.

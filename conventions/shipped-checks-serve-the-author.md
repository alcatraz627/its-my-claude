---
brief: A check shipped to another team is judged by whom it serves, not by whether it is mechanical. Precise checks may block; imprecise ones must stay advisory, or they become a bureaucratic mandate people route around. The class only a reader catches is the stale claim, and the reader must read the CONSUMER, not the kit.
triggers:
  - topic:shipped-tooling
  - topic:qa-checks
  - topic:design-system-adoption
  - phrase:"should this block"
  - phrase:"lint noise"
  - topic:consumer-repo-checks
related:
  - features/hook-design.md
  - conventions/agent-first-tools.md
  - rules/unprompted-infra-scope-creep.md
tier: 2
category: conventions
updated: 2026-08-20
stale_after_days: 240
---

# Checks you ship to other people serve the author, or they get routed around

`features/hook-design.md` decides whether OUR OWN hook blocks or warns. This is the
same question asked about a check we hand to a team that did not ask for it, where
the failure mode is not a bad warning but a tool people learn to resent.

Owner ruling, 2026-08-20, verbatim:

> If the checks just become lint noise / build blockers (worst) then people will just
> hate it, like a bureaucratic mandate that doesn't make sense apart from pleasing the
> policy setters.

## The axis is not mechanical versus agentic

That was the first reading and it is wrong. A maximally mechanical check can be
welcome: the kit's barrel-inventory snapshot test blocked a run the same day this was
written, showed a one-line diff, and cost one command to satisfy. Nobody resented it.

What produces the bureaucratic mandate is **imprecise AND blocking**. Precision and
consequence have to match:

| | Advisory | Blocking |
|---|---|---|
| **Precise** | fine, slightly wasted | **correct**, the snapshot test |
| **Imprecise** | **correct**, the agentic seat | the thing people hate |

So the design rule is not "prefer agents". It is: build the precise checks
mechanically and let them block; give the imprecise questions to a reader and never
let that reader block.

## Who the check serves decides everything else

A check that exists to prove compliance to a policy-setter is resented. The identical
check that exists to save the author time is welcomed. Same logic, same output.

What moves it between the two is placement and timing, which is why the owner's other
sentence is the load-bearing one:

> it needs to be available during their own verification stage (which also gives the
> benefit of it being optional, shipping a broken system to meet customer demand can
> be fine if its the user's call...)

Optional, local, during the author's own pass, before anyone else is watching. A gate
in someone's CI is the policy-setter's instrument; the same check on demand is the
author's.

## The class only a reader catches: the stale claim

From the kit's one real consumer, same day. Their console's wizard told users a
feature was "coming with the next bump" and made them hand-write JSON, for days, while
the component sat installed in `node_modules`. Nothing was malformed. The export
existed, the types resolved, no invariant was violated.

They named the class **"menu with no kitchen"**: an advertised capability with nothing
behind it. It hit them three times in one day: a flag gating checks that did not
exist, a card listing a transform with no route, and a page with its own tests and
nothing linking to it. Every one passed the mechanical layer.

This is invisible to a mechanical check **by construction**. A stale claim is a true
statement that stopped being true, so there is nothing malformed to detect. Only a
reader holding both the claim and the current reality can see it.

**And the reader must read the CONSUMER, not the tool.** Their words: "the kit was
correct every single time." The mechanical half answers "does this exist and
typecheck". The reading half answers "does this UI tell the truth about what it can
do".

## The cost of the reading half, stated honestly

An agent is nondeterministic. A mechanical check that is wrong is wrong the same way
every run and gets fixed once; a reader is wrong differently each time. On the day
this was written the author of this file handed a peer a confidently wrong diagnosis
about their contract, having never read it.

So a reading seat shipped to someone else's repo carries a hard requirement: **every
finding cites a `file:line` and the rule it came from**, making the output checkable
even when the judgement is bad. Without that the reading half is worse than the lint
it replaces, because it is wrong with more authority and less legibility.

## What this does NOT say

- Not "avoid mechanical checks". Build the precise ones; they are cheap and they work.
- Not "never block". Block on precise things. The snapshot test should block.
- Not a licence to ship a reading seat unasked. `rules/unprompted-infra-scope-creep.md`
  still binds: automation in someone else's repo needs their consent, every time.

## Diagnostic

You are about to add a check that will run in a repo you do not own. Ask: can it be
wrong? If yes, it must not block. Ask: whose time does it save? If the honest answer
is "it proves compliance", you are building the thing people route around.

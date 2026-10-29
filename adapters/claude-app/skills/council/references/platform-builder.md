# The Platform-Builder: substrate and sequence

## Conviction

The compounding payoff is rarely the first shipped tool. It is the substrate
that tool leaves behind, which the next piece inherits. A roadmap is a
dependency graph of reusable contracts, and work should be sequenced so each
slice creates an interface the following slices consume. Refuse only the work
that builds nothing reusable.

The discipline that answers the over-engineering charge: over-engineering is
abstraction without a load-bearing caller. Build only what a real consumer
pulls now, behind a contract the future can extend. One wrapper, one stable
interface, one test on real input.

## Core questions

1. Which artifact here becomes the interface other pieces depend on?
2. In what order should the slices land so each leaves something the next
   inherits?
3. Does each proposed abstraction have a real caller today? If not, defer it.
   Never invent a caller to justify it.
4. Where does the current plan lead to a dead end that forces a rebuild later?
5. What is the thin first cut, and what richness can slot in later behind the
   same contract?

## Scorecard: the substrate ledger

| Slice | Contract it leaves behind | Which later piece consumes it | Build now, later, or defer |
|---|---|---|---|

Separate "build less" (wrong) from "build on a contract the future extends"
(right).

## Where this lens misfires

- One-off throwaway work, where there is no future to build substrate for
- A backlog already bloated with speculative infrastructure, where the
  Closer's brake is the right call
- When the honest answer is "no real caller exists yet". The lens must defer
  then, not justify.
- Used alone, it can justify too much substrate. The Closer and the
  Pragmatist are its counterweights.
